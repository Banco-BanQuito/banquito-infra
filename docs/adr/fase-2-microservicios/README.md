# ADR — Fase 2: Microservicios (Segundo Parcial)

Este directorio documenta las decisiones de arquitectura tomadas durante la evolución del Core Bancario y el Switch de Pagos Masivos, de monolito dual (Fase 1) a un ecosistema de microservicios sobre Docker Compose.

| ADR | Título |
|---|---|
| [001](001-microservicios-y-dominios.md) | Por qué 8 microservicios específicos, y no solo el mínimo pedido |
| [002](002-persistencia-poliglota.md) | Persistencia políglota: PostgreSQL, MySQL y MongoDB |
| [003](003-comunicacion-sincrona-grpc-rest.md) | gRPC dentro de cada dominio, REST al cruzar de dominio |
| [004](004-comunicacion-asincrona-rabbitmq.md) | Mensajería asíncrona con RabbitMQ |
| [005](005-api-gateway-kong.md) | API Gateway con Kong |
| [007](007-despliegue-docker-compose.md) | Orquestación con Docker Compose y actualización continua con Watchtower |
| [008](008-bases-datos-nube.md) | Bases de datos administradas por un proveedor de nube |
| [011](011-eliminacion-routing-service.md) | Eliminación del servicio de ruteo — RabbitMQ hace el ruteo directamente |
| [012](012-redes-docker-separadas.md) | Redes Docker separadas entre Core y Switch |
| [013](013-scheduler-lotes-diferidos-deuda-tecnica.md) | Aviso — el reloj de lotes diferidos no sobrevive a un reinicio |
| [014](014-cobertura-pruebas-70-porciento.md) | Pruebas unitarias con 70% de cobertura, solo en Controllers y Services |

> **Nota:** los números 006, 009 y 010 existieron en un borrador anterior y se eliminaron. Documentaban el particionamiento de PostgreSQL, la transacción compensatoria entre account-core-service y accounting-service, y la idempotencia por identificador único — las tres cosas están descritas casi palabra por palabra en el documento de requisitos del Core V2 (RF-01, RF-05 y Anexo 2), y la idempotencia ya estaba pedida desde el Core V1. No fueron decisiones del equipo, fueron requisitos explícitos, así que no califican como ADR.
