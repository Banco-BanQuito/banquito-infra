# ADR-009 (Fase 1): Procesamiento del lote línea por línea, en segundo plano

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
El lote se procesa en segundo plano con `@Async`, línea por línea: si una línea falla, se marca como rechazada y el resto del lote sigue. La comisión por transacción sale de una tabla configurable; el IVA queda fijo al 15% en el código.

## Contexto
Un lote de nómina puede tener cientos de beneficiarios. Si uno solo tiene una cuenta cerrada o inválida, el resto (los sueldos de los demás empleados) no debe quedar bloqueado ni revertido.

## Opciones consideradas
1. **(SELECCIONADA) Procesamiento por línea, en segundo plano:** cada línea se procesa por separado; una línea con error no afecta a las demás.
2. **Transacción todo-o-nada:** si una sola línea falla, se revierte el lote completo.
3. **IVA configurable en tabla, igual que la comisión.**

## Compensaciones

**Opción 1 (SELECCIONADA) — Procesamiento por línea**
- Seleccionada porque así funciona un switch de pagos real: el beneficiario 47 con una cuenta cerrada no puede ser motivo para que los otros 299 empleados no reciban su sueldo ese mes.
- Se agregó además un revisor que corre cada 10 minutos y recupera lotes que quedaron atascados — pensado para el caso en que el proceso se caiga a mitad de un lote.
- Con esta opción, si el proceso se reinicia a mitad de un lote, el trabajo en segundo plano (`@Async`) no se guarda en ningún lado — el sistema no sabe automáticamente que debe seguir donde se quedó. Esto lo resuelve RabbitMQ en la Fase 2, con colas que sí sobreviven a un reinicio.

**Opción 2 — Transacción todo-o-nada**
- Rechazada porque un solo beneficiario con error tumbaría el pago de todos los demás — comportamiento que no tiene sentido para un sistema de nómina real.

**Opción 3 — IVA configurable en tabla**
- Rechazada porque el IVA es una tasa fija por ley, a diferencia de la comisión, que sí cambia según el volumen del lote (requisito explícito de esta fase). No había ningún caso de prueba que necesitara cambiar el IVA en tiempo real.
