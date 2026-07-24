# ADR-013 (Fase 1): Notificaciones por correo — asíncronas en el Switch, bloqueantes en el Core

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
Ambos backends envían correos por Gmail. El Switch lo hace en segundo plano, sin que el usuario espere. El Core lo hace dentro de la misma operación, así que el usuario sí espera a que el correo se envíe.

## Contexto
El Core notifica al completar una transacción manual desde la intranet. El Switch notifica al terminar de procesar un lote completo.

## Opciones consideradas
1. **(SELECCIONADA, con diferencia entre los dos) Correo dentro del flujo normal (Core) / correo en segundo plano (Switch).**
2. **Correo en segundo plano en ambos backends.**

## Compensaciones

**Opción 1 (SELECCIONADA) — Cada backend a su manera**
- En el Switch, el envío de correo queda dentro del procesamiento del lote, que ya corre en segundo plano (ver ADR-009) — el usuario nunca espera por el correo.
- En el Core, el correo se manda dentro de la misma operación bancaria, así que el operador espera a que el correo se envíe antes de ver la confirmación — hasta 8 segundos extra en el peor caso.
- El Core ya tenía la configuración lista para mandar cosas en segundo plano (`@EnableAsync`), pero nunca se conectó al envío de correo — quedó a medio hacer.

**Opción 2 — Correo en segundo plano en ambos**
- No se aplicó en el Core dentro del tiempo de esta fase, aunque la configuración para hacerlo ya estaba lista — quedó pendiente para una próxima iteración.
