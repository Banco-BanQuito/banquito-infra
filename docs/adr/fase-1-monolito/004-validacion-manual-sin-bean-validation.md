# ADR-004 (Fase 1): Validación imperativa en el servicio, sin Bean Validation declarativa

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
La validación de datos (montos positivos, campos obligatorios, reglas de negocio) se implementa de forma **imperativa** en la capa de servicio: condiciones explícitas en el código (`if` que verifica la regla y lanza una excepción con mensaje) en vez de anotaciones **declarativas** de Bean Validation (`@NotNull`, `@Positive`, etc.) sobre los campos del objeto de entrada.

## Contexto
Ambos backends necesitan validar lo que el usuario envía (formato, campos obligatorios) y también reglas de negocio (saldo suficiente, cuenta activa) antes de ejecutar una operación.

## Opciones consideradas
1. **(SELECCIONADA) Validación imperativa en el servicio:** cada regla se escribe como una condición explícita en Java que devuelve un mensaje de error en español.
2. **Validación declarativa con Bean Validation (JSR-380):** marcar cada campo del objeto de entrada con una anotación que indica la regla (`@NotNull`, `@Positive`), sin escribir la condición a mano.

## Compensaciones

**Opción 1 (SELECCIONADA) — Validación imperativa**
- Seleccionada porque permite mensajes de error en español, específicos para cada caso ("El monto debe ser mayor a cero"), sin configurar un archivo aparte de traducciones.
- Seleccionada porque en el mismo lugar se puede mezclar validación simple (¿el campo llegó vacío?) con validación de negocio que necesita consultar la base de datos (¿la cuenta existe y está activa?) — algo que la validación declarativa por sí sola no resuelve.
- Con esta opción, cada endpoint nuevo repite el mismo patrón a mano, con más riesgo de que alguien se salte una validación bajo presión de tiempo.
- El Switch dejó preparada la librería para hacer validación declarativa, pero nunca la usó — señal de que se pensó usar y no se alcanzó a aplicar.

**Opción 2 — Validación declarativa**
- Rechazada porque, para tener mensajes de error en español, hubiera exigido configurar un archivo de traducciones adicional — trabajo extra sin beneficio real en un sistema con un solo idioma.
