# ADR-010 (Fase 1): Cada frontend con su propio stack tecnológico

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
El frontend del Core se hizo en React con Tailwind. El frontend del Switch se hizo en TypeScript, sin ningún framework de componentes.

## Contexto
Core y Switch necesitaban interfaces web separadas (intranet de operadores para el Core, portal para clientes empresariales en el Switch), construidas por sub-equipos distintos trabajando en paralelo.

## Opciones consideradas
1. **(SELECCIONADA) Un stack distinto por frontend:** cada sub-equipo usa la herramienta con la que ya tiene experiencia.
2. **Un solo stack para los dos frontends:** ambos equipos usan la misma tecnología, aunque uno de los dos tenga que aprenderla sobre la marcha.

## Compensaciones

**Opción 1 (SELECCIONADA) — Un stack distinto por frontend**
- Seleccionada porque cada frontend consume una API distinta y no comparte componentes visuales con el otro — no había un beneficio real de compartir la misma herramienta.
- Seleccionada porque cada sub-equipo pudo avanzar en paralelo, sin depender de que el otro terminara de decidir su propio stack.
- Con esta opción, mantener el sistema a futuro es más difícil: alguien que trabaje en los dos frontends tiene que manejar dos formas distintas de construir pantallas.
- Quedó código sin usar en el Switch (un servidor propio que después se reemplazó por Nginx), señal de un cambio de plan que no se limpió del todo.

**Opción 2 — Un solo stack para los dos frontends**
- Rechazada porque hubiera obligado a uno de los dos sub-equipos a dejar la herramienta con la que ya avanzaba rápido, a mitad de un plazo de solo un mes.
