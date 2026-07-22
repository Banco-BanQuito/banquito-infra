# ADR-009 (Fase 1): Procesamiento de lote línea por línea (partial success), asíncrono con `@Async`

## Estado
Aceptado (histórico — el mecanismo `@Async` casero se reemplaza por RabbitMQ en Fase 2, ver ADR-004 de Fase 2)

## Contexto
Un lote de nómina puede contener cientos de beneficiarios; si uno solo tiene una cuenta inválida o inactiva, el resto del lote (sueldos de decenas de otros empleados) no debe quedar bloqueado ni revertido.

## Decisión
El procesamiento del lote corre en un método `@Async`, devolviendo control inmediato al llamador HTTP. Cada línea se procesa con su propio `try/catch` y estado individual (`REJECTED` no detiene el lote); un scheduler adicional cada 10 minutos detecta y recupera lotes atascados en estado `PROCESSING` por más de 20 minutos. La comisión por transacción es configurable en base de datos por rangos de volumen (`SERVICE_FEE_RULE`); el IVA está hardcodeado al 15% como constante Java. Cada línea exitosa genera doble partida contable real: crédito a una cuenta institucional de ingresos por servicio y otra de IVA por pagar, por montos distintos.

## Por qué procesamiento por línea y no transacción todo-o-nada del lote completo
Un lote todo-o-nada (rollback completo si una sola línea falla) sería más simple de implementar, pero no refleja cómo opera un switch de pagos real: el beneficiario número 47 con una cuenta cerrada no puede ser motivo para que los otros 299 empleados de la nómina no reciban su sueldo ese mes. El procesamiento por línea, con estado individual persistido, es la decisión que hace que el sistema sea utilizable en un escenario real de nómina masiva.

## Por qué IVA fijo pero comisión configurable
La comisión por transacción se sabía variable por requerimiento explícito del parcial (debía escalar según el volumen de transacciones exitosas del lote), así que se modeló desde el inicio como datos en tabla (`SERVICE_FEE_RULE`). El IVA, en cambio, es una tasa fijada por ley tributaria ecuatoriana, no una variable de negocio del banco — se trató como una constante porque, a diferencia de la comisión, no había ningún escenario de prueba que exigiera cambiarla en tiempo de ejecución.

## Consecuencias
- (+) Un archivo de nómina con errores puntuales no bloquea el pago de la mayoría de beneficiarios válidos — comportamiento correcto y esperado en un sistema de pagos real.
- (+) El scheduler de recuperación de lotes atascados demuestra que el equipo anticipó fallos a mitad de un procesamiento asíncrono, no solo el camino feliz.
- (+) La contabilización de doble partida (ingreso por servicio + IVA por pagar en cuentas institucionales separadas) es correcta desde el punto de vista contable, no una simplificación.
- (-) `@Async` de Spring no persiste su cola de tareas: si el proceso se reinicia a mitad de un lote, el estado queda en lo último persistido en base de datos, sin garantía de reanudación automática del resto del archivo — limitación que RabbitMQ, con sus colas durables, resuelve en la Fase 2.
