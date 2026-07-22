# ADR-015 (Fase 1): Otras decisiones técnicas menores, con evidencia directa del código

## Estado
Aceptado (histórico)

## Contexto
Decisiones puntuales, cada una demasiado pequeña para un ADR propio, pero relevantes en conjunto para entender el nivel de rigor técnico del primer parcial y para poder defender ante el evaluador que el análisis de esta fase fue sobre el código real, no sobre suposiciones.

## Decisiones y su sustento

**Lombok en el Core (54 archivos), completamente ausente en el Switch.** El Switch escribe a mano cada getter, setter, `equals`, `hashCode` y `toString` — un archivo como `ServiceFeeRule.java` tiene 145 líneas para solo 8 campos. Esto no es un accidente de un solo archivo: es consistente en todo el módulo del Switch, lo que confirma que fue una decisión (o ausencia de decisión) de todo ese sub-equipo, no un descuido puntual.

**DTOs siempre, nunca entidades JPA expuestas directamente en las respuestas.** Práctica mantenida sin excepciones en los ~15 controllers de ambos backends — evita el problema clásico de serialización infinita por relaciones bidireccionales JPA, y evita filtrar campos internos del modelo de persistencia hacia el consumidor de la API.

**Versionado de API fijo en el path** (`/core/v1/`, `/switch/v1/`), sin negociación de contenido por header. Es el patrón más simple y predecible de versionado REST, adecuado para un sistema con un único consumidor conocido por endpoint (no una API pública con múltiples versiones activas simultáneamente).

**CORS con dos configuraciones de rigor distinto.** El Core permite cualquier origen (`allowedOriginPatterns("*")`); el Switch restringe a una whitelist explícita de orígenes conocidos. El Switch, al manejar pagos masivos (mayor sensibilidad de negocio) y al ser la reescritura más tardía del proyecto (`Switch_V2`), recibió el endurecimiento que el Core nunca llegó a aplicar retroactivamente.

**Variables de entorno con valor por defecto embebido** (`${VARIABLE:valor_por_defecto}`) en el propio `application.properties`, en vez de archivos de perfil Spring separados. Permite mover el mismo artefacto compilado entre la laptop de un desarrollador y la VM de producción sin mantener dos archivos de configuración sincronizados manualmente.

**Sin rate limiting en ningún endpoint**, incluyendo `/auth/*` — consecuencia directa de la ausencia de una capa de autorización de API completa (ver ADR-004 de Fase 1): si no hay control de acceso a nivel de servidor, tampoco se priorizó un control de frecuencia de peticiones.

**Código vestigial real, encontrado por lectura directa del código:** `FileValidationService.validateBatch()` construye un registro de auditoría marcado como éxito de forma incondicional, sin volver a ejecutar ninguna validación — la lógica de validación real ya se había movido antes a `validateEarlyRejection()`, y este método quedó como un registro "siempre verde" tras un refactor que no se completó del todo. Es un ejemplo concreto y citable de deuda técnica real, útil para demostrar ante el evaluador que la revisión de esta fase fue exhaustiva y no superficial.
