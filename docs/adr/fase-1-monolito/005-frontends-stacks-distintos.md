# ADR-005 (Fase 1): Frontend del Core con React, frontend del Switch sin framework

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
Los dos frontends son JavaScript/TypeScript, pero no comparten la misma herramienta para construir la interfaz: el del Core se hizo con el framework React (más Tailwind para los estilos); el del Switch se hizo en TypeScript plano, sin ningún framework de componentes, sirviendo la página con un servidor Node propio.

## Contexto
Core y Switch necesitaban interfaces web separadas (intranet de operadores para el Core, portal para clientes empresariales en el Switch), construidas por sub-equipos distintos trabajando en paralelo, sin que el enunciado exigiera una herramienta específica para ninguna de las dos.

## Opciones consideradas
1. **(SELECCIONADA) Cada sub-equipo elige su propia herramienta:** un frontend con framework (React), el otro sin framework.
2. **Un solo framework para los dos frontends:** ambos equipos usan React, aunque uno de los dos tenga que aprenderlo sobre la marcha.

## Compensaciones

**Opción 1 (SELECCIONADA) — Cada sub-equipo elige su propia herramienta**
- Seleccionada porque cada frontend consume una API distinta y no comparte componentes visuales con el otro — no había un beneficio real de compartir la misma herramienta.
- Seleccionada porque cada sub-equipo pudo avanzar en paralelo, sin depender de que el otro terminara de decidir su propia herramienta.
- Con esta opción, mantener el sistema a futuro es más difícil: alguien que trabaje en los dos frontends tiene que manejar dos formas distintas de construir pantallas — una con componentes de React, otra manipulando el DOM directo.
- Quedó código sin usar en el Switch (un servidor propio que después se reemplazó por Nginx), señal de un cambio de plan que no se limpió del todo.

**Opción 2 — Un solo framework para los dos frontends**
- Rechazada porque hubiera obligado a uno de los dos sub-equipos a dejar la herramienta con la que ya avanzaba rápido, a mitad de un plazo de solo un mes.
