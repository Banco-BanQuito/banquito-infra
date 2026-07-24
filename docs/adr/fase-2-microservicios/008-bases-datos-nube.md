# ADR-008: Bases de datos administradas por un proveedor de nube

## Estado
Aceptado

## Contexto
El enunciado exige que la base de datos de producción esté contratada como servicio en la nube, no auto-hospedada en la misma VM que corre la aplicación.

## Decisión
- PostgreSQL (account-core-service, accounting-service): Cloud SQL de Google Cloud, una sola instancia con dos espacios separados dentro de ella, para mantener cada servicio con su propia base a nivel lógico sin pagar por dos instancias físicas completas.
- MySQL (party-service, file-reception-service, tariff-service): Cloud SQL de Google Cloud también, una sola instancia con tres bases lógicas separadas, una por servicio.
- MongoDB (clearinghouse-service, report-service, file-reception-service): MongoDB Atlas, con colecciones separadas por servicio dentro de la misma base.
- RabbitMQ: por ahora sigue corriendo como un contenedor en la misma máquina virtual de la aplicación — es una limitación conocida, no se migró todavía a un proveedor administrado por decisión de alcance de este parcial.

## Por qué instancias compartidas con espacios lógicos separados, en vez de una instancia física por servicio
Tener una instancia dedicada por cada uno de los 9 microservicios excedería el presupuesto y la cuota disponible para un proyecto académico. Se prioriza que cada servicio tenga su propio espacio lógico — sin tablas compartidas, sin acceso cruzado en el código — por encima de tener una instancia física completa para cada uno, manteniendo siempre la regla de que ningún servicio lee la base de otro directamente.

## Consecuencias
- A favor: las bases de datos sobreviven de forma independiente al ciclo de vida de la máquina virtual de la aplicación — un reinicio o recreación de la VM no afecta los datos.
- A favor: cumple el requisito de tener la base de datos de producción en la nube, tanto para las relacionales como para la documental.
- En contra: RabbitMQ sigue siendo un punto único de falla atado a la VM — si la VM se reinicia, el broker se reinicia con ella, aunque esto se mitiga guardando sus datos en un volumen que sí persiste.
- En contra: compartir una instancia física entre dos espacios lógicos (en Postgres) significa que ambos compiten por el mismo límite de conexiones simultáneas — se mitigó limitando cuántas conexiones puede abrir cada servicio a la vez, después de identificar esto como un cuello de botella en pruebas de carga con mucha concurrencia.
