FROM openjdk:18-jdk-slim

WORKDIR /app

COPY ./target/*.jar app.jar

EXPOSE 8080

ENTRYPOINT ["java", "-jar", "app.jar", "--spring.profiles.active=docker"]