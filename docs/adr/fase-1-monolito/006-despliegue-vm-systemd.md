# ADR-006 (Fase 1): Despliegue en una VM con systemd, sin contenedores

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
Una sola VM en GCP (`e2-standard-2`), con cada backend corriendo como un servicio de systemd, y Nginx repartiendo el tráfico hacia cada uno.

## Contexto
Plazo de un mes para tener el sistema funcionando en la nube, sin experiencia previa del equipo en Docker ni Kubernetes, y sin que esta fase del curso pidiera todavía contenedores.

## Opciones consideradas
1. **(SELECCIONADA) VM con systemd:** cada backend como un servicio del sistema operativo, reiniciado automáticamente si falla.
2. **Docker Compose en la misma VM:** los mismos backends, pero cada uno en un contenedor.
3. **Kubernetes:** un clúster completo desde esta fase.

## Compensaciones

**Opción 1 (SELECCIONADA) — VM con systemd**
- Seleccionada porque no exigía aprender Docker al mismo tiempo que el dominio bancario y los conceptos de arquitectura distribuida — una curva de aprendizaje menos en un mes ya apretado.
- Seleccionada porque systemd ya da reinicio automático si un servicio falla, sin configuración extra.
- Con esta opción, un problema de memoria o de CPU en un servicio afecta a los demás, porque todos comparten el mismo sistema operativo sin límites entre ellos.
- Con esta opción, actualizar un servicio implica un corte breve (no hay actualización sin downtime).
- Con esta opción, las contraseñas quedaron escritas directamente en los archivos de configuración de systemd, sin ningún baúl de secretos.

**Opción 2 — Docker Compose en la misma VM**
- Rechazada por tiempo: aprender Docker en el mismo mes hubiera restado tiempo a construir la funcionalidad del Core y el Switch.

**Opción 3 — Kubernetes**
- Rechazada por ser una herramienta demasiado compleja para el alcance y el tiempo de esta fase — Kubernetes se reserva para una fase posterior del proyecto, cuando ya es un requisito explícito.
