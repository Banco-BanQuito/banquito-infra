# ADR-002 (Fase 3): Migración de Docker Compose a Kubernetes (GKE)

**Estado:** En progreso — reemplaza al ADR-007 de Fase 2
**Fecha:** Julio 2026
**Autor:** Equipo Fase 3

## Decisión
El sistema se despliega en GKE (Kubernetes de Google Cloud). Cada repositorio actualiza su servicio con `kubectl set image` desde GitHub Actions, autenticado con Workload Identity Federation, sin llaves guardadas como secreto.

## Contexto
El proyecto final pide un orquestador de contenedores real, provisto por la nube. Docker Compose sobre una sola VM funcionó bien en fases anteriores, pero no es un orquestador real: no reinicia servicios solo si falla un nodo, no escala automáticamente, no actualiza sin cortar el servicio.

## Opciones consideradas
1. **(SELECCIONADA) Google Kubernetes Engine (GKE):** Kubernetes administrado por Google.
2. **Docker Swarm:** un orquestador más simple que Kubernetes.
3. **Seguir con Docker Compose + Watchtower.**

## Compensaciones

**Opción 1 (SELECCIONADA) — GKE**
- Seleccionada porque Kubernetes es el estándar de la industria y del curso, y GKE conecta de forma nativa con el resto de servicios de Google Cloud que ya usa el proyecto (Cloud SQL, Secret Manager, Identity Platform).
- Se usa Workload Identity Federation en vez de una llave de cuenta de servicio guardada como secreto — así no hay ninguna credencial de larga duración que se pueda filtrar.
- Con esta opción, las actualizaciones ya no cortan el servicio de golpe: los contenedores viejos se retiran poco a poco mientras los nuevos pasan su revisión de salud.
- Lección real encontrada en el camino: mientras el sistema corría con Docker Compose + Watchtower, un cambio a la rama principal apagaba y volvía a levantar todo el sistema de inmediato, sin poder cancelarlo a mitad de camino una vez empezado — esto ya no pasa en GKE.
- Migración todavía en curso: no todos los servicios están en GKE todavía, y al pasar los frontends hubo que corregir que no estaban recibiendo sus variables de entorno reales en el momento de construir la imagen.
- Los secretos que antes se leían como variable de entorno simple ahora necesitan, para hacerse bien (sin copiar el valor a mano en ningún lado), configurar el mecanismo de Kubernetes que los trae directo de Secret Manager (ver ADR-004 de esta fase) — más trabajo de configuración inicial que en fases anteriores, pero más correcto.

**Opción 2 — Docker Swarm**
- Rechazada porque, aunque es más simple de operar, tiene mucho menos uso en la industria y menos herramientas disponibles (observabilidad, manejo de secretos, políticas de red) comparado con Kubernetes.

**Opción 3 — Seguir con Docker Compose + Watchtower**
- Rechazada porque no cumple el requisito explícito de esta fase de tener un orquestador de contenedores real.
