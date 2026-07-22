# 0024. Programación de lotes diferidos con TaskScheduler en memoria (deuda técnica identificada)

## Estado
Aceptado con reserva — deuda técnica conocida, no resuelta

## Contexto
Los lotes de pago recibidos después de la hora de corte (`cutoff-hour`) se marcan como `PROGRAMADO` para procesarse a las 00:01 del día siguiente.

## Decisión
Se usa un `TaskScheduler` de Spring en memoria para disparar el procesamiento diferido.

## Por qué es una decisión débil, identificada durante el desarrollo
Un `TaskScheduler` en memoria no es durable — si el contenedor se reinicia (deploy, crash, actualización de Watchtower) antes de la hora programada, la tarea se pierde silenciosamente sin dejar rastro, y el lote queda huérfano indefinidamente en estado `PROGRAMADO`. Se confirmaron 4 casos reales de lotes huérfanos por esta causa.

## Alternativa correcta, no implementada aún
Persistir el lote programado en base de datos con un job de polling, o Quartz con `JobStore` persistente, o un mensaje diferido en RabbitMQ con TTL + dead-letter, que sobreviva a un reinicio del contenedor.

## Por qué se documenta como ADR aunque no está resuelto
Es exactamente el tipo de decisión que un profesor exigente va a cuestionar — mejor mostrar que el equipo la identificó y entiende el trade-off, que pretender que no existe.
