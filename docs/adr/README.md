# Architectural Decision Records - Banco BanQuito V2

Este directorio documenta las decisiones de arquitectura tomadas durante la evolucion del Core Bancario y el Switch de Pagos Masivos a un ecosistema de microservicios.

| ADR | Titulo |
| --- | --- |
| [001](001-microservicios-y-dominios.md) | Division en microservicios y separacion de dominios Core / Switch |
| [002](002-persistencia-poliglota.md) | Persistencia poliglota: PostgreSQL, MySQL y MongoDB |
| [003](003-comunicacion-sincrona-grpc-rest.md) | gRPC intra-dominio, REST al cruzar dominios |
| [004](004-comunicacion-asincrona-rabbitmq.md) | Mensajeria asincrona historica con RabbitMQ |
| [005](005-api-gateway-kong.md) | API Gateway con Kong |
| [006](006-particionamiento-postgresql.md) | Particionamiento declarativo de transacciones en PostgreSQL |
| [007](007-despliegue-docker-compose.md) | Orquestacion historica con Docker Compose |
| [008](008-bases-datos-nube.md) | Bases de datos como servicio en la nube |
| [009](009-consistencia-compensacion.md) | Consistencia entre microservicios via transaccion compensatoria |
| [010](010-idempotencia-transacciones.md) | Idempotencia de operaciones financieras via UUID de transaccion |
| [011](011-eliminacion-routing-service.md) | Decision historica de eliminacion de routing-service |
| [012](012-separacion-switch-pubsub-cloud.md) | Separacion del flujo Pub/Sub del Switch de Pagos |

## Nota

Los ADR 004, 007 y 011 se conservan como historicos porque explican decisiones tomadas antes de migrar completamente a GKE, Pub/Sub y servicios administrados de Google Cloud.

Para la arquitectura cloud actual, el ADR que gobierna el flujo asincrono del Switch es:

```text
ADR-012: Separacion del flujo Pub/Sub del Switch de Pagos
```

