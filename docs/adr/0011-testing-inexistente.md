# 0011. Cobertura de pruebas prácticamente inexistente

## Estado
Aceptado (histórico — el segundo parcial introduce un requisito formal de cobertura, ver ADR-0025)

## Contexto
Plazo de un mes para entregar un sistema con 3 canales de ingreso (portal, SFTP, intranet) contra dos bases de datos reales en una VM productiva.

## Decisión
Solo el test de contexto por defecto de Spring Initializr (`contextLoads()`) en cada backend. Cero tests en ambos frontends. El Switch trae `spring-boot-starter-data-jpa-test` en el `pom.xml` sin usarla en ningún archivo.

## Alternativas consideradas
- JUnit 5 + Mockito para servicios.
- Vitest + React Testing Library para los frontends.

## Consecuencias
- Patrón típico de proyecto académico de alcance ambicioso: testing fue lo primero sacrificado bajo presión de fecha, priorizando el flujo de negocio end-to-end funcionando de verdad en producción.
- Dependencias de test presentes pero sin usar sugieren que el equipo sabía que "debía" tener tests, pero el tiempo no alcanzó.
