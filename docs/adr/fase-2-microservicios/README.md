# ADR — Fase 2: Microservicios (Segundo Parcial)

Este directorio documenta las decisiones de arquitectura tomadas durante la evolución del Core Bancario y el Switch de Pagos Masivos, de monolito dual (Fase 1) a un ecosistema de microservicios sobre Docker Compose.

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
| [011](011-eliminacion-routing-service.md) | Eliminación de routing-service, el Exchange de RabbitMQ hace el ruteo |
| [012](012-redes-docker-separadas.md) | Redes Docker separadas entre Core y Switch |
| [013](013-scheduler-lotes-diferidos-deuda-tecnica.md) | Aviso — el reloj de lotes diferidos no sobrevive a un reinicio |
| [014](014-cobertura-pruebas-70-porciento.md) | Pruebas unitarias con 70% de cobertura, solo en Controllers y Services |

> **Nota de revisión:** el ADR-006 (particionamiento) documenta la partición por `transaction_date`. Verificación en vivo contra la base de datos real (con `EXPLAIN`) durante el desarrollo de Fase 3 confirmó que la columna que efectivamente produce partition pruning es `accounting_date` — son dos columnas distintas del mismo modelo. Pendiente de confirmar con el autor original si esto es un error de documentación o si el esquema cambió después de escrito el ADR.
