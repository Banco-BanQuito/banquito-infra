# ADR-002: Qué motor le toca a cada microservicio

## Estado
Aceptado

## Contexto
Que el proyecto usara tanto bases relacionales como documentales fue un requisito académico, no una decisión del equipo — pero el requisito no decía cuál motor documental usar, ni cómo repartir los 8 microservicios entre los motores. Eso sí quedó abierto: cuáles necesitaban Postgres, cuáles podían usar algo más liviano como MySQL, por qué usar dos motores relacionales distintos en vez de uno solo, y cuál motor documental usar entre las opciones disponibles.

## Por qué MongoDB y no otro motor documental
Entre los motores documentales disponibles para correr en un contenedor propio (la fase todavía era Docker Compose, no nube), MongoDB fue el que el equipo eligió por tener la imagen oficial de Docker más simple de levantar, la documentación y comunidad más grandes para resolver dudas rápido, y un lenguaje de consultas más expresivo que alternativas más simples tipo clave-valor. No se evaluó a fondo una alternativa como CouchDB porque no aportaba una ventaja concreta para el caso de uso (líneas de pago con campos variables) que justificara el tiempo de aprenderla desde cero en el plazo de esta fase.

## Decisión

| Servicio | Motor | Razón |
|---|---|---|
| account-core-service | PostgreSQL | Necesita reglas estrictas de consistencia sobre los saldos — que una transacción quede completa o no quede registrada en absoluto. |
| accounting-service | PostgreSQL | El libro mayor y los asientos de partida doble exigen el mismo nivel de consistencia que el Core; usa el mismo motor, pero en su propio espacio separado, sin compartir tablas con account-core-service. |
| party-service | MySQL | Datos maestros como clientes y sucursales, con relaciones simples; MySQL es suficiente y más liviano de operar para este caso. |
| file-reception-service | MySQL y MongoDB | MySQL para el registro general del lote (cabecera, pie, auditoría); MongoDB para el detalle de cada línea de pago, que cambia de forma según el tipo de archivo (nómina, proveedores, etc.). |
| clearinghouse-service y report-service | MongoDB | El estado de un pago en tránsito es información que cambia de forma según el caso y se escribe con mucha frecuencia — no necesita relacionar tablas entre sí, y se beneficia de que MongoDB permita escribir miles de líneas por segundo sin una estructura rígida. file-reception-service usa esta misma base para el despacho de pagos (ver ADR-008). |

## Por qué dos motores relacionales, y no uno solo para todo lo relacional
Postgres se reservó para lo que exige consistencia fuerte (saldos, contabilidad); MySQL se usó donde bastaba con algo más simple y liviano de operar (datos maestros, registros de auditoría). Usar Postgres para todo hubiera funcionado, pero no había necesidad real de pagar ese costo operativo extra en los servicios que no lo requerían. Usar solo una base documental para el Core, en cambio, sí hubiera sacrificado las garantías de consistencia que el dinero de los clientes requiere — por eso ahí no había alternativa real.

## Consecuencias
- A favor: cada servicio usa la herramienta más adecuada a su forma de acceder a los datos.
- A favor: cumple la regla de que cada servicio tenga su propia base — ningún servicio consulta directamente la base de otro.
- En contra: requiere mantener y operar tres motores de base de datos distintos en el mismo proyecto, en vez de uno solo.
- En contra: no se puede relacionar directamente información de dos servicios en una sola consulta, porque viven en bases distintas — hay que pedirle esa información al otro servicio por API o por gRPC, nunca consultando su base directamente.
