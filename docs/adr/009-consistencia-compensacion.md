# ADR-009: Consistencia entre microservicios vÃ­a transacciÃ³n compensatoria

## Estado
Aceptado

## Contexto
`account-core-service` afecta el saldo del cliente y luego debe pedirle a `accounting-service` que genere el asiento de partida doble correspondiente, vÃ­a gRPC sÃ­ncrono. Al ser dos bases de datos distintas, no existe una transacciÃ³n distribuida ACID real entre ambas: el Core puede tener Ã©xito y la contabilidad puede fallar (rechazo por regla de suma cero, timeout de red, etc.).

## DecisiÃ³n
Si la llamada a `accounting-service` falla o es rechazada, `account-core-service` ejecuta de inmediato una **transacciÃ³n compensatoria (reverso)** dentro de su propia base de datos para anular el movimiento del cliente, en lugar de dejar el saldo afectado sin su contraparte contable.

No se implementÃ³ un patrÃ³n Saga formal (con orquestador de pasos y eventos de compensaciÃ³n encolados) porque el flujo es de un solo paso de compensaciÃ³n (revertir el movimiento local), no una secuencia larga de pasos que requiera coordinaciÃ³n entre mÃ¡s de dos servicios.

## Por quÃ© no 2PC (two-phase commit) ni Saga orquestada
2PC requerirÃ­a que ambas bases de datos participen en un coordinador de transacciones distribuidas, lo cual ninguna de las dos soporta de forma nativa entre Postgres y otro Postgres en instancias/esquemas separados sin tooling adicional, y ademÃ¡s acopla fuertemente la disponibilidad de ambos servicios. Una Saga orquestada serÃ­a sobre-ingenierÃ­a para un flujo de dos pasos donde el segundo paso (compensar) es local al mismo servicio que iniciÃ³ la operaciÃ³n.

## Consecuencias
- (+) El saldo del cliente nunca queda "huÃ©rfano" sin su asiento contable correspondiente: o ambos existen, o ninguno.
- (+) SoluciÃ³n simple, sin infraestructura adicional de orquestaciÃ³n de sagas.
- (-) Existe una ventana de tiempo muy breve entre el dÃ©bito/crÃ©dito original y su reverso donde el saldo estÃ¡ "incorrecto" si alguien lo consulta exactamente en ese instante (trade-off aceptado: la ventana es del orden de milisegundos, limitada por el timeout de la llamada gRPC).
- (-) Este fue precisamente el patrÃ³n cuya ausencia causÃ³ un bug real detectado durante el desarrollo (crÃ©ditos sin validar el resultado del dÃ©bito inicial en `routing-service`), corregido sincronizando el resultado del dÃ©bito antes de permitir cualquier crÃ©dito asociado.

