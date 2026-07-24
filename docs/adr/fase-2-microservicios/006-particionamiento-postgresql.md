# ADR-006: Particionamiento declarativo de transacciones en PostgreSQL

## Estado
Aceptado

## Contexto
La tabla de transacciones de cuenta es la que más crece de todo el sistema — cada depósito, retiro, transferencia o pago le agrega una fila. Sin una estrategia para organizar ese crecimiento, las consultas normales (por ejemplo, ver los movimientos recientes en banca web) se vuelven cada vez más lentas a medida que crece el histórico, y el documento de requisitos del Core exige explícitamente separar los datos recientes de los datos antiguos.

## Decisión
La tabla de transacciones se divide físicamente por mes: cada mes tiene su propia partición dentro de la base de datos, y existe una partición adicional que recibe cualquier fecha fuera de lo esperado.

## Por qué dividir por fecha y no por otro criterio
La forma más común de consultar esta tabla es "dame los movimientos de los últimos meses de esta cuenta", así que dividir por fecha permite que la base de datos descarte de entrada las particiones que no le sirven para esa consulta, en vez de revisar todo el histórico completo. Dividir por número de cuenta, en cambio, no ayudaría a este tipo de consulta y complicaría separar lo antiguo de lo reciente.

## Consecuencias
- A favor: las consultas de movimientos recientes solo tocan una o dos particiones — la del mes actual y la del anterior — en vez de toda la tabla.
- A favor: permite mover después los datos antiguos a un almacenamiento más barato sin tocar la tabla completa ni el código de la aplicación.
- En contra: la forma en que se identifica cada fila de manera única tiene que incluir también la fecha, no solo el identificador — así que cualquier actualización o borrado por identificador necesita también saber la fecha, o resolverse de otra forma.
- En contra: requiere una tarea de mantenimiento, manual o programada, para crear con anticipación la partición del mes siguiente.
