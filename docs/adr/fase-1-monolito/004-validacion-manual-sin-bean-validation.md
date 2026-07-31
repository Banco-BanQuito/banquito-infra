# ADR-004 (Fase 1): Validación de negocio escrita a mano en el servicio

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
La validación de datos (montos positivos, campos obligatorios, reglas de negocio) se escribe a mano en la capa de servicio, con condiciones explícitas en el código que detienen la operación y devuelven un mensaje de error.

## Contexto
Ambos backends necesitan validar lo que el usuario envía (formato, campos obligatorios) y también reglas de negocio (saldo suficiente, cuenta activa) antes de ejecutar una operación.

## Opciones consideradas
1. **(SELECCIONADA) Validación manual en el servicio:** cada regla se escribe como una condición explícita que devuelve un mensaje de error en español.
2. **Validación declarativa:** marcar cada campo del objeto de entrada con una etiqueta especial que indica la regla ("obligatorio", "debe ser positivo"), sin escribir la condición a mano.

## Compensaciones

**Opción 1 (SELECCIONADA) — Validación manual**
- Seleccionada porque permite mensajes de error en español, específicos para cada caso ("El monto debe ser mayor a cero"), sin configurar un archivo aparte de traducciones.
- Seleccionada porque en el mismo lugar se puede mezclar validación simple (¿el campo llegó vacío?) con validación de negocio que necesita consultar la base de datos (¿la cuenta existe y está activa?) — algo que la validación declarativa por sí sola no resuelve.
- Con esta opción, cada endpoint nuevo repite el mismo patrón a mano, con más riesgo de que alguien se salte una validación bajo presión de tiempo.
- El Switch dejó preparada la librería para hacer validación declarativa, pero nunca la usó — señal de que se pensó usar y no se alcanzó a aplicar.

**Opción 2 — Validación declarativa**
- Rechazada porque, para tener mensajes de error en español, hubiera exigido configurar un archivo de traducciones adicional — trabajo extra sin beneficio real en un sistema con un solo idioma.
