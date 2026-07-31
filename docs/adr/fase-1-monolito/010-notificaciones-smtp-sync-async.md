# ADR-010 (Fase 1): Dos notificaciones independientes por correo — no un mensaje duplicado

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
El Core y el Switch envían correos por separado, cada uno por un motivo distinto: el Core notifica cuando un operador de agencia completa una transacción manual desde la intranet; el Switch notifica al beneficiario cuando se le acredita un pago de un lote. No son dos avisos de la misma operación — son dos funciones distintas, en dos sistemas distintos, que nunca se activan por el mismo evento.

## Contexto
El documento de requisitos del Switch (V1) ya exige notificar por correo al beneficiario apenas se acredita su pago — eso no fue una decisión del equipo, fue un requisito explícito (RF-05). Que el Core también notificara sus propias transacciones manuales no está pedido en ningún documento — esa parte es enteramente decisión del equipo, tomada porque el Core necesitaba su propia confirmación operativa, independiente del flujo de pagos masivos del Switch.

Lo que sí quedó abierto en ambos casos fue si el envío del correo debía bloquear al usuario que espera la respuesta, o correr aparte sin que nadie tenga que esperarlo — y ahí es donde el Core y el Switch terminaron resolviéndolo distinto.

## Opciones consideradas
1. **(SELECCIONADA, distinta en cada uno) Correo dentro del flujo normal en el Core, correo en segundo plano en el Switch.**
2. **Correo en segundo plano en ambos backends.**

## Compensaciones

**Opción 1 (SELECCIONADA) — Cada backend a su manera**
- En el Switch, el envío de correo queda dentro del procesamiento del lote, que ya corre en segundo plano (ver ADR-006) — el usuario nunca espera por el correo.
- En el Core, el correo se manda dentro de la misma operación bancaria, así que el operador espera a que el correo se envíe antes de ver la confirmación — hasta 8 segundos extra en el peor caso.
- El Core ya tenía preparado el mecanismo para mandar cosas en segundo plano, pero nunca se conectó al envío de correo — quedó a medio hacer.

**Opción 2 — Correo en segundo plano en ambos**
- No se aplicó en el Core dentro del tiempo de esta fase, aunque la configuración para hacerlo ya estaba lista — quedó pendiente para una próxima iteración.
