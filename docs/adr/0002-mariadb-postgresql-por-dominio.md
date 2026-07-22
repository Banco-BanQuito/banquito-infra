# 0002. Base de datos separada por dominio (MariaDB para Core, PostgreSQL para Switch)

## Estado
Aceptado (histórico — evoluciona a persistencia poliglota completa en ADR-0022)

## Contexto
Core y Switch son dos monolitos independientes que representan dominios de negocio distintos (banca núcleo vs. pagos masivos), y debían demostrar separación real de sistemas, no solo separación lógica de código.

## Decisión
MariaDB para el Core Bancario, PostgreSQL para el Switch de Pagos — motores distintos, sin compartir esquema ni instancia.

## Alternativas consideradas
- Una sola base de datos compartida entre ambos monolitos — más simple, pero rompe el aislamiento real entre los dos sistemas.

## Consecuencias
- Database-per-service desde el primer parcial — sienta la base para la evolución a microservicios en el segundo parcial.
- Sin transacciones distribuidas entre las dos bases; consistencia eventual gestionada con idempotencia manual (ver ADR-0009).
- No se encontró evidencia en el código de que se usara alguna característica específica de cada motor (JSONB de Postgres, replicación de MariaDB) — la elección fue principalmente pedagógica/demostrativa.
