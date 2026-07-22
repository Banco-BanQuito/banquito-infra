# ADR-012 (Fase 1): Manejo de errores centralizado con `@RestControllerAdvice`

## Estado
Aceptado — el patrón se mantiene vigente en Fase 2, con mayor rigor

## Contexto
Ambos backends necesitan traducir excepciones de negocio (cuenta no encontrada, saldo insuficiente, transacción duplicada) a respuestas HTTP consistentes y comprensibles para el frontend, sin repetir bloques try/catch en cada controller.

## Decisión
`@RestControllerAdvice` (`GlobalExceptionHandler`) en ambos backends, con una jerarquía de excepciones de negocio custom mapeadas a códigos HTTP específicos. El Core mapea 8 tipos de excepción distintos; el Switch, menos tipos específicos pero con un catch-all genérico que expone `e.getMessage()` directamente en la respuesta al cliente.

## Por qué `@RestControllerAdvice` y no manejo local por controller
Centralizar el manejo de errores en un único punto por servicio evita que la traducción de "excepción de negocio → código HTTP" se repita y potencialmente se vuelva inconsistente entre distintos controllers del mismo backend. Es el patrón estándar de Spring para este problema y no exige librerías adicionales.

## Consecuencias
- (+) Respuestas de error consistentes dentro de cada backend, con códigos HTTP semánticamente razonables para la mayoría de los casos (404 para no encontrado, 409 para conflicto, 401/403 para autenticación/autorización).
- (-) El Core no tiene catch-all genérico: una excepción no prevista explota como 500 sin ningún control ni mensaje amigable — el desarrollador debe anticipar explícitamente cada tipo de error posible.
- (-) El catch-all del Switch, aunque cubre el caso no anticipado, expone `e.getMessage()` sin filtrar directamente al cliente — riesgo de fuga de detalles internos (nombres de clase, mensajes de excepciones de librería) que en un entorno de producción real debería sanearse antes de responder al cliente.
- (-) Ninguno de los dos backends usa `ProblemDetail` (RFC 7807), disponible nativamente desde Spring 6 — las respuestas de error son `Map` construidos a mano, sin una estructura estandarizada entre servicios.
