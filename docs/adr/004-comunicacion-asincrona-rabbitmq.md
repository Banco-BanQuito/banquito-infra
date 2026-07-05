# ADR-004: Mensajería asíncrona con RabbitMQ (modelo Pub-Sub)

## Estado
Aceptado

## Contexto
El Switch de Pagos Masivos debe procesar archivos de miles de líneas sin bloquear al cliente HTTP (Banca Web Empresas) ni acoplar la velocidad de ingesta a la velocidad de procesamiento del Core. El enunciado exige explícitamente RabbitMQ (prohibido Kafka) y un modelo Publicador-Suscriptor real con Exchanges y Routing Keys, no solo colas directas.

## Decisión
- Se usa **RabbitMQ** como único broker.
- Cada flujo asíncrono tiene un **Exchange `direct`** dedicado con su **Routing Key**, en lugar de publicar directo al exchange default:
  - `payment.exchange` (Direct, routing key según clasificación: `onus`/`offus`/`invalid`) → colas `payment.lines.onus.queue`/`payment.lines.offus.queue`/`payment.lines.invalid.queue`: `file-reception-service` publica cada línea ya clasificada y las consume ella misma con `concurrency 5-20` (ver ADR-011). El Exchange, no un microservicio de ruteo, decide a qué cola llega cada línea.
  - `clearing.exchange` (routing key `clearing.outbound`) → `clearing.outbound.queue`: `file-reception-service` y `account-core-service` publican transacciones Off-Us; `clearinghouse-service` consume.
- El acuse de recibo es **automático** (modo `AUTO` de Spring AMQP): el contenedor confirma el mensaje tras procesarlo sin excepción, y lo reencola si falla.

## Por qué Exchange + Routing Key y no solo nombre de cola
Publicar directo a una cola por nombre (exchange default) funciona, pero es un patrón de "Work Queue" punto a punto, no Pub-Sub. Declarar un Exchange explícito permite, sin cambiar el código del publicador, añadir más colas/consumidores suscritos al mismo evento en el futuro (ej. un futuro servicio de auditoría que también necesite ver cada línea de pago).

## Consecuencias
- (+) El Switch responde con `202 Accepted` de inmediato al subir un archivo; el procesamiento real ocurre fuera del ciclo de vida de esa petición HTTP.
- (+) Un fallo temporal en el Core (ver ADR-009) no tira el archivo completo: cada línea fallida se reporta individualmente sin afectar las demás.
- (+) El modelo es extensible a más suscriptores sin tocar el publicador (justifica el uso de Exchange/Routing Key en vez de colas directas).
- (-) Requiere operar RabbitMQ (actualmente como contenedor Docker en la misma VM, no como servicio gestionado — ver limitación documentada en el bloque de infraestructura).
