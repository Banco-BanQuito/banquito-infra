# ADR-004 (Fase 1): Procesamiento del lote en segundo plano, con recuperación automática

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
El lote se procesa en segundo plano, sin bloquear al usuario que subió el archivo, con un revisor que corre cada 10 minutos y recupera lotes que quedaron atascados a mitad de camino.

## Contexto
El documento de requisitos del Switch (V1) ya exige que una línea con error no bloquee ni revierta el resto del lote — eso no fue una decisión del equipo, fue un requisito explícito (un beneficiario con cuenta cerrada no puede ser motivo para que los demás no reciban su sueldo). Lo que sí quedó abierto fue cómo correr ese procesamiento sin dejar esperando al usuario, y qué hacer si el proceso se cae a mitad de un lote — y eso es lo que documenta este ADR.

## Opciones consideradas
1. **(SELECCIONADA) Procesamiento en segundo plano, con un revisor periódico de recuperación:** el lote se procesa fuera de la petición HTTP que lo subió, y un proceso aparte revisa cada 10 minutos si quedó algo atascado.
2. **Procesar el lote dentro de la misma petición HTTP, sin segundo plano:** el usuario espera a que termine de procesarse todo el archivo.
3. **IVA configurable en tabla, igual que la comisión.**

## Compensaciones

**Opción 1 (SELECCIONADA) — Segundo plano con recuperación periódica**
- Seleccionada porque un lote de cientos de líneas puede tardar en procesarse, y no tiene sentido dejar al usuario esperando esa respuesta con la conexión abierta.
- Se agregó el revisor cada 10 minutos pensando específicamente en el caso de que el proceso se caiga a mitad de un lote.
- Con esta opción, si el proceso se reinicia a mitad de un lote, el trabajo que estaba corriendo en segundo plano no se guarda en ningún lado — el sistema no sabe automáticamente que debe seguir donde se quedó, solo lo detecta el revisor periódico. Esto lo resuelve RabbitMQ en la Fase 2, con colas que sí sobreviven a un reinicio.

**Opción 2 — Procesar dentro de la misma petición HTTP**
- Rechazada porque un lote de cientos de líneas dejaría al usuario esperando minutos con la conexión abierta, con riesgo real de que el navegador o un proxy intermedio la corte antes de terminar.

**Opción 3 — IVA configurable en tabla**
- Rechazada porque el IVA es una tasa fija por ley, a diferencia de la comisión, que sí cambia según el volumen del lote (requisito explícito de esta fase). No había ningún caso de prueba que necesitara cambiar el IVA en tiempo real.
