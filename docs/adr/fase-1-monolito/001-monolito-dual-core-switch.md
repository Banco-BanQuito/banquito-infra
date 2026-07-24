# ADR-001 (Fase 1): Monolito dual — Core y Switch como dos procesos separados

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
Se construyen dos procesos Spring Boot separados — `banquito-core` (cuentas, clientes, transacciones) y `switch-pagos` (lotes, tarifas, notificaciones) — en vez de un solo monolito o microservicios desde el inicio.

## Contexto
El primer parcial pedía entregar un Core Bancario y un Switch de Pagos funcionando en un mes, con un equipo sin experiencia previa en sistemas distribuidos. Todavía no estaba claro qué le tocaba a cada uno (¿la validación de fraude es del Switch o del Core? ¿la tarifa se calcula antes o después de consultar el saldo?), así que el dominio se fue definiendo mientras se construía el sistema.

## Opciones consideradas
1. **(SELECCIONADA) Dos procesos separados:** Core y Switch como dos aplicaciones independientes, cada una con su propia base de datos.
2. **Monolito único:** Core y Switch dentro del mismo proceso y la misma base de datos.
3. **Microservicios desde el inicio:** dividir en varios servicios pequeños (cuentas, pagos, tarifas, notificaciones) desde el primer día.

## Compensaciones

**Opción 1 (SELECCIONADA) — Dos procesos separados**
- Seleccionada porque Core y Switch cambian a ritmos distintos: el Core cambia poco (reglas bancarias), el Switch cambia seguido (tarifas, integraciones con bancos). Un solo proceso hubiera mezclado esos dos ritmos de cambio.
- Seleccionada porque separar en dos bases de datos desde ahora deja el camino listo para microservicios reales más adelante.
- Con esta opción, todo el Core se reinicia aunque cambie una sola clase — no hay despliegue independiente por módulo dentro de cada proceso.
- Con esta opción, no se puede escalar solo el Core si su carga sube — hay que escalar los dos procesos juntos o ninguno.

**Opción 2 — Monolito único**
- Rechazada porque mezclaría los ritmos de cambio de Core y Switch en un solo despliegue, obligando a redesplegar todo el sistema por un cambio de cualquiera de los dos lados.

**Opción 3 — Microservicios desde el inicio**
- Rechazada porque el equipo no tenía experiencia previa en sistemas distribuidos y el dominio todavía no estaba claro. Fijar los límites de red entre servicios demasiado pronto hubiera significado corregirlos varias veces — algo mucho más caro entre servicios que dentro de un mismo proyecto de código. Es la misma idea del patrón "Monolito Primero" de Martin Fowler: esperar a que el dominio esté claro antes de separar en servicios reales.
