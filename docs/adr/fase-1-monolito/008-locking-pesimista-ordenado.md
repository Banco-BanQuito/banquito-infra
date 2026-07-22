# ADR-008 (Fase 1): Locking pesimista con bloqueo ordenado alfabéticamente para transferencias

## Estado
Aceptado — se mantiene vigente en Fase 2 y Fase 3 sin cambios

## Contexto
Dos transferencias cruzadas simultáneas (cliente A transfiere a B en el mismo instante en que B transfiere a A) pueden producir un interbloqueo (deadlock) si cada transacción de base de datos bloquea las cuentas involucradas en un orden distinto — una espera el lock que tiene la otra, y viceversa.

## Decisión
Todo movimiento de saldo en el Core usa `SELECT ... FOR UPDATE` (locking pesimista, vía `findWithLockByAccountNumber` + `@Lock(LockModeType.PESSIMISTIC_WRITE)` de Spring Data), y en operaciones que afectan dos cuentas (transferencias), ambas cuentas se bloquean siempre en **orden alfabético por número de cuenta**, sin importar el sentido real de la transferencia.

## Por qué pesimista y no optimista para el saldo
El locking optimista (verificar una versión al guardar y reintentar si cambió) es adecuado cuando los conflictos son poco frecuentes y el costo de un reintento es bajo — es lo que efectivamente se usa para el estado del lote en el Switch (ver más abajo). Para el saldo de una cuenta bancaria, un conflicto no detectado a tiempo significa dinero mal calculado, no un simple reintento de UI: el costo de un error es demasiado alto para aceptar la ventana de riesgo que el locking optimista tolera. El locking pesimista bloquea la fila desde el inicio de la transacción, garantizando que ninguna otra operación pueda leer o escribir el mismo saldo hasta que la primera termine.

## Por qué bloquear en orden alfabético y no en el orden en que llega la transferencia
Si cada transacción bloqueara primero la cuenta origen y luego la destino (el orden "natural" de una transferencia), dos transferencias cruzadas (A→B y B→A) bloquearían en órdenes opuestos, generando un deadlock real que la base de datos eventualmente resuelve abortando una de las dos transacciones — con el correspondiente reintento y latencia adicional. Ordenar el bloqueo alfabéticamente por número de cuenta, independientemente del sentido de la transferencia, garantiza que **todas** las transacciones concurrentes bloqueen las cuentas compartidas en el mismo orden, eliminando la posibilidad de deadlock por diseño, no por manejo de excepciones.

## Consecuencias
- (+) Elimina deadlocks entre transferencias cruzadas por construcción, sin necesitar lógica de detección y reintento.
- (+) Demuestra un nivel de comprensión de concurrencia en sistemas bancarios que va más allá de lo mínimo exigible en un ejercicio académico.
- (+) Coexiste coherentemente con locking optimista en el Switch para el estado del lote — cada mecanismo se aplicó al dominio donde su trade-off tiene sentido: pesimista donde el costo de un error es alto (dinero), optimista donde los conflictos son raros y el costo de reintentar es bajo (workflow de estado).
- (-) El locking pesimista reduce el paralelismo posible sobre una misma cuenta: si un cliente tiene múltiples operaciones concurrentes sobre su propia cuenta, se serializan estrictamente, aceptado como trade-off correcto frente al riesgo de saldo incorrecto.
