# 0014. DDL automático de Hibernate, sin migraciones versionadas

## Estado
Aceptado (histórico)

## Contexto
El esquema de ambas bases de datos cambió constantemente durante el mes de desarrollo del primer parcial.

## Decisión
`spring.jpa.hibernate.ddl-auto=update` en ambos backends — Hibernate genera y evoluciona el esquema automáticamente. Sin Flyway ni Liquibase.

## Alternativas consideradas
- Flyway con scripts de migración versionados (`V1__init.sql`, `V2__add_column.sql`, etc.).

## Consecuencias
- Evita la fricción de escribir migraciones manuales cada vez que se agrega un campo — razonable para desarrollo activo de un mes.
- Riesgoso para una base de datos de producción real: el propio equipo documentó tener que hacer `DROP DATABASE` + recarga completa cuando cambiaba el volumen de datos esperado, señal directa de que ya sintieron el costo de no tener migraciones versionadas.
- `SPRING_PROFILES_ACTIVE=prod` está declarado en producción pero no existe un `application-prod.properties` correspondiente — vestigio de un plan de perfiles Spring que no se completó.
