# 0009. Procesamiento de lote por línea (partial success), asíncrono

## Estado
Aceptado (histórico — el segundo parcial reemplaza el `@Async` casero por RabbitMQ, ver ADR-0017)

## Contexto
Un lote de nómina no debe fallar completo porque una sola cuenta destino sea inválida; el usuario tampoco debe esperar bloqueado a que se procesen miles de líneas.

## Decisión
Procesamiento `@Async`, cada línea con su propio try/catch y estado individual (`REJECTED` no detiene el lote). Comisión por transacción configurable en base de datos por rangos de volumen (`SERVICE_FEE_RULE`); IVA hardcodeado al 15% como constante Java. Contabilización de doble partida real: dos cuentas institucionales distintas para ingreso por servicio e IVA por pagar. Un scheduler cada 10 minutos detecta y recupera lotes atascados en `PROCESSING` por más de 20 minutos.

## Alternativas consideradas
- Transacción todo-o-nada con rollback completo del lote.
- Motor de reglas (Drools) para las tarifas en vez de una tabla simple.
- Cola de mensajes en vez de `@Async` + `@Scheduled` casero.

## Consecuencias
- Refleja cómo funcionan los switches de pago reales — un beneficiario inválido no tumba la nómina completa.
- El IVA fijo (vs. comisión parametrizada) sugiere que se asumió constante por ley, mientras la comisión sí se sabía variable por requerimiento explícito del parcial.
- El scheduler de recuperación demuestra que el equipo anticipó fallos a mitad de procesamiento asíncrono.
