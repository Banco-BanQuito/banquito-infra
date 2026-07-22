# ADR-011 (Fase 1): Sin cobertura de pruebas automatizadas

## Estado
Aceptado (histórico — reemplazado por un requisito formal de cobertura del 70% en Fase 2, ver ADR nuevo de Fase 2)

## Contexto
El primer parcial exigía un sistema funcional end-to-end contra bases de datos reales en producción (tres canales: portal, SFTP, intranet), en un plazo de un mes, sin que esta fase del curso estableciera todavía un requisito formal de cobertura de pruebas.

## Decisión
Ningún test más allá del `contextLoads()` generado automáticamente por Spring Initializr en cada backend. Cero tests en ambos frontends. El Switch incluye `spring-boot-starter-data-jpa-test` en su `pom.xml` sin usarla en ningún archivo del proyecto.

## Por qué no se priorizó testing en esta fase
Con tres canales de ingreso distintos (portal web, SFTP, intranet) contra dos bases de datos reales desplegadas en una VM de producción, el riesgo mayor identificado por el equipo era que el sistema simplemente **no funcionara de punta a punta** — no que una unidad de código individual tuviera un bug no cubierto. Bajo presión de un plazo de un mes, el tiempo se invirtió en verificación manual del flujo completo (que sí se logró, con los tres canales operativos en producción) en vez de en pruebas automatizadas que hubieran consumido tiempo de desarrollo sin garantizar, por sí solas, que la integración completa funcionara.

## Consecuencias
- (+) El sistema completo (3 canales, 2 bases de datos, notificaciones SMTP) funcionó de punta a punta en producción para la evaluación del parcial — el objetivo priorizado se cumplió.
- (-) Ningún cambio posterior al código tiene una red de seguridad automatizada: cualquier regresión solo se detecta por verificación manual.
- (-) La dependencia de testing presente pero sin usar en el Switch (`spring-boot-starter-data-jpa-test`) confirma que el equipo era consciente de la necesidad de testing, pero el tiempo disponible no alcanzó para implementarlo — no fue una omisión por desconocimiento, sino una decisión de priorización bajo restricción de tiempo real.
