# 0018. Kong como API Gateway de desarrollo, Apigee como API Manager de entrega final

## Estado
Aceptado

## Contexto
El requisito del proyecto exige que el API Manager sea un servicio provisto por la nube, con integración a OAuth2 y API Key por aplicación.

## Decisión
Dos etapas: **Kong OSS** (modo declarativo/DB-less), corriendo en contenedor junto al resto del stack, para iterar rápido durante el desarrollo diario sin depender de un servicio cloud. **Apigee** como API Manager de la entrega final — cumple explícitamente el requisito de "servicio de nube".

## Alternativas consideradas
- Exponer los microservicios directamente sin gateway — descartado, no cumple el requisito y acopla a cada frontend con las URLs internas de cada microservicio.

## Consecuencias
- Apigee, al aprovisionarse, queda atado permanentemente a un proyecto de GCP — restricción técnica real que forzó que Apigee viva en un proyecto de GCP separado del resto del workload (GKE, Cloud SQL, Identity Platform, Secret Manager comparten un mismo proyecto).
- Esta separación, aunque originada por una restricción técnica, se defiende como un patrón arquitectónico válido: separación entre capa "edge" (gateway) y capa "workload" (todo lo demás).
