# ADR-013 (Fase 1): Notificaciones por correo — asíncronas en el Switch, bloqueantes en el Core

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
Ambos backends envían correos por Gmail. El Switch lo hace en segundo plano, sin que el usuario espere. El Core lo hace dentro de la misma operación, así que el usuario sí espera a que el correo se envíe.

## Contexto
El documento de requisitos del Switch (V1) ya exige notificar por correo al beneficiario apenas se acredita su pago — eso no fue una decisión del equipo, fue un requisito explícito (RF-05). Que esa notificación sea o no bloqueante para el usuario sí quedó abierto. Notificar también las transacciones manuales del Core no está pedido en ningún documento — esa parte es enteramente decisión del equipo.

## Opciones consideradas
1. **(SELECCIONADA, distinta en cada uno) Correo dentro del flujo normal en el Core, correo en segundo plano en el Switch.**
2. **Correo en segundo plano en ambos backends.**

## Compensaciones

**Opción 1 (SELECCIONADA) — Cada backend a su manera**
- En el Switch, el envío de correo queda dentro del procesamiento del lote, que ya corre en segundo plano (ver ADR-009) — el usuario nunca espera por el correo.
- En el Core, el correo se manda dentro de la misma operación bancaria, así que el operador espera a que el correo se envíe antes de ver la confirmación — hasta 8 segundos extra en el peor caso.
- El Core ya tenía preparado el mecanismo para mandar cosas en segundo plano, pero nunca se conectó al envío de correo — quedó a medio hacer.

**Opción 2 — Correo en segundo plano en ambos**
- No se aplicó en el Core dentro del tiempo de esta fase, aunque la configuración para hacerlo ya estaba lista — quedó pendiente para una próxima iteración.
