# ADR-007 (Fase 3): Gateway API de GKE en vez de Ingress tradicional

**Estado:** Aceptado
**Fecha:** Julio 2026
**Autor:** Equipo Fase 3

## Decisión
Se usa el recurso Gateway (Gateway API de Kubernetes, clase `gke-l7-global-external-managed`) como punto de entrada externo del clúster, con un HTTPRoute por dominio, en vez del recurso Ingress tradicional de Kubernetes.

## Contexto
GKE necesita un mecanismo para exponer los servicios internos a Apigee desde fuera del clúster, enrutando por ruta hacia el Service correcto de cada microservicio, en tres dominios (Core, Switch, Frontend) que deben poder cambiar sus reglas sin afectarse entre sí.

## Opciones consideradas
1. **(SELECCIONADA) Gateway API (un Gateway compartido + un HTTPRoute por dominio).**
2. **Ingress tradicional de Kubernetes (`kind: Ingress`).**

## Compensaciones

**Opción 1 (SELECCIONADA) — Gateway API**
- Seleccionada porque separa el Gateway compartido (una sola IP externa, un solo certificado) de las reglas de ruteo de cada dominio (HTTPRoute) — cada namespace (banquito-core, banquito-switch, banquito-frontend) declara sus propias rutas sin tocar la configuración de los otros dominios.
- Seleccionada porque enrutar varias rutas por prefijo hacia distintos servicios dentro de un mismo HTTPRoute es más directo que lograr lo mismo con las anotaciones específicas del proveedor que exige Ingress.
- Con esta opción, el Gateway vive en su propio namespace (banquito-gateway), separado de los namespaces de dominio — refuerza la misma idea de aislamiento que ya se usaba con Kong Core y Kong Switch en Fase 2.

**Opción 2 — Ingress tradicional**
- Rechazada porque un solo recurso Ingress mezcla en el mismo lugar la administración del punto de entrada compartido con las reglas de cada dominio, apoyándose en anotaciones específicas del proveedor en vez de campos estándar de la API.
