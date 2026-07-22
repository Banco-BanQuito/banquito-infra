# Architectural Decision Records — Banco BanQuito

Registro de decisiones de arquitectura del proyecto, organizado por fase. Cada carpeta corresponde a una etapa real de evolución del sistema — de un monolito dual en una VM, a microservicios sobre Docker Compose, a Kubernetes con un proveedor de identidad en la nube.

## [Fase 1 — Monolito Dual (Primer Parcial)](fase-1-monolito/README.md)
Core Bancario y Switch de Pagos como dos procesos Spring Boot independientes, desplegados en una VM con systemd, sin contenedores.

## [Fase 2 — Microservicios (Segundo Parcial)](fase-2-microservicios/README.md)
Descomposición en 8 microservicios con Database per Service, comunicación gRPC/REST/RabbitMQ, API Gateway con Kong, y despliegue con Docker Compose + Watchtower.

## [Fase 3 — Kubernetes e Identity Platform (Proyecto Final)](fase-3-kubernetes-identity/README.md)
Migración a GKE y adopción de Google Identity Platform como servicio de OAuth2 en la nube, integrado al API Manager.

---

Cada ADR sigue el formato estándar (Nygard): **Estado**, **Contexto**, **Decisión**, **Por qué X y no Y** (alternativas consideradas), y **Consecuencias**. Cuando una decisión de una fase reemplaza a una de una fase anterior, ambos ADR lo indican explícitamente en su sección de Estado, para que la evolución completa del proyecto se pueda seguir como una sola línea de tiempo.
