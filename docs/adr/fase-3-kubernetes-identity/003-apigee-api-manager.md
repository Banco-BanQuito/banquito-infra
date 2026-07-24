# ADR-003 (Fase 3): Apigee como API Manager de la entrega final

**Estado:** En progreso — reemplaza a Kong (ADR-005 de Fase 2) como API Manager final
**Fecha:** Julio 2026
**Autor:** Equipo Fase 3

## Decisión
Se usa Apigee como API Manager de la entrega final. Apigee valida el token de Identity Platform con una política de verificación de token que trae integrada, comparando la firma contra las llaves públicas de Identity Platform, sin necesitar preguntarle a Identity Platform en cada llamada.

## Contexto
El proyecto final pide que el API Manager sea un servicio de la nube, que se integre con OAuth2, y que cada aplicación cliente tenga su propia API Key. Kong (usado en la Fase 2) es open source y corre en un contenedor propio — no cumple el requisito de "servicio de nube" para esta entrega final.

## Opciones consideradas
1. **(SELECCIONADA) Apigee:** API Manager administrado por Google Cloud.
2. **Seguir con Kong, ahora en modo administrado (Kong Konnect):** la versión de Kong que sí es un servicio de nube.
3. **WSO2 API Manager en la nube.**

## Compensaciones

**Opción 1 (SELECCIONADA) — Apigee**
- Seleccionada porque es el servicio de API Manager de Google Cloud, y el resto del proyecto ya está construido sobre GCP (Identity Platform, GKE, Cloud SQL) — usar Apigee evita sumar un proveedor más a la mezcla.
- Se comprobó en vivo que la validación del token funciona: la política de Apigee revisa la firma, quién lo emitió, y para quién es válido, todo contra las llaves públicas de Identity Platform, sin llamar a Identity Platform en cada petición.
- **Restricción técnica real encontrada:** al crear la organización de Apigee, borrarla y querer crear otra en el mismo proyecto de GCP, Google bloquea volver a crear una por 30 días. Esto obligó a que Apigee terminara en un proyecto de GCP separado del resto del sistema — no fue una decisión de diseño inicial, sino algo que se convirtió en un patrón defendible después: separar la puerta de entrada (Apigee) del resto de los servicios internos.
- Se encontraron y quedan documentados 2 errores reales de configuración durante la integración: una variable interna que no se resuelve bien antes de validar el token, y la falta del header de API Key que Apigee empezó a exigir sin que los equipos de frontend lo supieran todavía.
- Requiere, además de validar el token (OAuth2), que cada aplicación tenga su propia API Key registrada dentro de Apigee — esto es un mecanismo aparte de Identity Platform, exigido también por el enunciado del proyecto.

**Opción 2 — Kong Konnect**
- No se llegó a evaluar a fondo en esta fase porque Apigee ya cumplía el requisito y el equipo responsable de esta parte ya tenía experiencia configurando Kong en la Fase 2, facilitando la transición.

**Opción 3 — WSO2 API Manager en la nube**
- Rechazada por ser una herramienta más pesada de operar (necesita su propia base de datos y un servidor adicional) para el alcance de este proyecto.
