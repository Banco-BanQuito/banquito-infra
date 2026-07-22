# ADR-013 (Fase 1): Notificaciones SMTP — asíncronas en Switch, síncronas en Core

## Estado
Aceptado (histórico)

## Contexto
Ambos backends necesitan notificar por correo: el Core al completar una transacción manual desde la intranet, el Switch al finalizar el procesamiento de un lote completo.

## Decisión
`JavaMailSender` vía Gmail + STARTTLS en ambos backends, con cuentas de Gmail distintas por servicio. El Switch envía la notificación dentro de su flujo ya `@Async` (ver ADR-009 de Fase 1), por lo que nunca bloquea al usuario. El Core la envía de forma síncrona, dentro de la misma transacción `@Transactional` de la operación bancaria — a pesar de tener un `AsyncConfig.java` con `@EnableAsync` ya declarado en el proyecto, sin conectar a este flujo específico.

## Por qué esta asimetría no es arbitraria
El Switch se diseñó desde el inicio para procesar lotes de cientos de líneas, un escenario que exige asincronía por naturaleza propia del problema — el envío de correo simplemente heredó esa asincronía al vivir dentro del mismo flujo. El Core, en cambio, se diseñó para operaciones interactivas de un solo operador de agencia procesando una transacción a la vez desde la intranet; en ese contexto, el tiempo adicional de una llamada SMTP (con timeout de 5-8 segundos configurado) se consideró aceptable dentro del tiempo de respuesta esperado de una operación de ventanilla.

## Consecuencias
- (+) El Switch nunca bloquea al usuario por causa del envío de correo, incluso bajo lotes grandes.
- (-) Cada transacción manual desde la intranet del Core espera bloqueada a que el servidor SMTP de Gmail responda antes de devolver la confirmación al operador — en el peor caso, hasta 8 segundos de latencia añadida a una operación que de otro modo sería casi instantánea.
- (-) La presencia de `AsyncConfig.java` sin conectar al flujo de notificación del Core es evidencia directa de una optimización que se planeó (probablemente para replicar el mismo patrón del Switch) pero no se completó dentro del plazo del parcial.
