# 0008. Locking pesimista ordenado para transferencias en el Core

## Estado
Aceptado

## Contexto
Dos transferencias cruzadas simultáneas (A→B y B→A) pueden producir un deadlock si cada transacción bloquea las cuentas involucradas en un orden distinto.

## Decisión
`SELECT ... FOR UPDATE` (locking pesimista) para todo movimiento de saldo en el Core, con las cuentas bloqueadas siempre en **orden alfabético por número de cuenta**, sin importar el sentido de la transferencia. El Switch, en cambio, usa locking optimista para el estado del lote (reintento ante `ObjectOptimisticLockingFailureException`).

## Alternativas consideradas
- Locking optimista también para saldo (más simple, pero insuficiente para garantizar corrección en operaciones financieras concurrentes).
- Sin bloqueo explícito, confiando en el aislamiento por defecto de la base de datos (riesgo real de condiciones de carrera en saldo).

## Consecuencias
- Previene deadlock por diseño, sin necesitar detección/retry a nivel de base de datos.
- Demuestra comprensión real de concurrencia bancaria, no trivial para un equipo estudiantil.
- Elección de estrategia de locking apropiada a cada dominio: pesimista donde la corrección es crítica (dinero), optimista donde los conflictos son raros y reintentar es barato (estado de workflow).
