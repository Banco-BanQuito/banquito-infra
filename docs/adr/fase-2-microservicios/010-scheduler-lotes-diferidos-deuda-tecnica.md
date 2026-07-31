# ADR-010 (Fase 2): Aviso — el reloj de lotes diferidos no sobrevive a un reinicio

**Estado:** Aceptado con reserva — deuda técnica conocida, todavía sin resolver
**Fecha:** Junio 2026
**Autor:** Equipo Fase 2

## Decisión
Los lotes que llegan después de la hora de corte se agendan con un un programador de tareas de Spring, guardado solo en memoria, para procesarse a las 00:01 del día siguiente.

## Contexto
Un lote que llega tarde no se procesa de inmediato: se marca como `PROGRAMADO` y debe ejecutarse solo, sin que un operador tenga que hacer nada, al día siguiente.

## Opciones consideradas
1. **(SELECCIONADA, con reserva) un programador de tareas en memoria:** el aviso para procesar el lote vive solo en la memoria del proceso.
2. **Guardar el aviso en base de datos + revisor periódico:** un proceso revisa cada cierto tiempo si hay lotes que ya deben procesarse.
3. **Mensaje diferido en RabbitMQ (con tiempo de espera):** aprovechar el mismo broker de mensajes que ya usa el sistema.

## Compensaciones

**Opción 1 (SELECCIONADA, con reserva) — un programador de tareas en memoria**
- Fue la más rápida de implementar con las herramientas que Spring ya trae.
- **Riesgo real, no hipotético:** si el proceso se reinicia antes de la hora programada (por un despliegue nuevo, una caída, o una actualización automática), el aviso se pierde sin dejar rastro, y el lote queda esperando para siempre en estado `PROGRAMADO`. Se confirmaron 4 casos reales de esto durante el desarrollo.
- No hay ninguna alerta que avise cuando esto pasa — el problema se descubre solo si un cliente pregunta por qué su pago nunca llegó.
- Se deja documentado a propósito, sin resolver todavía, porque avisar de una deuda técnica conocida es mejor que dejar que la descubran por otro lado.

**Opción 2 — Guardar en base de datos + revisor periódico**
- No se implementó en esta fase por el tiempo disponible — es el arreglo más simple de los tres pendientes.

**Opción 3 — Mensaje diferido en RabbitMQ**
- No se implementó en esta fase, aunque aprovecharía la infraestructura de colas que el sistema ya tiene (ver ADR-004 de esta fase).
