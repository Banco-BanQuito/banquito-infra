# ADR-011: EliminaciÃ³n de routing-service, el Exchange de RabbitMQ hace el ruteo

## Estado
Aceptado

## Contexto
El profesor observÃ³ que no tiene sentido mantener un microservicio dedicado exclusivamente a "rutear" mensajes (decidir si una lÃ­nea de pago es On-Us u Off-Us y reenviarla) cuando RabbitMQ ya resuelve ese problema mediante Exchanges y Routing Keys. `routing-service` consumÃ­a una Ãºnica cola (`payment.lines.queue`) y decidÃ­a en cÃ³digo (`determineRoute()` + switch) a quÃ© flujo pertenecÃ­a cada lÃ­nea, duplicando una responsabilidad que el propio broker ya cumple.

## DecisiÃ³n
- El Direct Exchange `payment.exchange` pasa a tener 3 bindings (`onus`, `offus`, `invalid`), cada uno a su propia cola. `file-reception-service` (que ya calculaba la clasificaciÃ³n On-Us/Off-Us con su catÃ¡logo paramÃ©trico) decide la routing key al publicar; el Exchange entrega cada mensaje a la cola correspondiente sin que ningÃºn servicio tenga que re-evaluarlo.
- Toda la lÃ³gica de orquestaciÃ³n de lote que vivÃ­a en `routing-service` (idempotencia por lÃ­nea, dÃ©bito inicial del lote, crÃ©dito On-Us vÃ­a REST a `account-core-service`, adaptaciÃ³n y publicaciÃ³n Off-Us hacia `clearinghouse-service`, cÃ¡lculo de comisiÃ³n vÃ­a gRPC a `tariff-service`, devoluciÃ³n de rechazados, tracking de estado del lote en Mongo) se mueve a `file-reception-service`, que ahora consume directamente las 3 colas.
- `account-core-service` (Core) no cambia: sigue siendo un sistema pasivo que solo expone sus endpoints REST, tal como exige el documento de requisitos ("Core Bancario... actÃºa como un sistema pasivo y subordinado a las instrucciones del Switch").
- El microservicio `routing-service` se elimina de la topologÃ­a (`docker-compose.switch.yml`, Kong Switch). Su endpoint de estado del lote (`GET /api/v2/payments/batches/{batchId}/status`) se mueve a `file-reception-service`.

## Por quÃ© file-reception-service y no account-core-service
Se evaluÃ³ mover esta lÃ³gica a `account-core-service`, pero el documento de requisitos del Core (BancoBanQuito-Core-V2) es explÃ­cito: el Core debe ser pasivo, y es el Switch quien orquesta y llama a su API de forma sÃ­ncrona (RF-03 del Switch: "el Switch consumirÃ¡ de forma sÃ­ncrona el API del Core Bancario"). Mover la orquestaciÃ³n a `account-core-service` invertirÃ­a esa relaciÃ³n documentada. `file-reception-service` ya es dueÃ±o del catÃ¡logo de clasificaciÃ³n y del ciclo de vida del lote/archivo, por lo que absorber el despacho de lÃ­neas es una extensiÃ³n natural de su responsabilidad existente, sin inventar un nuevo microservicio ni tocar el Core.

## Consecuencias
- (+) Se elimina un microservicio completo (menos partes mÃ³viles, menos superficie de despliegue).
- (+) El ruteo real (a quÃ© cola llega cada mensaje) ahora lo hace exclusivamente el Exchange, no cÃ³digo de aplicaciÃ³n.
- (+) Se elimina un salto de red innecesario: `file-reception-service` ya no necesita una llamada REST "a sÃ­ mismo" para el crÃ©dito On-Us; ahora invoca directamente el cliente REST hacia `account-core-service`.
- (-) `file-reception-service` gana mÃ¡s responsabilidades (Mongo para tracking de lote + gRPC a tariff/notification), lo que lo acerca a ser un "servicio mÃ¡s grande" dentro del dominio Switch â€” aceptado porque esas responsabilidades son inherentes al ciclo de vida del lote que este servicio ya orquesta.

