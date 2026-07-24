# ADR-004 (Fase 3): Google Secret Manager como baúl de secretos

**Estado:** Aceptado
**Fecha:** Julio 2026
**Autor:** Equipo Fase 3

## Decisión
Todas las contraseñas y llaves del proyecto (base de datos, RabbitMQ, Identity Platform, etc.) se guardan en Google Secret Manager, con un nombre por secreto que indica de qué parte del sistema es. Los servicios que los necesitan (por ejemplo, GitHub Actions al construir una imagen, o un Pod en Kubernetes) van a buscarlos ahí directamente, en vez de tener el valor copiado en otro lugar.

## Contexto
El proyecto final pide que toda contraseña y variable de entorno esté guardada en un baúl de secretos administrado por la nube, no escrita directamente en archivos de configuración como pasaba en la Fase 1 y parte de la Fase 2.

## Opciones consideradas
1. **(SELECCIONADA) Google Secret Manager, consultado directamente por quien lo necesita:** un solo lugar con la verdad; cada consumidor (GitHub Actions, GKE) lo consulta al momento de usarlo.
2. **Copiar los valores a Secrets de GitHub y Secrets de Kubernetes por separado:** duplicar cada valor en cada lugar donde se necesite.
3. **Seguir con variables de entorno escritas directamente en archivos de configuración**, como en fases anteriores.

## Compensaciones

**Opción 1 (SELECCIONADA) — Secret Manager como única fuente**
- Seleccionada porque hay un solo lugar donde vive cada secreto — si alguien lo cambia, todos los que lo consultan ven el valor nuevo, sin tener que actualizarlo en varios lugares.
- Cada secreto tiene un prefijo según de qué parte del sistema es (por ejemplo, `identity-platform-`), para que no se choquen los nombres entre los secretos de distintos compañeros del equipo.
- Con esta opción, hace falta configurar el acceso correctamente: quien consulta un secreto (por ejemplo, un Pod en GKE) necesita permiso explícito para leer justo ese secreto, ni más ni menos.
- Se identificó y se corrigió una tentación real de copiar un valor a mano en un Secret de Kubernetes en vez de consultarlo — esa opción es más rápida pero rompe la idea de "un solo lugar con la verdad", y además los Secrets nativos de Kubernetes solo están codificados (no cifrados de verdad) por defecto.

**Opción 2 — Copiar los valores a cada lugar donde se necesiten**
- Rechazada porque crea varias copias del mismo secreto: si se cambia uno, hay que acordarse de cambiar los demás a mano, y es fácil que se desactualicen sin que nadie lo note.

**Opción 3 — Variables de entorno escritas directamente en archivos**
- Rechazada porque no cumple el requisito explícito de esta fase, y es exactamente el problema que ya se identificó en la Fase 1 (contraseñas en texto plano en los archivos de configuración).
