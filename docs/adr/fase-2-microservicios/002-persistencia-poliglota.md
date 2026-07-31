# ADR-002: Persistencia políglota: PostgreSQL, MySQL y MongoDB

## Estado
Aceptado

## Contexto
El requisito académico exige usar tanto bases relacionales como documentales, eligiendo la tecnología según la naturaleza de los datos de cada microservicio (no como elección arbitraria por servicio).

## Decisión

| Servicio | Motor | Razón |
|---|---|---|
| account-core-service | PostgreSQL | Necesita reglas estrictas de consistencia sobre los saldos — que una transacción quede completa o no quede registrada en absoluto. |
| accounting-service | PostgreSQL | El libro mayor y los asientos de partida doble exigen el mismo nivel de consistencia que el Core; usa el mismo motor, pero en su propio espacio separado, sin compartir tablas con account-core-service. |
| party-service | MySQL | Datos maestros como clientes y sucursales, con relaciones simples; MySQL es suficiente y más liviano de operar para este caso. |
| file-reception-service | MySQL y MongoDB | MySQL para el registro general del lote (cabecera, pie, auditoría); MongoDB para el detalle de cada línea de pago, que cambia de forma según el tipo de archivo (nómina, proveedores, etc.). |
| clearinghouse-service y report-service | MongoDB | El estado de un pago en tránsito es información que cambia de forma según el caso y se escribe con mucha frecuencia — no necesita relacionar tablas entre sí, y se beneficia de que MongoDB permita escribir miles de líneas por segundo sin una estructura rígida. file-reception-service usa esta misma base para el despacho de pagos (ver ADR-008). |

## Por qué no una sola base para todo
Usar un único motor relacional para todo forzaría a tratar los datos de pagos masivos, que cambian de forma según el caso y se generan en volúmenes altos y pasajeros, como si fueran filas rígidas de una tabla, complicando el esquema sin necesidad. Usar solo una base documental para el Core sacrificaría las garantías de consistencia que el dinero de los clientes requiere.

## Consecuencias
- A favor: cada servicio usa la herramienta más adecuada a su forma de acceder a los datos.
- A favor: cumple la regla de que cada servicio tenga su propia base — ningún servicio consulta directamente la base de otro.
- En contra: requiere mantener y operar tres motores de base de datos distintos en el mismo proyecto, en vez de uno solo.
- En contra: no se puede relacionar directamente información de dos servicios en una sola consulta, porque viven en bases distintas — hay que pedirle esa información al otro servicio por API o por gRPC, nunca consultando su base directamente.
