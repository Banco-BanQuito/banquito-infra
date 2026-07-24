# ADR-011 (Fase 1): Sin pruebas automatizadas en esta fase

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
No se escribieron pruebas automatizadas más allá de la que genera Spring por defecto. Todo el testing de esta fase fue manual, probando el sistema completo ya desplegado.

## Contexto
El primer parcial pedía un sistema funcionando de punta a punta, con tres canales (portal, SFTP, intranet) contra dos bases de datos reales, en solo un mes. Esta fase del curso no exigía todavía un porcentaje de cobertura de pruebas.

## Opciones consideradas
1. **(SELECCIONADA) Verificación manual del sistema completo:** probar a mano que los tres canales funcionan de punta a punta.
2. **Pruebas automatizadas (JUnit) para las partes críticas:** escribir pruebas para las reglas de negocio más importantes, aunque no fuera 100% del código.

## Compensaciones

**Opción 1 (SELECCIONADA) — Verificación manual**
- Seleccionada porque el mayor riesgo en esta fase era que el sistema completo simplemente no funcionara de un extremo a otro — no que una función individual tuviera un error sin cubrir. El tiempo se puso en lograr que los tres canales funcionaran juntos en producción.
- Con esta opción, ningún cambio nuevo tiene una red de seguridad automática — cualquier error se detecta solo si alguien lo prueba a mano.
- El Switch dejó agregada una librería de pruebas sin usarla en ningún archivo, señal de que el equipo sabía que hacía falta testing, pero no alcanzó el tiempo.

**Opción 2 — Pruebas automatizadas para las partes críticas**
- Rechazada por tiempo: escribir pruebas junto con toda la funcionalidad nueva, en un mes, hubiera significado avanzar más lento en el objetivo principal de esta fase (tener el sistema funcionando de punta a punta).
