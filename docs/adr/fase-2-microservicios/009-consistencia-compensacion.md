# ADR-009: Consistencia entre microservicios vía transacción compensatoria

## Estado
Aceptado

## Contexto
`account-core-service` afecta el saldo del cliente y luego debe pedirle a `accounting-service` que genere el asiento de partida doble correspondiente, vía gRPC síncrono. Al ser dos bases de datos distintas, no existe una transacción distribuida ACID real entre ambas: el Core puede tener éxito y la contabilidad puede fallar (rechazo por regla de suma cero, timeout de red, etc.).

## Decisión
Si la llamada a `accounting-service` falla o es rechazada, `account-core-service` ejecuta de inmediato una **transacción compensatoria (reverso)** dentro de su propia base de datos para anular el movimiento del cliente, en lugar de dejar el saldo afectado sin su contraparte contable.

No se implementó un patrón Saga formal (con orquestador de pasos y eventos de compensación encolados) porque el flujo es de un solo paso de compensación (revertir el movimiento local), no una secuencia larga de pasos que requiera coordinación entre más de dos servicios.

## Por qué no 2PC (two-phase commit) ni Saga orquestada
2PC requeriría que ambas bases de datos participen en un coordinador de transacciones distribuidas, lo cual ninguna de las dos soporta de forma nativa entre Postgres y otro Postgres en instancias/esquemas separados sin tooling adicional, y además acopla fuertemente la disponibilidad de ambos servicios. Una Saga orquestada sería sobre-ingeniería para un flujo de dos pasos donde el segundo paso (compensar) es local al mismo servicio que inició la operación.

## Consecuencias
- (+) El saldo del cliente nunca queda "huérfano" sin su asiento contable correspondiente: o ambos existen, o ninguno.
- (+) Solución simple, sin infraestructura adicional de orquestación de sagas.
- (-) Existe una ventana de tiempo muy breve entre el débito/crédito original y su reverso donde el saldo está "incorrecto" si alguien lo consulta exactamente en ese instante (trade-off aceptado: la ventana es del orden de milisegundos, limitada por el timeout de la llamada gRPC).
- (-) Este fue precisamente el patrón cuya ausencia causó un bug real detectado durante el desarrollo (créditos sin validar el resultado del débito inicial en `routing-service`), corregido sincronizando el resultado del débito antes de permitir cualquier crédito asociado.
