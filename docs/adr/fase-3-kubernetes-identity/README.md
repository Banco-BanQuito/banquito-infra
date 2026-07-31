# ADR — Fase 3: Kubernetes, Identity Platform, API Manager y Broker (Proyecto Final)

Decisiones de arquitectura de la fase final: migración del despliegue a Kubernetes (GKE), OAuth2 como servicio de nube (Identity Platform), Apigee como API Manager, Secret Manager como baúl de secretos, Pub/Sub como broker de mensajes, Artifact Registry como repositorio de imágenes, Gateway API como entrada al clúster, y HPA para el autoescalamiento.

| ADR | Título |
|---|---|
| [001](001-identity-platform-oauth2.md) | Google Identity Platform como OAuth2 en la nube |
| [002](002-migracion-vm-a-gke.md) | Migración de Docker Compose a Kubernetes (GKE) |
| [003](003-apigee-api-manager.md) | Apigee como API Manager de la entrega final |
| [004](004-secret-manager-baul-secretos.md) | Google Secret Manager como baúl de secretos |
| [005](005-pubsub-broker-mensajes.md) | Google Cloud Pub/Sub como broker de mensajes |
| [006](006-artifact-registry-en-vez-de-ghcr.md) | Google Artifact Registry en vez de GHCR |
| [007](007-gateway-api-en-vez-de-ingress.md) | Gateway API de GKE en vez de Ingress tradicional |
| [008](008-autoescalamiento-horizontal-hpa.md) | Autoescalamiento horizontal (HPA) uniforme, con escalado asimétrico |

Todas las decisiones de esta fase son de elección libre del equipo: ninguno de los documentos de requisitos de Core o Switch (que llegan hasta la V2) menciona Kubernetes, un proveedor de identidad, un API Manager, un baúl de secretos, ni un broker administrado — el enunciado del proyecto final solo pide que estas piezas existan como servicios de la nube, sin indicar cuáles usar. Los ADR-006, 007 y 008 se agregaron después de revisar los manifiestos reales del clúster (`k8s/`) que no estaban documentados todavía.
