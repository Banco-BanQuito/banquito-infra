# 0013. Notificaciones SMTP: asíncronas en Switch, síncronas y bloqueantes en Core

## Estado
Aceptado (histórico)

## Contexto
Ambos backends necesitan notificar por correo (transacciones en Core, resultados de lote en Switch).

## Decisión
`JavaMailSender` vía Gmail+STARTTLS en ambos. El Switch envía notificaciones dentro de su flujo ya `@Async` (nunca bloquea al usuario). El Core las envía de forma síncrona dentro de cada transacción `@Transactional`, a pesar de tener un `AsyncConfig.java` con `@EnableAsync` ya declarado y sin conectar a este flujo — cada transferencia manual desde la intranet espera a que Gmail SMTP responda antes de devolver la respuesta HTTP.

## Alternativas consideradas
- `@Async` consistente en ambos backends.
- Cola de mensajes dedicada para envío de correo.

## Consecuencias
- El Switch fue diseñado desde el inicio pensando en lotes (requiere asincronía por naturaleza), así que el `@Async` llegó "gratis" al envolver todo el procesamiento.
- El Core se pensó para operaciones interactivas de un cajero, donde el bloqueo SMTP probablemente no se percibió como problema.
- El `AsyncConfig` presente pero no conectado sugiere una optimización planeada y no completada.
