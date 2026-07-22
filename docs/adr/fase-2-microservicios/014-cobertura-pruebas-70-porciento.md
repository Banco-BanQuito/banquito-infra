# ADR-014 (Fase 2): Cobertura de pruebas unitarias mínima del 70%, limitada a Controllers y Services

## Estado
Aceptado — supersede a ADR-011 de Fase 1 (ausencia total de pruebas)

## Contexto
El enunciado de esta fase exige explícitamente pruebas unitarias con una cobertura mínima del 70%, aplicadas únicamente a las capas de Controladores y Servicios — a diferencia de la Fase 1, donde no existía ningún requisito formal de testing.

## Decisión
JUnit 5 + Mockito, con foco exclusivo en Controllers (verificar que el endpoint delega correctamente y traduce excepciones al código HTTP esperado) y Services (verificar la lógica de negocio con los repositorios mockeados). Los repositorios (`@Repository`, interfaces de Spring Data) quedan fuera del requisito de cobertura.

## Por qué excluir Repositories del requisito de cobertura
La mayoría de los repositorios en este proyecto son interfaces declarativas de Spring Data JPA/MongoDB sin ninguna implementación propia — probar una interfaz que Spring genera automáticamente en tiempo de ejecución no aporta valor real de detección de bugs, solo infla el número de cobertura sin mejorar la confianza en el sistema.

## Por qué unitarias con mocks y no pruebas de integración con Testcontainers
Testcontainers hubiera dado mayor confianza real (probar contra una base de datos y un broker reales, no simulados), pero exige tiempo de configuración e infraestructura de CI adicional que compitió, dentro del plazo de esta fase, con el tiempo necesario para construir la descomposición completa en microservicios, la integración con RabbitMQ, y el particionamiento de base de datos. Se priorizó cumplir el requisito de cobertura explícito del enunciado con el mecanismo más rápido de implementar.

## Consecuencias
- (+) Cumple el requisito formal del curso con un número de cobertura verificable y reportable.
- (+) Los mocks fuerzan a que cada servicio exponga sus dependencias de forma inyectable y testeable, mejorando indirectamente el diseño del código.
- (-) Punto ciego real y ya materializado: el bug del índice duplicado en MongoDB (`auto-index-creation` deshabilitado, ver ADR-004 de esta fase) **no lo detectó la suite de pruebas unitarias** — se encontró manualmente en producción, porque una prueba con mocks no puede detectar que un índice real nunca se creó en la base de datos real. Es evidencia directa de que un número de cobertura alto no equivale a ausencia de bugs de integración.
- (-) Los mismos bugs de infraestructura (colas mal configuradas, particiones mal definidas, timeouts de red) seguirán siendo indetectables por este tipo de prueba mientras no se complemente con pruebas de integración reales.
