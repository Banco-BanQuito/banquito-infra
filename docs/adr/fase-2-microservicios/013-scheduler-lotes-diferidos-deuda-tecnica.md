# ADR-013 (Fase 2): TaskScheduler en memoria para lotes diferidos — deuda técnica identificada y aceptada

## Estado
Aceptado con reserva — deuda técnica conocida, documentada, no resuelta en esta fase

## Contexto
Los lotes de pago recibidos después de la hora de corte (`cutoff-hour`) no se procesan de inmediato: se marcan como `PROGRAMADO` y deben ejecutarse automáticamente a las 00:01 del día siguiente, sin intervención de un operador.

## Decisión
El disparo del procesamiento diferido usa un `TaskScheduler` de Spring, en memoria, dentro del propio proceso de `file-reception-service`.

## Por qué esto es una decisión débil, y por qué se documenta igual como ADR
Un `TaskScheduler` en memoria no sobrevive a un reinicio del contenedor: si el proceso se reinicia por un despliegue, un crash, o una actualización de Watchtower en cualquier momento antes de la hora programada, la tarea agendada se pierde **sin dejar ningún rastro**, y el lote queda huérfano indefinidamente en estado `PROGRAMADO`, sin que nadie lo note hasta que un cliente pregunte por qué su pago nunca se procesó. Esto no es una hipótesis: se confirmaron 4 casos reales de lotes huérfanos por esta causa exacta durante el desarrollo de esta fase.

## Por qué se acepta como decisión "en curso" y no se revierte de inmediato
Corregirlo correctamente exige uno de tres caminos, cada uno con costo de implementación no trivial dentro del tiempo disponible de esta fase: (1) persistir el lote programado en base de datos con un job de polling periódico que lo recoja, (2) usar Quartz con `JobStore` persistente en vez del `TaskScheduler` en memoria de Spring, o (3) reemplazar la espera en memoria por un mensaje diferido en RabbitMQ con TTL y dead-letter exchange, aprovechando la infraestructura de colas que el sistema ya tiene (ver ADR-004 de esta fase). Ninguna de las tres se implementó todavía.

## Consecuencias
- (+) Documentar esta limitación de forma explícita, con evidencia de los 4 casos reales encontrados, demuestra criterio de ingeniería: identificar y comunicar una deuda técnica conocida es más defendible ante un evaluador que dejarla sin mencionar y que se descubra por otra vía.
- (-) Todo lote programado para procesarse después de la hora de corte está en riesgo de pérdida silenciosa si el sistema se reinicia antes de esa hora — riesgo real y no hipotético en un entorno donde los despliegues son frecuentes (ver ADR-007 de esta fase, Watchtower).
- (-) No existe actualmente ninguna alerta ni monitoreo que detecte un lote huérfano en `PROGRAMADO` más allá de su hora esperada — el problema se descubre reactivamente, no proactivamente.
