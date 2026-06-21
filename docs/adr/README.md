# Architectural Decision Records — Banco BanQuito V2

Este directorio documenta las decisiones de arquitectura tomadas durante la evolución del Core Bancario y el Switch de Pagos Masivos a un ecosistema de microservicios.

| ADR | Título |
|---|---|
| [001](001-microservicios-y-dominios.md) | División en microservicios y separación de dominios (Core / Switch) |
| [002](002-persistencia-poliglota.md) | Persistencia políglota: PostgreSQL, MySQL y MongoDB |
| [003](003-comunicacion-sincrona-grpc-rest.md) | gRPC intra-dominio, REST al cruzar dominios |
| [004](004-comunicacion-asincrona-rabbitmq.md) | Mensajería asíncrona con RabbitMQ (modelo Pub-Sub) |
| [005](005-api-gateway-kong.md) | API Gateway con Kong |
| [006](006-particionamiento-postgresql.md) | Particionamiento declarativo de transacciones en PostgreSQL |
| [007](007-despliegue-docker-compose.md) | Orquestación con Docker Compose y actualización continua con Watchtower |
| [008](008-bases-datos-nube.md) | Bases de datos como servicio en la nube (DBaaS) |
| [009](009-consistencia-compensacion.md) | Consistencia entre microservicios vía transacción compensatoria (no Saga formal) |
| [010](010-idempotencia-transacciones.md) | Idempotencia de operaciones financieras vía UUID de transacción |
