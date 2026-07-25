# ADR-003: gRPC intra-dominio, REST al cruzar dominios

## Estado
Aceptado

## Contexto
El proyecto exige comunicaciÃ³n binaria (gRPC) obligatoria para llamadas inter-microservicio, pero el sistema tiene dos Bounded Contexts (Core y Switch) que deben permanecer dÃ©bilmente acoplados entre sÃ­.

## DecisiÃ³n
- **Dentro del mismo dominio**: toda comunicaciÃ³n sÃ­ncrona es **gRPC en modo UNARY**.
  - Core: `account-core-service` â†” `accounting-service`, `account-core-service` â†” `party-service`.
  - Switch: `file-reception-service` â†” `tariff-service`, `file-reception-service` â†” `notification-service` (ver ADR-011: el despacho de pagos, antes en `routing-service`, ahora vive en `file-reception-service`).
- **Al cruzar de un dominio a otro**: se usa **REST/HTTP**, tratando al otro dominio como si fuera un consumidor externo.
  - `file-reception-service` (Switch) â†’ `account-core-service` (Core): REST.
  - `clearinghouse-service` (Switch) â†’ `accounting-service` (Core): REST.

## Por quÃ© esta regla y no gRPC en todos lados
Un Bounded Context no debe depender del esquema interno (los `.proto`) de otro Bounded Context â€” eso acoplarÃ­a su evoluciÃ³n. Tratar la frontera entre Core y Switch igual que se tratarÃ­a una integraciÃ³n con un sistema externo (vÃ­a contrato HTTP/REST versionado) es coherente con DDD: el dominio ajeno se consume como una API pÃºblica, no como una llamada interna.

## Consecuencias
- (+) Cada dominio puede versionar y evolucionar sus contratos gRPC internos sin romper al otro dominio.
- (+) Las llamadas cross-dominio son mÃ¡s fÃ¡ciles de inspeccionar/depurar (HTTP estÃ¡ndar) y de exponer eventualmente vÃ­a el API Gateway si se requiriera.
- (-) La latencia cross-dominio es mayor que gRPC (serializaciÃ³n JSON vs binario), aceptable porque estas llamadas no estÃ¡n en el camino crÃ­tico de alta frecuencia (son dÃ©bitos/crÃ©ditos puntuales, no streaming).

