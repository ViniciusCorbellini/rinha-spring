#!/usr/bin/env bash
# _linux_run-test-stats-logger.sh — Linux docker stats logger
set -Eeuo pipefail

LOGFILE="${1:?Usage: $0 <logfile> <main_pid> [stop_flag]}"
MAIN_PID="${2:?Usage: $0 <logfile> <main_pid> [stop_flag]}"
STOP_FLAG="${3:-}"

export LANG=C.UTF-8
export LC_ALL=C.UTF-8

ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }

touch "${LOGFILE}"

echo "$(ts) Logger iniciado. Monitorando PID=${MAIN_PID}" >> "${LOGFILE}"

while true; do
  # stop conditions
  if [[ -n "${STOP_FLAG}" && -f "${STOP_FLAG}" ]]; then
    echo "$(ts) Sinal de parada detectado. Encerrando logger." >> "${LOGFILE}"
    break
  fi
  if ! kill -0 "${MAIN_PID}" 2>/dev/null; then
    echo "$(ts) Processo principal finalizado. Encerrando logger." >> "${LOGFILE}"
    break
  fi

  if docker stats --no-stream >/dev/null 2>&1; then
    docker stats --no-stream | while IFS= read -r line; do
      printf '%s %s
' "$(ts)" "$line" >> "${LOGFILE}"
    done
    printf '\n' >> "${LOGFILE}"
  else
    printf '%s [docker stats erro]\n' "$(ts)" >> "${LOGFILE}"
  fi
  sleep 2
done
