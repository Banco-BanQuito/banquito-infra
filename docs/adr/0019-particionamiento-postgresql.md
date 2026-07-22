# 0019. Particionamiento declarativo de PostgreSQL por accounting_date

## Estado
Aceptado

## Contexto
La tabla `account_core.account_transaction` crece indefinidamente — cada transacción bancaria genera una fila. Las consultas más frecuentes filtran por rango de fechas (estados de cuenta, reportes).

## Decisión
RANGE partitioning declarativo por la columna `accounting_date` (fecha contable) — no por `transaction_date` (timestamp de auditoría, columna distinta). La distinción se verificó explícitamente en producción tras un primer intento fallido de `EXPLAIN` sobre la columna equivocada, que mostraba escaneo completo de las 9 particiones en vez de partition pruning.

## Alternativas consideradas
- Tabla única sin particionar — simple pero degrada con el volumen.
- Particionar por `transaction_date` — columna equivocada para el patrón de consulta real del negocio.
- Sharding manual a nivel de aplicación — innecesariamente complejo a esta escala.

## Consecuencias
- Partition pruning confirmado en producción: `EXPLAIN` muestra que se escanea solo 1 partición de 9 al filtrar por `accounting_date`, contra las 9 completas al filtrar por la columna equivocada.
- Costo de mantenimiento: cada partición nueva requiere crearse antes de que llegue esa fecha.
