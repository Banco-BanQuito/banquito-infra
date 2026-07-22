# ADR-014 (Fase 1): DDL automático de Hibernate, sin migraciones versionadas

## Estado
Aceptado (histórico)

## Contexto
El esquema de ambas bases de datos (Core y Switch) cambió con frecuencia a lo largo del mes de desarrollo, a medida que el dominio se iba precisando.

## Decisión
`spring.jpa.hibernate.ddl-auto=update` en ambos backends — Hibernate genera y evoluciona el esquema automáticamente a partir de las entidades JPA, sin Flyway ni Liquibase.

## Por qué DDL automático y no migraciones versionadas desde el inicio
Escribir un script de migración por cada cambio de esquema tiene sentido cuando el esquema ya es relativamente estable y los cambios son incrementales y poco frecuentes. Durante el desarrollo activo de un mes, con el modelo de datos cambiando varias veces por semana a medida que se precisaban los requisitos, el costo de escribir y versionar una migración por cada ajuste hubiera sido desproporcionado frente al beneficio, que solo se materializa cuando hay múltiples entornos que deben mantenerse sincronizados de forma reproducible.

## Consecuencias
- (+) Cero fricción para iterar el modelo de datos durante el desarrollo activo del parcial.
- (-) Sin historial de cambios de esquema versionado — no hay forma de saber, a partir del repositorio, qué campo se agregó en qué momento del desarrollo.
- (-) Riesgo real materializado en producción: el propio equipo documentó tener que ejecutar `DROP DATABASE` y recargar los datos desde cero cuando el volumen de datos esperado cambió, evidencia directa del costo de no tener un mecanismo de migración incremental una vez que el sistema ya estaba en producción con datos reales.
- (-) `SPRING_PROFILES_ACTIVE=prod` está declarado en el `.service` de systemd de producción, pero no existe ningún `application-prod.properties` correspondiente en el repositorio — vestigio de un plan de perfiles Spring diferenciados (desarrollo vs. producción) que no llegó a implementarse.
