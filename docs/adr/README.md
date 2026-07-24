# Architectural Decision Records — Banco BanQuito

Registro de decisiones de arquitectura del proyecto, organizado por fase. Cada carpeta es una etapa real de la evolución del sistema — de un monolito dual en una VM, a microservicios sobre Docker Compose, a Kubernetes con un proveedor de identidad y un API Manager en la nube.

## [Fase 1 — Monolito Dual (Primer Parcial)](fase-1-monolito/README.md)
Core Bancario y Switch de Pagos como dos procesos Spring Boot separados, en una VM con systemd, sin contenedores.

## [Fase 2 — Microservicios (Segundo Parcial)](fase-2-microservicios/README.md)
División en 8 microservicios, cada uno con su propia base de datos, comunicación por gRPC/REST/RabbitMQ, API Gateway con Kong, despliegue con Docker Compose + Watchtower.

## [Fase 3 — Kubernetes, Identity Platform, API Manager y Broker (Proyecto Final)](fase-3-kubernetes-identity/README.md)
Migración a GKE, Identity Platform como OAuth2 en la nube, Apigee como API Manager, Secret Manager como baúl de secretos, y Pub/Sub como broker de mensajes en la nube.

---

Cada ADR sigue este formato: **Estado, Fecha y Autor** (arriba), **Decisión** (qué se eligió, en pocas palabras), **Contexto** (por qué había que decidir esto), **Opciones consideradas** (todas las alternativas, no solo la elegida), y **Compensaciones** (por qué se eligió esa opción y por qué se descartaron las demás). Cuando una decisión de una fase reemplaza a otra de una fase anterior, ambos ADR lo dicen explícitamente en su Estado, para poder seguir la evolución completa del proyecto como una sola línea de tiempo.
