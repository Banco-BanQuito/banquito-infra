# 0016. Migración de monolito dual a microservicios

## Estado
Aceptado — supersede a ADR-0001

## Contexto
El primer parcial demostró que un monolito dual funciona para un demo corto, pero acopla el despliegue completo de un dominio a un solo cambio, no permite escalar un módulo específico bajo carga, y un fallo en un módulo afecta a todos los demás dentro del mismo proceso.

## Decisión
Descomponer cada dominio en microservicios independientes: Core → `account-core-service`, `accounting-service`, `party-service`. Switch → `file-reception-service`, `tariff-service`, `clearinghouse-service`, `report-service`, `notification-service`, `routing-service`.

## Alternativas consideradas
- Mantener el monolito dual y solo verticalizar el hardware — descartado porque no resuelve el acoplamiento de despliegue ni el radio de fallo compartido.

## Consecuencias
- Cada servicio se despliega, versiona y escala de forma independiente (cada repo tiene su propio pipeline de imagen).
- Mayor complejidad operacional: hace falta descubrimiento de servicios, red compartida, observabilidad distribuida y coordinación de contratos entre servicios (gRPC/REST/eventos).
