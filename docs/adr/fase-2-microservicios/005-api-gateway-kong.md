# ADR-005: API Gateway con Kong

## Estado
Aceptado

## Contexto
El enunciado exige una solución propia de API Management (no la de un proveedor cloud) para centralizar el tráfico hacia los microservicios, en lugar de exponer cada servicio directamente a los frontends.

## Decisión
Se usan **dos instancias de Kong** en modo declarativo (`KONG_DATABASE: off`), una por dominio:
- **Kong Core** (puerto 8000): enruta a `account-core-service`, `accounting-service`, `party-service`.
- **Kong Switch** (puerto 8010): enruta a `file-reception-service`, `report-service`, `account-core-service`, `clearinghouse-service`.

Cada Kong tiene plugins de `cors` y `rate-limiting` configurados. La autenticación vía JWT está diferida al 3er parcial según el enunciado de esta fase; por eso no hay un plugin `jwt` activo en ninguna ruta todavía.

## Por qué Kong y no WSO2
Kong fue elegido por su modelo de configuración declarativa (un solo YAML versionable en el repositorio, sin necesidad de una base de datos de administración para este alcance), y por tener un ecosistema de plugins maduro para rate limiting y CORS sin desarrollo adicional. WSO2 API Manager es más pesado de operar (requiere su propia base de datos y un Carbon Server) para el alcance de este parcial.

## Por qué dos instancias y no una sola
Separar Kong Core de Kong Switch refuerza la misma frontera de Bounded Context del ADR-001: cada API Gateway solo conoce las rutas de su dominio, evitando que una mala configuración en las reglas del Switch afecte accidentalmente al tráfico del Core.

## Consecuencias
- (+) Configuración versionada como código (`kong.yml` por instancia).
- (+) Rate limiting y CORS centralizados, sin repetir esa lógica en cada microservicio.
- (-) El modo declarativo actual no separa Control Plane y Data Plane (Kong Hybrid mode); cada instancia es a la vez su propio plano de control y de datos — limitación documentada y aceptada para el alcance de este parcial.
