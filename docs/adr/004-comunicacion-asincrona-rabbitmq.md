# ADR-004: MensajerÃ­a asÃ­ncrona con RabbitMQ (modelo Pub-Sub)

## Estado
Aceptado

## Contexto
El Switch de Pagos Masivos debe procesar archivos de miles de lÃ­neas sin bloquear al cliente HTTP (Banca Web Empresas) ni acoplar la velocidad de ingesta a la velocidad de procesamiento del Core. El enunciado exige explÃ­citamente RabbitMQ (prohibido Kafka) y un modelo Publicador-Suscriptor real con Exchanges y Routing Keys, no solo colas directas.

## DecisiÃ³n
- Se usa **RabbitMQ** como Ãºnico broker.
- Cada flujo asÃ­ncrono tiene un **Exchange `direct`** dedicado con su **Routing Key**, en lugar de publicar directo al exchange default:
  - `payment.exchange` (Direct, routing key segÃºn clasificaciÃ³n: `onus`/`offus`/`invalid`) â†’ colas `payment.lines.onus.queue`/`payment.lines.offus.queue`/`payment.lines.invalid.queue`: `file-reception-service` publica cada lÃ­nea ya clasificada y las consume ella misma con `concurrency 5-20` (ver ADR-011). El Exchange, no un microservicio de ruteo, decide a quÃ© cola llega cada lÃ­nea.
  - `clearing.exchange` (routing key `clearing.outbound`) â†’ `clearing.outbound.queue`: `file-reception-service` y `account-core-service` publican transacciones Off-Us; `clearinghouse-service` consume.
- El acuse de recibo es **automÃ¡tico** (modo `AUTO` de Spring AMQP): el contenedor confirma el mensaje tras procesarlo sin excepciÃ³n, y lo reencola si falla.

## Por quÃ© Exchange + Routing Key y no solo nombre de cola
Publicar directo a una cola por nombre (exchange default) funciona, pero es un patrÃ³n de "Work Queue" punto a punto, no Pub-Sub. Declarar un Exchange explÃ­cito permite, sin cambiar el cÃ³digo del publicador, aÃ±adir mÃ¡s colas/consumidores suscritos al mismo evento en el futuro (ej. un futuro servicio de auditorÃ­a que tambiÃ©n necesite ver cada lÃ­nea de pago).

## Consecuencias
- (+) El Switch responde con `202 Accepted` de inmediato al subir un archivo; el procesamiento real ocurre fuera del ciclo de vida de esa peticiÃ³n HTTP.
- (+) Un fallo temporal en el Core (ver ADR-009) no tira el archivo completo: cada lÃ­nea fallida se reporta individualmente sin afectar las demÃ¡s.
- (+) El modelo es extensible a mÃ¡s suscriptores sin tocar el publicador (justifica el uso de Exchange/Routing Key en vez de colas directas).
- (-) Requiere operar RabbitMQ (actualmente como contenedor Docker en la misma VM, no como servicio gestionado â€” ver limitaciÃ³n documentada en el bloque de infraestructura).

