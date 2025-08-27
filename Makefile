# Makefile para build e deploy da aplicação Spring + Docker

# Variáveis
JAR_FILE=target/*.jar

# Comando para compilar o projeto e gerar o .jar (sem testes)
build:
	./mvnw clean package -DskipTests

# Comando para buildar a imagem Docker e subir com docker-compose
up:
	docker-compose up --build

# Derruba os containers e remove volumes
down:
	docker-compose down -v

# Limpa o target e o volume do banco
clean:
	./mvnw clean
	docker volume rm $$(docker volume ls -qf dangling=true)

# Apenas recompila o jar, sem subir nada
jar:
	./mvnw clean package -DskipTests

# Roda os comandos necessários após uma atualização no código
# OBS: se houve uma mudanca no dockerfile ou compose deve-se usar "make down" e depois "make run"
run:
	mvnw clean package -DskipTests
	docker-compose up --build

#Sobe os serviços em modo daemon, sem usar terminal
up_background:
	docker-compose up -d --build

# Roda os comandos necessários para rodar os testes do zero,
# truncando a tabela e esperando o gatling em uma imagem leve de linux
test:
	docker-compose run --rm gatling