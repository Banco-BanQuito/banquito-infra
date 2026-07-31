# ADR-008 (Fase 3): Autoescalamiento horizontal (HPA) uniforme, con escalado asimétrico

**Estado:** Aceptado
**Fecha:** Julio 2026
**Autor:** Equipo Fase 3

## Decisión
Todos los backends de Core y Switch tienen un HorizontalPodAutoscaler con el mismo umbral: mínimo 1 réplica, máximo 3, escalando hacia arriba al superar 70% de uso de CPU o 80% de memoria. La política de escalado es asimétrica: sube una réplica nueva más rápido de lo que baja una que ya no hace falta.

## Contexto
GKE Autopilot cobra por los recursos reales que consumen los Pods, así que dejar réplicas de sobra corriendo sin necesidad tiene un costo directo, pero escalar muy despacio ante un pico de tráfico degrada el servicio.

## Opciones consideradas
1. **(SELECCIONADA) HPA con umbral uniforme y escalado asimétrico, igual para todos los servicios.**
2. **Un umbral distinto por servicio, ajustado a su carga esperada individualmente.**
3. **Sin autoescalado — un número fijo de réplicas por servicio.**

## Compensaciones

**Opción 1 (SELECCIONADA) — Umbral uniforme, escalado asimétrico**
- Seleccionada porque, sin datos históricos de producción todavía (el sistema es nuevo), no había información real para justificar un umbral distinto por servicio — un valor conservador e igual para todos es más defendible que inventar números por servicio sin evidencia.
- La política de escalado es asimétrica a propósito: agregar una réplica nueva puede volver a dispararse a los 180 segundos si el tráfico sigue alto, pero quitar una réplica espera 300 segundos desde el último pico — para no destruir una réplica recién creada si el tráfico solo bajó por un momento.
- Con esta opción, ningún servicio pasa de 3 réplicas — un techo bajo, aceptado porque el volumen de este proyecto académico no exige más, pero es un límite real que un tráfico de producción mayor superaría.

**Opción 2 — Umbral distinto por servicio**
- Rechazada por falta de datos: ajustar un umbral por servicio sin evidencia de su comportamiento real bajo carga hubiera sido adivinar, no decidir con información.

**Opción 3 — Sin autoescalado**
- Rechazada porque un número fijo de réplicas no reacciona a un pico de tráfico real, y GKE Autopilot ya cobra por lo reservado — tener siempre el máximo de réplicas encendidas sin necesidad sale más caro que dejar que el HPA las apague cuando no hacen falta.
