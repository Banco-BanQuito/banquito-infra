# ADR-002 (Fase 1): Motores de base de datos distintos por dominio — MariaDB (Core) y PostgreSQL (Switch)

## Estado
Aceptado (histórico — evoluciona a persistencia poliglota completa en ADR-002 de Fase 2)

## Contexto
El ejercicio exige demostrar que Core y Switch son sistemas **realmente independientes**, no solo separados por convención de paquetes. Compartir una sola base de datos entre ambos, aunque fuera con esquemas distintos, dejaría abierta la posibilidad técnica de que un desarrollador hiciera un JOIN cruzado o una consulta directa a las tablas del otro dominio, rompiendo el aislamiento en la práctica aunque el diagrama dijera lo contrario.

## Decisión
MariaDB para `banquito_core` (Core Bancario), PostgreSQL para `switch_pagos` (Switch de Pagos) — instancias y motores completamente distintos, sin esquema ni conexión compartida entre ambos backends.

| Aspecto | Core (MariaDB) | Switch (PostgreSQL) |
|---|---|---|
| Motor | MariaDB 10.x | PostgreSQL |
| Base de datos | `banquito_core` | `switch_pagos` |
| Acceso | Exclusivo del proceso `banquito-core` | Exclusivo del proceso `switch-pagos` |
| Estrategia de locking | Pesimista ordenado (ver ADR-008 de Fase 1) | Optimista (reintento en conflicto) |

## Por qué motores distintos y no el mismo motor con dos bases lógicas
Usar el mismo motor de base de datos para ambos (por ejemplo, dos bases MariaDB) hubiera sido operativamente más simple, pero **no hace explícita la independencia tecnológica** que el ejercicio busca demostrar. Elegir motores distintos vuelve técnicamente imposible cualquier atajo de integración por base de datos compartida — un desarrollador no puede, ni por accidente, hacer una consulta cruzada entre `banquito_core` y `switch_pagos`, porque ni siquiera hablan el mismo protocolo de red. Esto fuerza a que toda comunicación entre los dos sistemas pase por API (ver ADR-003 de Fase 1), que es exactamente el contrato que se quiere validar.

## Consecuencias
- (+) Aislamiento de datos verificable a nivel de infraestructura, no solo de convención de código.
- (+) Sienta la base de "database per service" que la Fase 2 generaliza a los 8 microservicios resultantes.
- (-) Sin transacciones distribuidas entre Core y Switch — cualquier operación que toque ambos dominios necesita un mecanismo de consistencia eventual (mitigado con idempotencia manual por `transactionUuid`, generalizado formalmente en ADR-010 de Fase 2).
- (-) No se encontró en el código ninguna característica específica de PostgreSQL (JSONB, `LISTEN/NOTIFY`) ni de MariaDB (replicación) que se aproveche realmente — la elección de motores fue una decisión de aislamiento arquitectónico, no de capacidades técnicas particulares de cada uno.
