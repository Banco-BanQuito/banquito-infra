# ADR-005 (Fase 3): Google Cloud Pub/Sub como broker de mensajes

**Estado:** Aceptado — reemplaza a RabbitMQ (ADR-004 de Fase 2) como broker de mensajes
**Fecha:** Julio 2026
**Autor:** Equipo Fase 3

## Decisión
Se reemplaza RabbitMQ por Google Cloud Pub/Sub como broker de mensajes del sistema.

## Contexto
El proyecto final pide que el broker de mensajes sea un servicio de la nube, administrado por el proveedor, no instalado por el equipo. RabbitMQ, tal como se usaba en la Fase 2, corría en un contenedor propio dentro de Docker Compose — no cumple ese requisito para esta entrega final.

## Opciones consideradas
1. **(SELECCIONADA) Google Cloud Pub/Sub:** servicio de mensajería completamente administrado por Google Cloud.
2. **RabbitMQ administrado por un proveedor externo (por ejemplo CloudAMQP):** el mismo RabbitMQ de antes, pero como servicio de nube en vez de instalado por el equipo.
3. **Seguir con RabbitMQ propio, ahora dentro de un Pod de GKE.**

## Compensaciones

**Opción 1 (SELECCIONADA) — Google Cloud Pub/Sub**
- Seleccionada porque es un servicio totalmente administrado por Google Cloud — no hay que instalar, actualizar, ni vigilar la salud de un broker propio, algo que en la Fase 2 sí exigió ajustar manualmente (por ejemplo, cuánto tiempo esperar antes de considerar que RabbitMQ ya está listo para recibir tráfico).
- Seleccionada porque se integra de forma nativa con el resto del proyecto, que ya vive en Google Cloud (GKE, Cloud SQL, Identity Platform, Secret Manager).
- **Cambio real de modelo, no solo de proveedor:** RabbitMQ enrutaba cada línea de pago a su cola exacta (dentro del banco, hacia otro banco, o inválida) según una etiqueta que se le asignaba al publicarla. Pub/Sub no funciona igual — el filtrado se hace con atributos del mensaje y con filtros configurados en cada suscripción, un modelo distinto que hubo que adaptar.
- Con esta opción, la entrega de mensajes es "al menos una vez" — un mensaje puede llegar duplicado en algunos casos. Esto hace todavía más importante el control de duplicados que ya existía por el identificador único de cada transacción (ver ADR-010 de Fase 2), que ahora es la última línea de defensa contra un pago duplicado.

**Opción 2 — RabbitMQ administrado por un proveedor externo**
- No se eligió porque suma un proveedor externo más al proyecto, cuando Google Cloud ya ofrece un servicio de mensajería propio que cumple el mismo requisito sin salir del mismo ecosistema.

**Opción 3 — RabbitMQ propio dentro de GKE**
- Rechazada porque, aunque correría dentro de Kubernetes, seguiría siendo un broker instalado y mantenido por el equipo, no un servicio provisto por la nube — no cumple el requisito de esta fase.
