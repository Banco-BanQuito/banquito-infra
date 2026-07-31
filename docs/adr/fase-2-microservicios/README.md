# ADR — Fase 2: Microservicios (Segundo Parcial)

Este directorio documenta las decisiones de arquitectura tomadas durante la evolución del Core Bancario y el Switch de Pagos Masivos, de monolito dual (Fase 1) a un ecosistema de microservicios sobre Docker Compose.

| ADR | Título |
|---|---|
| [001](001-microservicios-y-dominios.md) | Por qué 8 microservicios específicos, y no solo el mínimo pedido |
| [002](002-persistencia-poliglota.md) | Qué motor le toca a cada microservicio |
| [003](003-comunicacion-sincrona-grpc-rest.md) | Reservar REST solo para cruzar de dominio, gRPC para todo lo demás |
| [004](004-comunicacion-asincrona-rabbitmq.md) | Exchange con Routing Key para el modelo Publicador-Suscriptor |
| [005](005-api-gateway-kong.md) | API Gateway con Kong |
| [006](006-watchtower-actualizacion-automatica.md) | Watchtower para actualizar automáticamente los contenedores |
| [007](007-bases-datos-nube.md) | Una instancia compartida por motor, con espacios lógicos separados |
| [008](008-eliminacion-routing-service.md) | Eliminación del servicio de ruteo — RabbitMQ hace el ruteo directamente |
| [009](009-redes-docker-separadas.md) | Redes Docker separadas entre Core y Switch |
| [010](010-scheduler-lotes-diferidos-deuda-tecnica.md) | Aviso — el reloj de lotes diferidos no sobrevive a un reinicio |

> **Nota:** se revisó cada ADR contra los 4 documentos de requisitos reales (Core V1, Switch V1, Core V2, Switch V2) y contra lo que el profesor indicó directamente en clase. Donde una parte de la decisión ya venía dada, el ADR se dejó enfocado solo en la parte que sí fue decisión real del equipo:
> - **ADR-002:** que hubiera bases relacionales y documentales a la vez fue requisito académico. La decisión real es cuál microservicio usa cuál motor, y por qué dos motores relacionales (Postgres y MySQL) en vez de uno solo.
> - **ADR-003:** que las llamadas entre microservicios fueran por gRPC fue instrucción general del proyecto. La decisión real es no seguir esa regla en un solo caso: usar REST específicamente al cruzar de dominio.
> - **ADR-004:** que el broker fuera RabbitMQ (Kafka no permitido) y el modelo Publicador-Suscriptor, fue instrucción directa del profesor. La decisión real es el diseño de Exchange y Routing Key.
> - **ADR-006:** que el despliegue fuera con Docker Compose fue instrucción directa del profesor. La decisión real es usar Watchtower para actualizar sin acceso manual a la VM.
> - **ADR-007:** que la base de datos de producción fuera un servicio en la nube fue instrucción del profesor. La decisión real es repartir 8 microservicios en instancias compartidas con espacios lógicos separados, para no pasarse del presupuesto.
>
> Se eliminaron por completo los ADR que documentaban el particionamiento de PostgreSQL, la transacción compensatoria entre account-core-service y accounting-service, y la idempotencia por identificador único — las tres cosas están descritas casi palabra por palabra en el documento de requisitos del Core V2 (RF-01, RF-05 y Anexo 2), y la idempotencia ya estaba pedida desde el Core V1.
>
> También se quitó el ADR de cobertura de pruebas al 70%: el número lo pedía el curso, y la forma de llegar ahí (pruebas unitarias con Mockito, más rápidas que montar infraestructura de prueba) no fue una alternativa seriamente debatida, fue la opción obvia dado el tiempo disponible — no calificaba como decisión de arquitectura.
