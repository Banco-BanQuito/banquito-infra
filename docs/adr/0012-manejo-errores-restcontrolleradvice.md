# 0012. Manejo de errores centralizado, con rigor inconsistente entre servicios

## Estado
Aceptado (histórico)

## Contexto
Ambos backends necesitan traducir excepciones de negocio a respuestas HTTP consistentes.

## Decisión
`@RestControllerAdvice` (`GlobalExceptionHandler`) en ambos backends. El Core mapea 8 tipos específicos de excepción pero sin catch-all genérico (un error no previsto explota como 500 sin control). El Switch mapea menos tipos específicos pero sí tiene un catch-all que expone `e.getMessage()` directamente en el body de la respuesta.

## Alternativas consideradas
- `ProblemDetail` (RFC 7807), disponible nativo desde Spring 6 — no utilizado, las respuestas de error son `Map` ad-hoc.

## Consecuencias
- Ambos aplicaron el patrón "correcto" enseñado en el curso — buena señal de consistencia arquitectónica básica.
- El catch-all del Switch filtra potencialmente detalles internos al cliente — riesgo de seguridad menor típico de un entorno académico donde no se pensó en exposición de stack traces como amenaza.
- La diferencia de rigor entre ambos manejadores sugiere autoría en momentos distintos sin revisión cruzada final.
