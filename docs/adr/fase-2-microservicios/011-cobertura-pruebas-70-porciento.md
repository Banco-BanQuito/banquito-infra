# ADR-011 (Fase 2): Pruebas unitarias con 70% de cobertura, solo en Controllers y Services

**Estado:** Aceptado — reemplaza al ADR-008 de Fase 1 (sin pruebas)
**Fecha:** Junio 2026
**Autor:** Equipo Fase 2

## Decisión
Se usan JUnit 5 y Mockito, con pruebas solo en Controllers y Services. Los repositorios quedan fuera del requisito de cobertura.

## Contexto
Esta fase pide, por primera vez en el proyecto, pruebas unitarias con al menos 70% de cobertura, aplicadas solo a Controllers y Services — eso es un requisito del curso, no una decisión del equipo. Lo que sí fue decisión del equipo es cómo llegar a ese número: con qué tipo de prueba y con qué herramienta.

## Opciones consideradas
1. **(SELECCIONADA) Pruebas unitarias con Mockito (simulando las dependencias):** rápidas de escribir, no necesitan una base de datos real corriendo.
2. **Pruebas de integración con Testcontainers (base de datos y broker reales):** más lentas de configurar, pero prueban contra el sistema real.

## Compensaciones

**Opción 1 (SELECCIONADA) — Pruebas unitarias con Mockito**
- Seleccionada porque cumple el requisito del curso más rápido, dejando tiempo para construir el resto de la fase (microservicios, RabbitMQ, particionamiento).
- Simular las dependencias obliga a que cada servicio quede armado de forma más fácil de probar, lo cual mejora el diseño del código de forma indirecta.
- Con esta opción, un bug real que solo aparece al conectar con la infraestructura real (por ejemplo, un índice de base de datos que nunca se creó) no lo detecta ninguna prueba — y de hecho pasó: ese bug exacto se encontró manualmente en producción, no por una prueba.

**Opción 2 — Pruebas de integración con Testcontainers**
- Rechazada por tiempo: hubiera dado más confianza real, pero exigía configurar infraestructura de pruebas adicional que competía con el tiempo necesario para el resto de la fase.
