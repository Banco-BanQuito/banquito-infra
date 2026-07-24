# ADR-012 (Fase 1): Manejo de errores centralizado por servicio

**Estado:** Aceptado — sigue vigente en Fase 2
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
Cada backend tiene un solo lugar (`GlobalExceptionHandler`, con `@RestControllerAdvice`) que convierte cada tipo de error de negocio en un código HTTP, en vez de repetir ese manejo en cada controlador.

## Contexto
Ambos backends necesitan convertir errores de negocio (cuenta no encontrada, saldo insuficiente, transacción duplicada) en respuestas HTTP claras para el frontend, sin repetir el mismo bloque de código en cada endpoint.

## Opciones consideradas
1. **(SELECCIONADA) Manejo centralizado con `@RestControllerAdvice`:** un solo archivo por backend traduce cada tipo de error a su código HTTP.
2. **Manejo local en cada controlador:** cada endpoint captura sus propios errores con `try/catch`.

## Compensaciones

**Opción 1 (SELECCIONADA) — Manejo centralizado**
- Seleccionada porque evita repetir la misma traducción de "error de negocio → código HTTP" en cada endpoint, y evita que dos controladores respondan distinto ante el mismo tipo de error.
- Es el patrón que Spring ya trae listo para este problema, sin necesitar ninguna librería extra.
- En el Core, un error que no se anticipó explota como código 500 sin ningún mensaje amigable — falta un manejo genérico de respaldo.
- En el Switch sí hay un manejo genérico de respaldo, pero muestra el mensaje interno del error directo al usuario — un riesgo si ese mensaje revela detalles internos del sistema.

**Opción 2 — Manejo local en cada controlador**
- Rechazada porque hubiera repetido el mismo código de manejo de errores una y otra vez, con más riesgo de que quedara inconsistente entre endpoints.
