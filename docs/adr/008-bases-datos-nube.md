# ADR-008: Bases de datos como servicio en la nube (DBaaS)

## Estado
Aceptado

## Contexto
El enunciado exige que la base de datos de producción esté contratada como servicio en la nube, no auto-hospedada en la misma VM que corre la aplicación.

## Decisión
- **PostgreSQL** (`account-core-service`, `accounting-service`): **Cloud SQL** (Google Cloud), una sola instancia con dos esquemas separados (`account_core`, `accounting`) para mantener "Database per Service" a nivel lógico sin pagar por dos instancias físicas completas.
- **MySQL** (`party-service`, `file-reception-service`, `tariff-service`): **Cloud SQL** (Google Cloud), una sola instancia con bases lógicas separadas (`partydb`, `filedb`, `tariffdb`).
- **MongoDB** (`clearinghouse-service`, `report-service`, `file-reception-service`): **MongoDB Atlas**, con colecciones separadas por servicio dentro de la misma base `banquito`.
- **RabbitMQ**: actualmente corre como contenedor Docker en la misma VM de aplicación (limitación conocida, no migrado a un proveedor gestionado como CloudAMQP por decisión de alcance de este parcial).

## Por qué instancias compartidas con esquemas/bases lógicas separadas, en vez de una instancia física por servicio
Una instancia Cloud SQL o un cluster Atlas dedicado por cada uno de los 9 microservicios excedería el presupuesto y la cuota de un proyecto académico. Se prioriza el aislamiento **lógico** (esquema/base/colección propia, sin tablas compartidas, sin acceso cruzado en el código) sobre el aislamiento físico total, manteniendo la regla de "ningún servicio lee la base de otro directamente".

## Consecuencias
- (+) Las bases de datos relacionales y documentales sobreviven independientemente del ciclo de vida de la VM de aplicación; un reinicio o recreación de la VM no afecta los datos.
- (+) Cumple el requisito de "BD de producción en la nube" para Postgres, MySQL y MongoDB.
- (-) RabbitMQ sigue siendo un punto único de falla atado a la VM — si la VM se reinicia, el broker se reinicia con ella (mitigado por el volumen persistente de RabbitMQ y `restart: unless-stopped`).
- (-) Compartir instancia física entre dos esquemas (Postgres) significa que ambos compiten por el mismo límite de conexiones — mitigado fijando un pool pequeño por servicio (ver bloque de pruebas de carga, donde se identificó esto como cuello de botella bajo concurrencia alta).
