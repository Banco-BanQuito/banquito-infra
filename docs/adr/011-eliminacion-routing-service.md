# ADR-011: Eliminación de routing-service, el Exchange de RabbitMQ hace el ruteo

## Estado
Aceptado

## Contexto
El profesor observó que no tiene sentido mantener un microservicio dedicado exclusivamente a "rutear" mensajes (decidir si una línea de pago es On-Us u Off-Us y reenviarla) cuando RabbitMQ ya resuelve ese problema mediante Exchanges y Routing Keys. `routing-service` consumía una única cola (`payment.lines.queue`) y decidía en código (`determineRoute()` + switch) a qué flujo pertenecía cada línea, duplicando una responsabilidad que el propio broker ya cumple.

## Decisión
- El Direct Exchange `payment.exchange` pasa a tener 3 bindings (`onus`, `offus`, `invalid`), cada uno a su propia cola. `file-reception-service` (que ya calculaba la clasificación On-Us/Off-Us con su catálogo paramétrico) decide la routing key al publicar; el Exchange entrega cada mensaje a la cola correspondiente sin que ningún servicio tenga que re-evaluarlo.
- Toda la lógica de orquestación de lote que vivía en `routing-service` (idempotencia por línea, débito inicial del lote, crédito On-Us vía REST a `account-core-service`, adaptación y publicación Off-Us hacia `clearinghouse-service`, cálculo de comisión vía gRPC a `tariff-service`, devolución de rechazados, tracking de estado del lote en Mongo) se mueve a `file-reception-service`, que ahora consume directamente las 3 colas.
- `account-core-service` (Core) no cambia: sigue siendo un sistema pasivo que solo expone sus endpoints REST, tal como exige el documento de requisitos ("Core Bancario... actúa como un sistema pasivo y subordinado a las instrucciones del Switch").
- El microservicio `routing-service` se elimina de la topología (`docker-compose.switch.yml`, Kong Switch). Su endpoint de estado del lote (`GET /api/v2/payments/batches/{batchId}/status`) se mueve a `file-reception-service`.

## Por qué file-reception-service y no account-core-service
Se evaluó mover esta lógica a `account-core-service`, pero el documento de requisitos del Core (BancoBanQuito-Core-V2) es explícito: el Core debe ser pasivo, y es el Switch quien orquesta y llama a su API de forma síncrona (RF-03 del Switch: "el Switch consumirá de forma síncrona el API del Core Bancario"). Mover la orquestación a `account-core-service` invertiría esa relación documentada. `file-reception-service` ya es dueño del catálogo de clasificación y del ciclo de vida del lote/archivo, por lo que absorber el despacho de líneas es una extensión natural de su responsabilidad existente, sin inventar un nuevo microservicio ni tocar el Core.

## Consecuencias
- (+) Se elimina un microservicio completo (menos partes móviles, menos superficie de despliegue).
- (+) El ruteo real (a qué cola llega cada mensaje) ahora lo hace exclusivamente el Exchange, no código de aplicación.
- (+) Se elimina un salto de red innecesario: `file-reception-service` ya no necesita una llamada REST "a sí mismo" para el crédito On-Us; ahora invoca directamente el cliente REST hacia `account-core-service`.
- (-) `file-reception-service` gana más responsabilidades (Mongo para tracking de lote + gRPC a tariff/notification), lo que lo acerca a ser un "servicio más grande" dentro del dominio Switch — aceptado porque esas responsabilidades son inherentes al ciclo de vida del lote que este servicio ya orquesta.
