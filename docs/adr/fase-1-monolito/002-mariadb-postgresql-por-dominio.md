# ADR-002 (Fase 1): Motores de base de datos distintos por dominio

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
MariaDB para el Core (`banquito_core`) y PostgreSQL para el Switch (`switch_pagos`) — dos motores distintos, sin compartir base de datos ni conexión entre los dos procesos.

## Contexto
El ejercicio pedía demostrar que Core y Switch son sistemas realmente separados, no solo separados por carpetas de código. Si ambos usaran la misma base de datos, aunque fuera con esquemas distintos, alguien podría (por accidente o por atajo) hacer una consulta cruzada entre las tablas de un dominio y del otro.

## Opciones consideradas
1. **(SELECCIONADA) Motores distintos:** MariaDB para el Core, PostgreSQL para el Switch.
2. **Mismo motor, dos bases lógicas:** por ejemplo, dos bases MariaDB separadas, una para cada dominio.
3. **Una sola base de datos compartida:** un único motor y una sola base, con tablas de ambos dominios.

## Compensaciones

**Opción 1 (SELECCIONADA) — Motores distintos**
- Seleccionada porque hace imposible, no solo prohibido, cualquier consulta cruzada entre Core y Switch — ni siquiera hablan el mismo protocolo de red. Esto obliga a que toda comunicación entre los dos pase por API.
- Con esta opción no hay transacciones que abarquen ambas bases a la vez — cualquier operación que toque los dos dominios necesita otro mecanismo para mantenerse consistente.
- No se usó ninguna función específica de PostgreSQL o MariaDB que justificara la elección por capacidades técnicas — fue principalmente para forzar el aislamiento.

**Opción 2 — Mismo motor, dos bases lógicas**
- Rechazada porque, aunque separa los datos, sigue siendo técnicamente posible conectar ambas bases desde el mismo motor y hacer una consulta cruzada por accidente.

**Opción 3 — Una sola base de datos compartida**
- Rechazada porque no demuestra ninguna separación real entre los dos sistemas — cualquier desarrollador podría unir tablas de Core y Switch en una sola consulta.
