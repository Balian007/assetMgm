FROM maven:3.9.9-eclipse-temurin-17 AS build
WORKDIR /app

COPY pom.xml ./
RUN mvn -B -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -B -DskipTests clean package

FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

ENV TZ=Asia/Shanghai

RUN useradd -r -u 1001 appuser \
    && mkdir -p /data/asset-mgm/uploads \
    && chown -R appuser:appuser /app /data/asset-mgm

COPY --from=build /app/target/asset-mgm-backend-*.jar /app/app.jar

USER appuser
EXPOSE 8080

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar /app/app.jar"]