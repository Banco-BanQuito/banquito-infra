# ADR-003 (Fase 1): Integración Switch → Core síncrona vía HTTP

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
El Switch llama al Core por HTTP síncrono usando `RestClient` (cliente de Spring), con tiempos de espera fijos (5s para conectar, 15s para recibir respuesta).

## Contexto
El Switch necesita consultar saldo, debitar/acreditar cuentas y cobrar comisiones en el Core mientras procesa cada línea de un lote de pagos. El usuario debía ver el resultado de cada línea en el mismo momento, y el volumen esperado por lote todavía era bajo — no había un requisito de procesar miles de líneas bajo prueba de carga en esta fase.

## Opciones consideradas
1. **(SELECCIONADA) HTTP síncrono con RestClient:** cada línea espera la respuesta del Core antes de seguir con la siguiente.
2. **HTTP síncrono con OpenFeign:** mismo enfoque síncrono, pero con un cliente HTTP declarativo en vez de `RestClient`.
3. **Mensajería asíncrona (broker de colas):** el Switch publica cada línea y sigue de inmediato, sin esperar al Core.

## Compensaciones

**Opción 1 (SELECCIONADA) — HTTP síncrono con RestClient**
- Seleccionada porque el flujo de una transacción se puede seguir línea por línea en un solo lugar, fácil de depurar.
- Seleccionada porque `RestClient` es la forma recomendada por el propio equipo de Spring desde la versión usada en el proyecto, sin agregar una dependencia extra.
- Con esta opción no hay reintento automático ni interruptor de circuito (`circuit breaker`) — si el Core se pone lento o falla, la línea que se está procesando en ese momento se bloquea sin ningún control.
- Con esta opción, el Switch queda esperando bloqueado la respuesta del Core en cada línea — es justo esto lo que la Fase 2 corrige al meter un broker de mensajes.

**Opción 2 — HTTP síncrono con OpenFeign**
- Rechazada porque agrega una dependencia (`spring-cloud-starter-openfeign`) pensada para balancear carga entre varias instancias del Core, algo que no hacía falta en esta fase con una sola instancia corriendo.

**Opción 3 — Mensajería asíncrona**
- Rechazada porque en esta fase no existía todavía el requisito de procesar archivos de miles de líneas — meter un broker de mensajes hubiera sido complejidad sin un problema real que resolver en ese momento.
