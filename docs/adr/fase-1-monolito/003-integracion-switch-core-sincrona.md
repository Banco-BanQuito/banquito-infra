# ADR-003 (Fase 1): Cliente HTTP y tiempos de espera para la integración Switch → Core

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
El Switch llama al Core con el cliente HTTP recomendado por el propio framework del proyecto, con tiempos de espera fijos: 5 segundos para conectar y 15 segundos para recibir respuesta.

## Contexto
El documento de requisitos del Switch (V1) ya exige que esta integración sea síncrona — el Switch debe esperar la respuesta del Core antes de seguir con la siguiente línea del lote. Eso no fue una decisión del equipo, fue un requisito explícito. Lo que sí quedó abierto fue con qué herramienta hacer esa llamada y qué tiempos de espera usar, y eso es lo que documenta este ADR.

## Opciones consideradas
1. **(SELECCIONADA) Cliente HTTP nativo del framework, con tiempos de espera fijos (5s / 15s).**
2. **Cliente HTTP declarativo de una librería aparte**, pensado para repartir carga entre varias instancias del Core.

## Compensaciones

**Opción 1 (SELECCIONADA) — Cliente HTTP nativo, tiempos fijos**
- Seleccionada porque es la forma recomendada por el propio framework que usa el proyecto, sin agregar una herramienta extra.
- Seleccionada porque el flujo de una transacción se puede seguir línea por línea en un solo lugar, fácil de depurar.
- Con esta opción no hay reintento automático ni un mecanismo que corte las llamadas cuando el Core empieza a fallar seguido — si el Core se pone lento o falla, la línea que se está procesando en ese momento se bloquea sin ningún control.
- Con esta opción, el Switch queda esperando bloqueado la respuesta del Core en cada línea — es justo esto lo que la Fase 2 corrige al meter un broker de mensajes.

**Opción 2 — Cliente HTTP declarativo de otra librería**
- Rechazada porque esa librería está pensada para repartir la carga entre varias copias del Core corriendo a la vez, algo que no hacía falta en esta fase con una sola copia corriendo.
