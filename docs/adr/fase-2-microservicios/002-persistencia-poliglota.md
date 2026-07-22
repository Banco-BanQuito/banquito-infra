# ADR-002: Persistencia políglota: PostgreSQL, MySQL y MongoDB

## Estado
Aceptado

## Contexto
El requisito académico exige usar tanto bases relacionales como documentales, eligiendo la tecnología según la naturaleza de los datos de cada microservicio (no como elección arbitraria por servicio).

## Decisión

| Servicio | Motor | Razón |
|---|---|---|
| `account-core-service` | PostgreSQL | Necesita integridad referencial fuerte, transacciones ACID estrictas sobre saldos, y soporta particionamiento declarativo nativo para separar data caliente/fría (ver ADR-006). |
| `accounting-service` | PostgreSQL | El libro mayor y los asientos de partida doble exigen consistencia transaccional al mismo nivel que el Core; comparte el mismo motor para mantener semántica SQL consistente, en un esquema separado (`accounting`), nunca compartiendo tablas con `account_core`. |
| `party-service` | MySQL | Datos maestros (clientes, sucursales) con relaciones simples, sin necesidad de particionamiento; MySQL es suficiente y más liviano de operar. |
| `file-reception-service` | MySQL + MongoDB | MySQL para el registro estructurado del lote (cabecera/pie, auditoría); MongoDB para el detalle de líneas de pago, que es un documento variable según el tipo de servicio (nómina, proveedores, etc.). |
| `clearinghouse-service`, `report-service` | MongoDB | El estado de un pago en tránsito (CompensationFile, PaymentBatch, PaymentDetail) es un documento semi-estructurado de alto volumen y escritura intensiva; no requiere joins relacionales y se beneficia de la escritura flexible de Mongo bajo carga de miles de líneas por segundo. `file-reception-service` usa esta misma colección de Mongo para el despacho de pagos (ver ADR-011). |

## Por qué no una sola base para todo
Usar un único motor (ej. solo Postgres) forzaría a tratar los documentos de pagos masivos (con campos opcionales y de alto volumen transitorio) como filas relacionales rígidas, complicando el esquema sin necesidad. Usar solo Mongo para el Core sacrificaría las garantías ACID que el dinero de los clientes requiere.

## Consecuencias
- (+) Cada servicio usa la herramienta más adecuada a su patrón de acceso.
- (+) Cumple "Database per Service": ningún servicio consulta directamente la base de otro.
- (-) Requiere mantener habilidades/operación de 2 motores SQL + 1 NoSQL en el mismo proyecto.
- (-) No hay JOIN nativo entre datos de distintos servicios (ej. `account.customer_id` vs `customer.id` en bases distintas) — se resuelve por API/gRPC, nunca por consulta directa cross-DB.
