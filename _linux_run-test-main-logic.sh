#!/usr/bin/env bash
# _linux_run-test-main-logic.sh — Linux main logic with robust UTF-8 and health checks
set -Eeuo pipefail

LOGFILE="${1:-__test_logs-$(date +%Y%m%d-%H%M%S).txt}"

# Locale/encoding (UTF-8 end-to-end)
export LANG=C.UTF-8
export LC_ALL=C.UTF-8
export JAVA_TOOL_OPTIONS="-Dfile.encoding=UTF-8 -Dsun.stdout.encoding=UTF-8 -Dsun.stderr.encoding=UTF-8 ${JAVA_TOOL_OPTIONS:-}"
export MAVEN_OPTS="-Dfile.encoding=UTF-8 ${MAVEN_OPTS:-}"

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "${SCRIPT_DIR}"

ts() { date '+%Y-%m-%d %H:%M:%S.%3N'; }

wlog() {
  printf '%s %s
' "$(ts)" "$*" | tee -a "${LOGFILE}"
}

# Runs a command, streaming output to console and file (UTF-8) — ignores failures if asked
run_cmd() {
  local title="$1"; shift
  local ignore="${1}"; shift  # "ignore" or "strict"
  wlog "[CMD] ${title}"
  # stdbuf for line-buffered tee; prevents blocking
  if ! stdbuf -oL -eL "$@" 2>&1 | tee -a "${LOGFILE}"; then
    if [[ "${ignore}" != "ignore" ]]; then
      return 1
    fi
  fi
}

# =============== Steps ===============

wlog "[PASSO 1/5] Parando e removendo containers antigos (ignorar falhas)..."
run_cmd "docker compose down -v" "ignore" docker compose down -v || true

wlog ""
wlog "[PASSO 2/5] Construindo e subindo novos containers (ignorar falhas)..."
run_cmd "docker compose up -d --build --compatibility" "ignore" docker compose --compatibility up -d --build || true

wlog ""
wlog "[PASSO 3/5] Verificacao de Saude dos Containers..."
SERVICES=("postgres" "app1" "app2" "nginx")
TIMEOUT=90
DEADLINE=$(( $(date +%s) + TIMEOUT ))

get_ids_for_service() {
  docker compose ps -q "$1" 2>/dev/null | sed '/^$/d' || true
}

is_container_running() {
  local id="$1"
  [[ "$(docker inspect -f '{{.State.Status}}' "${id}" 2>/dev/null || echo 'unknown')" == "running" ]]
}

has_healthcheck() {
  local id="$1"
  [[ -n "$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{end}}' "${id}" 2>/dev/null)" ]]
}

is_container_healthy() {
  local id="$1"
  [[ "$(docker inspect -f '{{.State.Health.Status}}' "${id}" 2>/dev/null || echo 'none')" == "healthy" ]]
}

all_services_ready() {
  local ready=0 total=0
  for svc in "${SERVICES[@]}"; do
    total=$((total+1))
    local ids; mapfile -t ids < <(get_ids_for_service "${svc}")
    if [[ "${#ids[@]}" -eq 0 ]]; then
      return 1
    fi
    local ok_running=1 ok_health=1
    for id in "${ids[@]}"; do is_container_running "${id}" || { ok_running=0; break; }; done
    if [[ $ok_running -eq 1 ]]; then
      local any_health=0
      for id in "${ids[@]}"; do has_healthcheck "${id}" && { any_health=1; break; }; done
      if [[ $any_health -eq 1 ]]; then
        for id in "${ids[@]}"; do is_container_healthy "${id}" || { ok_health=0; break; }; done
      fi
    else
      ok_health=0
    fi
    if [[ $ok_running -eq 1 && $ok_health -eq 1 ]]; then
      ready=$((ready+1))
    fi
  done
  [[ "${ready}" -eq "${total}" ]]
}

healthy_count() {
  local cnt=0
  for svc in "${SERVICES[@]}"; do
    local ids; mapfile -t ids < <(get_ids_for_service "${svc}")
    [[ "${#ids[@]}" -gt 0 ]] || continue
    local ok_running=1 ok_health=1
    for id in "${ids[@]}"; do is_container_running "${id}" || { ok_running=0; break; }; done
    if [[ $ok_running -eq 1 ]]; then
      local any_health=0
      for id in "${ids[@]}"; do has_healthcheck "${id}" && { any_health=1; break; }; done
      if [[ $any_health -eq 1 ]]; then
        for id in "${ids[@]}"; do is_container_healthy "${id}" || { ok_health=0; break; }; done
      fi
    else
      ok_health=0
    fi
    if [[ $ok_running -eq 1 && $ok_health -eq 1 ]]; then
      cnt=$((cnt+1))
    fi
  done
  echo "${cnt}"
}

while (( $(date +%s) < DEADLINE )); do
  hc=$(healthy_count)
  wlog "Aguardando... (${hc} de ${#SERVICES[@]} servicos prontos)"
  if all_services_ready; then
    wlog "Todos os servicos essenciais estao prontos! A continuar."
    break
  fi
  sleep 5
done

if ! all_services_ready; then
  wlog ""
  wlog "--- ESTADO ATUAL DOS CONTAINERS ---"
  docker compose ps | tee -a "${LOGFILE}" >/dev/null || true
  wlog "Timeout: Nem todos os containers ficaram prontos em ${TIMEOUT} segundos."
  exit 1
fi

# Postgres readiness + cleanup
wlog ""
wlog "[PASSO 4/5] Limpando o banco de dados..."
PG_ID="$(docker compose ps -q postgres | head -n1 || true)"
if [[ -z "${PG_ID}" ]]; then
  wlog "Aviso: container do postgres nao encontrado; pulando limpeza."
else
  # Wait DB ready
  DB_TIMEOUT=90
  DB_DEADLINE=$(( $(date +%s) + DB_TIMEOUT ))
  while (( $(date +%s) < DB_DEADLINE )); do
    if docker exec "${PG_ID}" sh -lc 'command -v pg_isready >/dev/null 2>&1' ; then
      if docker exec "${PG_ID}" pg_isready -U postgres -d postgres_api_db -q ; then
        break
      fi
    else
      if docker exec "${PG_ID}" psql -U postgres -d postgres_api_db -c "SELECT 1;" >/dev/null 2>&1 ; then
        break
      fi
    fi
    wlog "Aguardando DB aceitar conexoes..."
    sleep 3
  done
  # Cleanup
  docker exec "${PG_ID}" psql -U postgres -d postgres_api_db -v ON_ERROR_STOP=1     -c "TRUNCATE TABLE transactions"     -c "UPDATE accounts SET balance = 0"     2>&1 | tee -a "${LOGFILE}"
fi

# Sleeps for a minute to make sure spring is accepting connections
wlog "Dormindo"
sleep 60
wlog "Acordando"

# Gatling
wlog ""
wlog "[PASSO 5/5] Executando o teste de carga com Gatling..."
pushd "${SCRIPT_DIR}/gatling" >/dev/null
stdbuf -oL -eL mvn -B -Dfile.encoding=UTF-8 \
  gatling:test -Dgatling.simulationClass=simulations.RinhaBackendCrebitosSimulation \
  2>&1 | tee -a "${LOGFILE}"
G_EXIT=${PIPESTATUS[0]}
popd >/dev/null
if [[ ${G_EXIT} -ne 0 ]]; then
  wlog "Falha ao executar o teste do Gatling. Exit=${G_EXIT}"
  exit ${G_EXIT}
fi

wlog "Teste concluido com sucesso."
