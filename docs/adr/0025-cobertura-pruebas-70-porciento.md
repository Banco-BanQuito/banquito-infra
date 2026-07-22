# 0025. Cobertura de pruebas unitarias — solo Controllers y Services, mínimo 70%

## Estado
Aceptado — supersede a ADR-0011

## Contexto
Requisito explícito del curso: pruebas unitarias con cobertura ≥70%, limitadas a la capa de Controladores y Servicios.

## Decisión
JUnit 5 + Mockito, enfocadas en esas dos capas. Repositorios excluidos del requisito de cobertura por ser, en su mayoría, interfaces declarativas de Spring Data sin lógica propia que probar.

## Alternativas consideradas
- Pruebas de integración completas con Testcontainers para cada servicio — hubiera dado mayor confianza real, descartado por el tiempo disponible del equipo.

## Consecuencias
- Cobertura alta en número, pero con un punto ciego conocido: bugs de integración real con la infraestructura (índices, particiones, colas) no se detectan por este tipo de prueba.
- El bug real del índice duplicado en MongoDB (ver ADR-0017) no lo detectó la suite de tests — se encontró y corrigió manualmente en producción, evidencia directa de esta limitación.
