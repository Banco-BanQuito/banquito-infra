# ADR-006: Particionamiento declarativo de transacciones en PostgreSQL

## Estado
Aceptado

## Contexto
`account_transaction` es la tabla de mayor crecimiento del sistema (cada depósito, retiro, transferencia o pago la inserta). Sin una estrategia de archivado, las consultas operativas (consulta de movimientos recientes en banca web) se degradan a medida que crece el histórico, y el documento de requisitos del Core exige explícitamente separar "data caliente" de "data fría".

## Decisión
`account_transaction` se crea con `PARTITION BY RANGE (transaction_date)`, con una partición física por mes (`account_transaction_2026_01`, `account_transaction_2026_02`, ...) y una partición `DEFAULT` (`account_transaction_historico`) que recibe cualquier fecha fuera del rango declarado explícitamente.

## Por qué Range Partitioning por fecha y no por otro criterio
El patrón de acceso dominante es "dame los movimientos de los últimos N meses de esta cuenta", por lo que particionar por fecha permite que Postgres descarte particiones completas (partition pruning) en vez de escanear todo el histórico. Particionar por `account_id` no ayudaría a este patrón de consulta y complicaría el archivado por antigüedad.

## Consecuencias
- (+) Las consultas de movimientos recientes solo tocan 1-2 particiones (las del mes actual y anterior).
- (+) Permite "enfriar" datos antiguos (ej. mover una partición vieja a almacenamiento más barato) sin tocar la tabla lógica ni el código de la aplicación.
- (-) La clave primaria debe incluir la columna de partición (`PRIMARY KEY (id, transaction_date)`), lo que exige que cualquier UPDATE/DELETE por solo `id` especifique también la fecha o se resuelva vía índice secundario.
- (-) Requiere un job de mantenimiento (manual o programado) para crear la partición del mes siguiente con anticipación.
