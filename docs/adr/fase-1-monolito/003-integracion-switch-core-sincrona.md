# ADR-003 (Fase 1): Integración Switch → Core síncrona vía HTTP

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
El Switch llama al Core por HTTP, esperando siempre la respuesta antes de seguir, con tiempos de espera fijos: 5 segundos para conectar y 15 segundos para recibir respuesta.

## Contexto
El Switch necesita consultar saldo, debitar o acreditar cuentas y cobrar comisiones en el Core mientras procesa cada línea de un lote de pagos. El usuario debía ver el resultado de cada línea en el mismo momento, y el volumen esperado por lote todavía era bajo — no había un requisito de procesar miles de líneas bajo prueba de carga en esta fase.

## Opciones consideradas
1. **(SELECCIONADA) Llamada HTTP que espera respuesta:** cada línea espera la respuesta del Core antes de seguir con la siguiente.
2. **Llamada HTTP que espera respuesta, con otra librería cliente:** mismo enfoque, pero con una herramienta distinta para armar la llamada.
3. **Mensajería asíncrona con un broker de colas:** el Switch publica cada línea y sigue de inmediato, sin esperar al Core.

## Compensaciones

**Opción 1 (SELECCIONADA) — Llamada HTTP que espera respuesta**
- Seleccionada porque el flujo de una transacción se puede seguir línea por línea en un solo lugar, fácil de depurar.
- Seleccionada porque es la forma recomendada por el propio framework que usa el proyecto, sin agregar una herramienta extra.
- Con esta opción no hay reintento automático ni un mecanismo que corte las llamadas cuando el Core empieza a fallar seguido — si el Core se pone lento o falla, la línea que se está procesando en ese momento se bloquea sin ningún control.
- Con esta opción, el Switch queda esperando bloqueado la respuesta del Core en cada línea — es justo esto lo que la Fase 2 corrige al meter un broker de mensajes.

**Opción 2 — Otra librería cliente, mismo enfoque síncrono**
- Rechazada porque agrega una herramienta extra pensada para repartir la carga entre varias copias del Core corriendo a la vez, algo que no hacía falta en esta fase con una sola copia corriendo.

**Opción 3 — Mensajería asíncrona**
- Rechazada porque en esta fase no existía todavía el requisito de procesar archivos de miles de líneas — meter un broker de mensajes hubiera sido complejidad sin un problema real que resolver en ese momento.
