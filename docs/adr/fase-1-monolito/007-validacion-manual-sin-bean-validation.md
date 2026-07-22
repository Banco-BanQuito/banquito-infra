# ADR-007 (Fase 1): Validación de negocio manual en la capa de servicio

## Estado
Aceptado (histórico)

## Contexto
Ambos backends necesitan validar entradas de usuario (montos positivos, formatos de identificación, campos obligatorios) y reglas de negocio (saldo suficiente, cuenta activa) antes de ejecutar una operación.

## Decisión
Cero anotaciones de Bean Validation (`@NotNull`, `@Valid`, `@Email`, `@Size`) en ningún DTO de ninguno de los dos backends. Toda la validación vive en la capa de servicio como bloques explícitos `if (...) throw new IllegalArgumentException("mensaje en español")`.

## Por qué validación manual y no Bean Validation declarativa
Bean Validation es más rápido de escribir para reglas simples (`@NotNull`, `@Positive`), pero para reglas de negocio con mensajes específicos en español ("El monto debe ser mayor a cero", "La cuenta no está activa") exige configurar un `messages.properties` con claves de internacionalización — trabajo adicional que no aporta valor cuando el sistema tiene un único idioma de destino. Validar explícitamente en el servicio permite además mezclar validación de formato y validación de reglas de negocio (que dependen de consultar la base de datos, como "la cuenta debe existir y estar activa") en el mismo punto del código, algo que Bean Validation por sí solo no puede resolver sin validadores custom adicionales.

## Consecuencias
- (+) Mensajes de error de negocio en español, específicos y accionables para el usuario final, sin configuración adicional.
- (+) Una sola capa (el servicio) concentra tanto validación de formato como de negocio, evitando que la lógica de "es válido" quede repartida entre anotaciones en el DTO y código en el servicio.
- (-) El Switch declara `spring-boot-starter-validation` en su `pom.xml` sin usarla en ningún archivo — dependencia añadida con intención de usarla que no se aprovechó, señal de un refactor de validación que se planeó y no se completó.
- (-) Sin un mecanismo declarativo, cada nuevo endpoint requiere repetir manualmente el patrón de validación, con mayor riesgo de que alguien lo omita bajo presión de tiempo.
