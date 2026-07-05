# ADR-003: gRPC intra-dominio, REST al cruzar dominios

## Estado
Aceptado

## Contexto
El proyecto exige comunicación binaria (gRPC) obligatoria para llamadas inter-microservicio, pero el sistema tiene dos Bounded Contexts (Core y Switch) que deben permanecer débilmente acoplados entre sí.

## Decisión
- **Dentro del mismo dominio**: toda comunicación síncrona es **gRPC en modo UNARY**.
  - Core: `account-core-service` ↔ `accounting-service`, `account-core-service` ↔ `party-service`.
  - Switch: `file-reception-service` ↔ `tariff-service`, `file-reception-service` ↔ `notification-service` (ver ADR-011: el despacho de pagos, antes en `routing-service`, ahora vive en `file-reception-service`).
- **Al cruzar de un dominio a otro**: se usa **REST/HTTP**, tratando al otro dominio como si fuera un consumidor externo.
  - `file-reception-service` (Switch) → `account-core-service` (Core): REST.
  - `clearinghouse-service` (Switch) → `accounting-service` (Core): REST.

## Por qué esta regla y no gRPC en todos lados
Un Bounded Context no debe depender del esquema interno (los `.proto`) de otro Bounded Context — eso acoplaría su evolución. Tratar la frontera entre Core y Switch igual que se trataría una integración con un sistema externo (vía contrato HTTP/REST versionado) es coherente con DDD: el dominio ajeno se consume como una API pública, no como una llamada interna.

## Consecuencias
- (+) Cada dominio puede versionar y evolucionar sus contratos gRPC internos sin romper al otro dominio.
- (+) Las llamadas cross-dominio son más fáciles de inspeccionar/depurar (HTTP estándar) y de exponer eventualmente vía el API Gateway si se requiriera.
- (-) La latencia cross-dominio es mayor que gRPC (serialización JSON vs binario), aceptable porque estas llamadas no están en el camino crítico de alta frecuencia (son débitos/créditos puntuales, no streaming).
