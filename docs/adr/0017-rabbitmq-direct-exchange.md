# 0017. RabbitMQ con Direct Exchange para el enrutamiento de líneas de pago

## Estado
Aceptado — supersede a ADR-0003 y ADR-0009

## Contexto
El Switch recibe archivos de pago masivo; cada línea debe clasificarse en exactamente una de tres categorías: transacción interna (on-us), transacción hacia otro banco (off-us), o línea inválida. Esto reemplaza el modelo del primer parcial, donde cada línea se procesaba síncronamente con una llamada HTTP bloqueante al Core.

## Decisión
RabbitMQ con Direct Exchange (`payment.exchange`), routing keys exactas: `onus` → `payment.lines.onus.queue`, `offus` → `payment.lines.offus.queue`, `invalid` → `payment.lines.invalid.queue`. Un segundo exchange (`clearing.exchange`) con routing key `clearing.outbound` para el flujo de salida hacia la cámara de compensación.

## Alternativas consideradas
- **Fanout**: descartado — todos los consumidores recibirían todas las líneas sin poder filtrar por clasificación, obligando a filtrar en el consumidor y desperdiciando ancho de banda.
- **Topic**: descartado — permite patrones con wildcards, pero la clasificación es un valor exacto y cerrado (3 categorías fijas), no un espacio de patrones jerárquicos que crezca.
- **Seguir síncrono (como en el primer parcial)**: descartado explícitamente — no soporta el volumen de las pruebas de carga (10 a 13,000 líneas) sin bloquear el hilo de la petición HTTP original.

## Consecuencias
- Desacople temporal real entre recepción del archivo y procesamiento de cada línea — el usuario recibe confirmación de "lote recibido" sin esperar a que se procesen miles de líneas.
- Consistencia eventual, gestionada con estado de lote (`PaymentBatch.status`) consultable por el usuario.
- Se necesitó tolerancia a duplicados vía índice único en `batchId` — bug real encontrado y corregido durante el desarrollo: el índice nunca se creó en MongoDB porque `auto-index-creation` estaba deshabilitado por defecto en Spring Data MongoDB, permitiendo inserciones duplicadas concurrentes.
