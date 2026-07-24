# ADR-007 (Fase 1): Validación de negocio escrita a mano en el servicio

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
La validación de datos (montos positivos, campos obligatorios, reglas de negocio) se escribe a mano en la capa de servicio, con bloques `if` que lanzan una excepción con el mensaje de error.

## Contexto
Ambos backends necesitan validar lo que el usuario envía (formato, campos obligatorios) y también reglas de negocio (saldo suficiente, cuenta activa) antes de ejecutar una operación.

## Opciones consideradas
1. **(SELECCIONADA) Validación manual en el servicio:** cada regla se escribe como un `if` explícito que lanza una excepción con mensaje en español.
2. **Bean Validation declarativa:** anotaciones como `@NotNull` o `@Positive` directo en los campos del DTO.

## Compensaciones

**Opción 1 (SELECCIONADA) — Validación manual**
- Seleccionada porque permite mensajes de error en español, específicos para cada caso ("El monto debe ser mayor a cero"), sin configurar un archivo aparte de traducciones.
- Seleccionada porque en el mismo lugar se puede mezclar validación simple (¿el campo llegó vacío?) con validación de negocio que necesita consultar la base de datos (¿la cuenta existe y está activa?) — algo que las anotaciones por sí solas no resuelven.
- Con esta opción, cada endpoint nuevo repite el mismo patrón a mano, con más riesgo de que alguien se salte una validación bajo presión de tiempo.
- El Switch declaró la librería de Bean Validation en su configuración pero nunca la usó — señal de que se pensó usar y no se alcanzó a aplicar.

**Opción 2 — Bean Validation declarativa**
- Rechazada porque, para tener mensajes de error en español, hubiera exigido configurar un archivo de traducciones adicional — trabajo extra sin beneficio real en un sistema con un solo idioma.
