# ADR-005 (Fase 1): Frontends construidos de forma independiente

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
El frontend del Core y el frontend del Switch se construyeron con React, pero de forma independiente: cada uno por su propio sub-equipo, sin compartir componentes ni coordinar una estructura de proyecto común entre los dos.

## Contexto
Core y Switch necesitaban interfaces web separadas (intranet de operadores para el Core, portal para clientes empresariales en el Switch), construidas por sub-equipos distintos trabajando en paralelo, sin que el enunciado exigiera coordinar ambos frontends como un solo proyecto.

## Opciones consideradas
1. **(SELECCIONADA) Construcción independiente por sub-equipo:** cada sub-equipo arma su propio proyecto React, desde cero, sin compartir código con el otro.
2. **Un solo proyecto compartido:** ambos frontends viven en el mismo repositorio, compartiendo componentes visuales y configuración base.

## Compensaciones

**Opción 1 (SELECCIONADA) — Construcción independiente por sub-equipo**
- Seleccionada porque cada frontend consume una API distinta y no comparte pantallas ni flujos con el otro — no había un beneficio real de forzar un solo proyecto compartido.
- Seleccionada porque cada sub-equipo pudo avanzar en paralelo, sin depender de que el otro terminara de definir su propia estructura de carpetas y componentes.
- Con esta opción, hay trabajo duplicado entre los dos: cosas básicas (llamadas a la API, manejo de sesión, componentes de formulario) se armaron dos veces, una por cada equipo, en vez de compartirse.

**Opción 2 — Un solo proyecto compartido**
- Rechazada porque hubiera exigido coordinar de entrada una estructura común entre los dos sub-equipos, a mitad de un plazo de solo un mes, cuando cada uno ya tenía su propio ritmo de avance.
