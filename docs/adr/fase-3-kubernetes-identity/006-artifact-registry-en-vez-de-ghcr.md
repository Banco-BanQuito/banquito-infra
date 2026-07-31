# ADR-006 (Fase 3): Google Artifact Registry en vez de GHCR

**Estado:** Aceptado — reemplaza a GHCR de Fase 2
**Fecha:** Julio 2026
**Autor:** Equipo Fase 3

## Decisión
Se usa Google Artifact Registry como repositorio de imágenes Docker, reemplazando a GitHub Container Registry (GHCR), que era el que se usaba en Fase 2.

## Contexto
El proyecto final exige que la infraestructura viva dentro de Google Cloud, con autenticación entre servicios vía Workload Identity Federation, sin llaves de larga duración guardadas como secreto. GHCR, usado en Fase 2, vive fuera de Google Cloud, en GitHub — para que GKE pudiera descargar imágenes de un registro externo, necesitaría su propia credencial guardada como secreto, justo lo que esta fase busca eliminar.

## Opciones consideradas
1. **(SELECCIONADA) Google Artifact Registry.**
2. **Seguir con GHCR.**
3. **Docker Hub.**

## Compensaciones

**Opción 1 (SELECCIONADA) — Artifact Registry**
- Seleccionada porque el nodo de GKE puede leer imágenes de Artifact Registry usando el mismo Service Account del proyecto, sin ninguna credencial adicional — coherente con el resto de la fase (Workload Identity Federation en GitHub Actions, sin llaves guardadas).
- Seleccionada porque GitHub Actions ya se autentica a Google Cloud con Workload Identity Federation para hacer el despliegue (`kubectl set image`); desde ahí también puede subir la imagen a Artifact Registry, sin necesitar un segundo tipo de credencial solo para el registro de imágenes.
- Con esta opción, el proyecto ya no depende de GitHub para servir las imágenes en producción — si GitHub tuviera una caída, GKE seguiría pudiendo desplegar imágenes que ya están en Artifact Registry.

**Opción 2 — Seguir con GHCR**
- Rechazada porque hubiera exigido guardar un token de GitHub como secreto de Kubernetes para que GKE se autenticara contra un registro externo — exactamente el tipo de credencial de larga duración que esta fase busca eliminar.

**Opción 3 — Docker Hub**
- Rechazada por la misma razón que GHCR: es un registro externo a Google Cloud, sin integración nativa de identidad con GKE.
