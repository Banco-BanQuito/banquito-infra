# FASE 0 - Levantamiento y analisis

## Objetivo

Entender como esta construido el proyecto antes de modificar codigo o infraestructura.

## Repositorios revisados

### Core Bancario

| Microservicio | Tecnologia | HTTP | gRPC | Persistencia |
| --- | --- | ---: | ---: | --- |
| `banquito-account-core-service` | Spring Boot / Maven | 8081 | 9091 | PostgreSQL, schema `account_core` |
| `banquito-accounting-service` | Spring Boot / Maven | 8082 | 9092 | PostgreSQL, schema `accounting` |
| `banquito-party-service` | Spring Boot / Maven | 8083 | 9093 | MySQL, database `partydb` |

### Switch de Pagos Masivos

| Microservicio | Tecnologia | HTTP | gRPC | Persistencia / mensajeria |
| --- | --- | ---: | ---: | --- |
| `banquito-file-reception-service` | Spring Boot / Maven | 8084 | cliente | MySQL `filedb`, MongoDB, Pub/Sub |
| `banquito-tariff-service` | Spring Boot / Maven anidado | 8086 | 9090 | MySQL `tariffdb` |
| `banquito-clearinghouse-service` | Spring Boot / Maven anidado | 8087 | n/a | MongoDB, Pub/Sub |
| `banquito-report-service` | Spring Boot / Maven | 8088 | n/a | MongoDB |
| `banquito-notification-service` | Spring Boot / Maven | 8089 | 9092 | MongoDB, SMTP |

### Frontends

| Frontend | Tecnologia | Puerto contenedor | Uso |
| --- | --- | ---: | --- |
| `banquito-teller-frontend` | Vite / Nginx | 8080 | Ventanilla |
| `banquito-web-personas-frontend` | Vite / Nginx | 8080 | Banca Personas |
| `banquito-web-empresas-frontend` | Vite / Nginx | 8080 | Banca Empresas |
| `banquito-frontend-web-operador` | Vite / Nginx | 8080 | Operador |

## Dependencias principales

Core:

```text
account-core-service -> accounting-service por gRPC 9092
account-core-service -> party-service por gRPC 9093
party-service -> account-core-service por gRPC 9091
```

Switch:

```text
file-reception-service -> tariff-service por gRPC 9090
file-reception-service -> notification-service por gRPC 9092
clearinghouse-service -> Pub/Sub
report-service -> MongoDB
notification-service -> MongoDB y SMTP
```

## Decision de comunicacion

| Tipo de comunicacion | Decision |
| --- | --- |
| Frontend hacia backend | Debe pasar por Apigee |
| Trafico externo | Debe pasar por Apigee |
| Trafico interno tecnico entre microservicios | Puede usar Kubernetes Service interno |
| gRPC interno | Se mantiene dentro del cluster |
| Bases, Pub/Sub, OAuth, SMTP | Servicios administrados o externos |

## Entregable

Documento tecnico de arquitectura base:

```text
banquito-infra/docs/entendimiento-gke-ci-cd.md
```
