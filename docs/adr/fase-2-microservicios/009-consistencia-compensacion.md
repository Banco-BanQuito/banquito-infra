# ADR-009: Consistencia entre microservicios vía transacción compensatoria

## Estado
Aceptado

## Contexto
account-core-service afecta el saldo del cliente y luego debe pedirle a accounting-service que genere el asiento contable correspondiente, esperando su respuesta. Al ser dos bases de datos distintas, no existe una sola transacción que abarque a las dos a la vez: el Core puede tener éxito y la contabilidad puede fallar, por ejemplo si accounting-service la rechaza o si la llamada entre los dos se cae.

## Decisión
Si la llamada a accounting-service falla o es rechazada, account-core-service ejecuta de inmediato un movimiento contrario dentro de su propia base de datos, para anular el movimiento del cliente, en lugar de dejar el saldo afectado sin su registro contable correspondiente.

No se implementó un patrón formal de coordinación entre varios pasos (conocido como Saga) porque el flujo es de un solo paso de compensación — revertir el movimiento local — no una secuencia larga que necesite coordinar más de dos servicios.

## Por qué no una transacción distribuida real, ni una Saga con orquestador
Una transacción distribuida real exigiría que las dos bases de datos participen en un mismo coordinador central, algo que ninguna de las dos soporta de forma nativa entre instancias separadas sin herramientas adicionales, y que además ataría la disponibilidad de un servicio a la del otro. Un orquestador de Saga sería una solución más compleja de lo necesario para un flujo de solo dos pasos, donde el segundo paso (compensar) ocurre dentro del mismo servicio que inició la operación.

## Consecuencias
- A favor: el saldo del cliente nunca queda sin su asiento contable correspondiente — o existen los dos, o no existe ninguno.
- A favor: es una solución simple, sin necesitar infraestructura adicional para coordinar pasos.
- En contra: existe una ventana de tiempo muy breve, del orden de milisegundos, entre el movimiento original y su reverso, donde el saldo se vería incorrecto si alguien lo consultara justo en ese instante — un riesgo aceptado por lo corta que es esa ventana.
- En contra: la falta de este mismo control fue justo la causa de un error real detectado durante el desarrollo — créditos que no validaban el resultado del débito inicial — corregido asegurando que el resultado del débito se confirme antes de permitir cualquier crédito asociado.
