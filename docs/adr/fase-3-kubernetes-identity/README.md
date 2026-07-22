# ADR — Fase 3: Kubernetes e Identity Platform (Proyecto Final)

Decisiones de arquitectura de la fase final: migración del despliegue a Kubernetes (GKE) y la introducción de OAuth2 como servicio de nube (Identity Platform), integrado al API Manager.

| ADR | Título |
|---|---|
| [001](001-identity-platform-oauth2.md) | Google Identity Platform como servicio de OAuth2/OIDC en la nube |
| [002](002-migracion-vm-a-gke.md) | Migración de despliegue — Docker Compose + Watchtower → Google Kubernetes Engine |

Esta fase está en progreso. Otras decisiones de esta fase (API Manager como Apigee, Secret Manager, orquestación final en GKE de todos los servicios) las documentan los compañeros responsables de esas áreas.
