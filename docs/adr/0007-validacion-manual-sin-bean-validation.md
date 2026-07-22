# 0007. Validación de negocio manual, sin Bean Validation

## Estado
Aceptado (histórico)

## Contexto
Ambos backends del primer parcial necesitan validar entradas de usuario y reglas de negocio.

## Decisión
Cero anotaciones `@NotNull`/`@Valid`/`@Email` en los DTOs — toda la validación vive en la capa de servicio como `if (...) throw new IllegalArgumentException(...)`. El Switch incluso trae `spring-boot-starter-validation` en el `pom.xml` sin usarla en ningún punto del código.

## Alternativas consideradas
- `jakarta.validation` con anotaciones declarativas + `@Valid` en los controllers.

## Consecuencias
- Mensajes de error de negocio en español, personalizados, sin necesidad de configurar `messages.properties`.
- Más explícito para debug rápido bajo presión de entrega.
- La dependencia de validación presente pero sin usar en el Switch sugiere una intención de refactor que no llegó a completarse.
