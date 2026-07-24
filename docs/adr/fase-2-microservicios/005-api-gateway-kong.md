# ADR-005: API Gateway con Kong

## Estado
Aceptado

## Contexto
El enunciado exige una solución propia de API Management (no la de un proveedor cloud) para centralizar el tráfico hacia los microservicios, en lugar de exponer cada servicio directamente a los frontends.

## Decisión
Se usan dos instancias de Kong, configuradas por archivo en vez de por base de datos, una por dominio:
- Kong Core (puerto 8000): enruta a account-core-service, accounting-service, party-service.
- Kong Switch (puerto 8010): enruta a file-reception-service, report-service, account-core-service, clearinghouse-service.

Cada Kong tiene activado el control de quién puede llamar desde el navegador y un límite de peticiones por minuto. La autenticación con token queda para el proyecto final según el enunciado de esta fase; por eso todavía no hay ningún control de token activo en ninguna ruta.

## Por qué Kong y no WSO2
Kong fue elegido porque toda su configuración se puede guardar en un solo archivo versionado en el repositorio, sin necesitar una base de datos aparte para administrarlo, y porque ya trae listas las funciones de límite de peticiones y control de origen que necesitábamos, sin desarrollo adicional. WSO2 API Manager es más pesado de operar — necesita su propia base de datos y un servidor adicional — para lo que pedía este parcial.

## Por qué dos instancias y no una sola
Separar Kong Core de Kong Switch refuerza la misma frontera entre dominios del ADR-001: cada API Gateway solo conoce las rutas de su dominio, evitando que una mala configuración en las reglas del Switch afecte accidentalmente al tráfico del Core.

## Consecuencias
- A favor: configuración guardada como código, versionada en el repositorio, una por instancia.
- A favor: límite de peticiones y control de origen centralizados, sin repetir esa lógica en cada microservicio.
- En contra: en el modo actual, cada instancia de Kong mezcla su propia administración con el manejo del tráfico real, en vez de tenerlos separados — una limitación documentada y aceptada para el alcance de este parcial.
