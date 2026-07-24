# ADR — Fase 3: Kubernetes, Identity Platform y API Manager (Proyecto Final)

Decisiones de arquitectura de la fase final: migración del despliegue a Kubernetes (GKE), OAuth2 como servicio de nube (Identity Platform), Apigee como API Manager, y Secret Manager como baúl de secretos.

| ADR | Título |
|---|---|
| [001](001-identity-platform-oauth2.md) | Google Identity Platform como OAuth2 en la nube |
| [002](002-migracion-vm-a-gke.md) | Migración de Docker Compose a Kubernetes (GKE) |
| [003](003-apigee-api-manager.md) | Apigee como API Manager de la entrega final |
| [004](004-secret-manager-baul-secretos.md) | Google Secret Manager como baúl de secretos |

Esta fase está en progreso. Todavía falta documentar la decisión del broker de mensajes para esta fase (si sigue siendo RabbitMQ o pasa a un servicio administrado por la nube).
