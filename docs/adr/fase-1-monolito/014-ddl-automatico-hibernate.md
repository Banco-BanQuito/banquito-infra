# ADR-014 (Fase 1): Hibernate genera el esquema automáticamente

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
Se configura a Hibernate (la herramienta que conecta el código con la base de datos) para que cree y ajuste las tablas solo, a partir de las clases del código, sin escribir scripts de migración.

## Contexto
El esquema de ambas bases de datos cambió seguido durante el mes de desarrollo, a medida que se iba entendiendo mejor el negocio.

## Opciones consideradas
1. **(SELECCIONADA) DDL automático de Hibernate:** el esquema se genera solo a partir del código.
2. **Migraciones versionadas (Flyway o Liquibase):** cada cambio de esquema se escribe como un script numerado.

## Compensaciones

**Opción 1 (SELECCIONADA) — DDL automático**
- Seleccionada porque, con el modelo de datos cambiando varias veces por semana, escribir un script de migración por cada ajuste hubiera consumido tiempo sin aportar mucho en esta fase.
- Con esta opción no queda ningún historial de qué campo se agregó y cuándo — no se puede reconstruir esa información desde el repositorio.
- Ya en producción, el equipo tuvo que borrar y recargar la base de datos completa cuando cambió el volumen esperado de datos — el costo real de no tener migraciones se sintió en esta misma fase.

**Opción 2 — Migraciones versionadas**
- Rechazada por tiempo: con el esquema cambiando tan seguido, escribir y mantener un script por cada cambio hubiera sido más trabajo del que el proyecto podía absorber en un mes.
