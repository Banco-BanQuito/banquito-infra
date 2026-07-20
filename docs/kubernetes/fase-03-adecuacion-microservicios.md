# FASE 3 - Adecuacion de microservicios para Kubernetes

## Objetivo

Asegurar que cada microservicio pueda ejecutarse dentro de un Pod sin depender de `localhost`, IPs fijas locales ni archivos manuales.

## Criterios aplicados

| Aspecto | Criterio |
| --- | --- |
| Puertos | Deben exponerse segun `server.port` y puertos gRPC reales |
| Configuracion | Usar variables de entorno |
| Secretos | No guardar passwords reales en Git |
| Bases | Usar endpoints Cloud SQL / MongoDB Atlas |
| RabbitMQ | Usar endpoint externo o administrado |
| Dockerfile | Imagen ligera y compatible con GKE |

## Variables esperadas

Ejemplos:

```properties
server.port=${SERVER_PORT:8081}
spring.datasource.url=${DB_URL}
spring.datasource.username=${DB_USER}
spring.datasource.password=${DB_PASS}
spring.rabbitmq.host=${RABBITMQ_HOST}
```

## Configuracion por dominio

Core:

```text
account-core-service -> PostgreSQL
accounting-service -> PostgreSQL
party-service -> MySQL
```

Switch:

```text
file-reception-service -> MySQL, MongoDB, RabbitMQ
tariff-service -> MySQL
clearinghouse-service -> MongoDB, RabbitMQ
report-service -> MongoDB
notification-service -> MongoDB, SMTP
```

## Dockerfiles

Patron backend:

```dockerfile
FROM eclipse-temurin:21-jre
COPY target/*.jar app.jar
ENTRYPOINT ["java","-jar","/app.jar"]
```

Patron frontend:

```dockerfile
FROM node:18-alpine AS builder
RUN npm install
RUN npm run build

FROM nginxinc/nginx-unprivileged:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 8080
```

## Validacion

```powershell
rg -n "localhost|127.0.0.1|replace-with|password|jdbc:" banquito-* -S
rg -n "server.port|grpc.*port|spring.datasource|rabbit|mongodb" banquito-* -S
```

## Entregable

Cada microservicio puede construirse como imagen Docker y recibir configuracion por variables de entorno.
