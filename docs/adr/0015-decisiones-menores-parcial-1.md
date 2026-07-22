# 0015. Otras decisiones técnicas menores del primer parcial

## Estado
Aceptado (histórico)

## Contexto
Decisiones puntuales encontradas durante la revisión del código, cada una demasiado pequeña para un ADR propio pero relevantes para entender el nivel de madurez técnica del primer parcial.

## Decisiones y consecuencias

**Lombok en el Core, ausente en el Switch.** 54 archivos del Core usan Lombok (`@RequiredArgsConstructor`, `@Slf4j`); el Switch escribe todo el boilerplate (getters/setters/equals/hashCode) a mano. Refuerza la hipótesis de convenciones distintas por sub-equipo.

**DTOs siempre, nunca entidades JPA expuestas directamente.** Buena práctica mantenida consistentemente en los ~15 controllers revisados de ambos backends — evita serialización infinita por relaciones bidireccionales.

**Versionado de API hardcodeado en el path** (`/core/v1/`, `/switch/v1/`), sin negociación de contenido — patrón simple y común en APIs educativas.

**CORS con dos filosofías distintas.** Core permisivo (`allowedOriginPatterns("*")`); Switch con whitelist explícita de orígenes — el Switch, al manejar pagos masivos, se hizo más restrictivo, probablemente por ser la iteración más tardía (`Switch_V2`).

**Variables de entorno con default embebido** (`${VAR:default}`) en vez de perfiles Spring reales — más simple de mover entre laptop de desarrollo y GCP sin mantener dos archivos sincronizados.

**Sin rate limiting en ningún endpoint**, incluyendo `/auth/*` — coherente con la ausencia total de capa de autorización (ADR-0004).

**Código vestigial encontrado:** `FileValidation.validateBatch()` reporta éxito incondicionalmente sin volver a validar nada — la lógica real de validación ya se movió a otro método (`validateEarlyRejection()`) antes, y esta tabla quedó como registro "siempre verde" tras un refactor incompleto.
