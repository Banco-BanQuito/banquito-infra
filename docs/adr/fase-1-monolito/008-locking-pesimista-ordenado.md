# ADR-008 (Fase 1): Bloqueo pesimista ordenado para transferencias

**Estado:** Aceptado — sigue vigente en Fase 2 y Fase 3
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
Toda operación que mueve saldo bloquea la fila de la cuenta con `SELECT ... FOR UPDATE`, y en las transferencias (que tocan dos cuentas), siempre se bloquean en orden alfabético por número de cuenta, sin importar el sentido de la transferencia.

## Contexto
Dos transferencias cruzadas al mismo tiempo (A le transfiere a B, mientras B le transfiere a A) pueden trabarse entre sí (deadlock) si cada una bloquea las cuentas en un orden distinto — una espera lo que tiene bloqueada la otra, y viceversa.

## Opciones consideradas
1. **(SELECCIONADA) Bloqueo pesimista con orden fijo:** se bloquean las filas desde el inicio, siempre en el mismo orden (alfabético), sin importar quién transfiere a quién.
2. **Bloqueo optimista:** se guarda una versión del registro y se reintenta si alguien más lo cambió mientras tanto.
3. **Sin bloqueo explícito:** confiar en el nivel de aislamiento por defecto de la base de datos.

## Compensaciones

**Opción 1 (SELECCIONADA) — Bloqueo pesimista con orden fijo**
- Seleccionada porque, para el saldo de una cuenta, un error no detectado a tiempo significa dinero mal calculado — un costo demasiado alto para arriesgar con reintentos.
- Seleccionada porque bloquear siempre en el mismo orden (alfabético, no según quién transfiere a quién) evita el interbloqueo por diseño, sin necesitar lógica para detectarlo y reintentar.
- Con esta opción, dos operaciones sobre la misma cuenta al mismo tiempo se ejecutan una después de la otra, nunca en paralelo — aceptado porque es más seguro que el riesgo de un saldo mal calculado.

**Opción 2 — Bloqueo optimista**
- Rechazada para el saldo porque el costo de un conflicto no detectado a tiempo (dinero mal calculado) es demasiado alto comparado con el ahorro de rendimiento. Sí se usa, en cambio, para el estado del lote en el Switch, donde un conflicto es raro y reintentar sale barato.

**Opción 3 — Sin bloqueo explícito**
- Rechazada porque deja el saldo expuesto a condiciones de carrera reales entre operaciones simultáneas sobre la misma cuenta.
