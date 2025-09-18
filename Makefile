# Makefile para build e deploy da aplicação Spring + Docker em WSL

# Variáveis
JAR_FILE=target/*.jar

# Comando para compilar o projeto e gerar o .jar (sem testes)
build:
	mvn clean package -DskipTests

#Sobe os serviços em modo daemon, sem usar terminal
up:
	docker compose --compatibility up -d --build

# Derruba os containers e remove volumes
down:
	docker-compose down -v

# Limpa o target e o volume do banco
clean:
	mvn clean
	docker volume rm $$(docker volume ls -qf dangling=true)

# Roda os comandos necessários após uma atualização no código
# OBS: se houve uma mudanca no dockerfile ou compose deve-se usar "make down" e depois "make run"
run:
	mvn clean package -DskipTests
	docker compose --compatibility up -d --build

# Resetar o banco e rodar a simulação (Gatling)
test:
	docker exec postgres psql -U postgres -d postgres_api_db -v ON_ERROR_STOP=1 \
	-c "BEGIN; TRUNCATE TABLE transactions; UPDATE accounts SET balance = 0; COMMIT;" \
	&& mvn gatling:test -Dgatling.simulationClass=simulations.RinhaBackendCrebitosSimulation

#Roda o script que inicia o teste em sh para linux
wsl_test:
	\_linux_run-test-launcher.sh