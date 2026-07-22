# 0020. Segmentación de red Docker entre Core y Switch

## Estado
Aceptado

## Contexto
El proyecto exige demostrar separación real entre Core y Switch, no solo lógica o de código.

## Decisión
Dos redes Docker distintas (`banquito-core-net`, `banquito-switch-net`). `party-service` y `teller-frontend` viven solo en la red del Core; `clearinghouse-service`/`tariff-service` solo en la del Switch. `account-core-service` es el único servicio conectado a ambas redes — el único puente legítimo entre los dos sistemas.

## Alternativas consideradas
- Una sola red compartida para todos los contenedores — más simple de configurar, pero no demuestra aislamiento real (cualquier contenedor podría hablarle a cualquier otro).

## Consecuencias
- Separación verificable con `docker network inspect`, no solo argumentable en una diapositiva.
- Cualquier nuevo servicio que necesite comunicarse entre Core y Switch debe pasar explícitamente por ese puente o por el API Manager, obligando a decisiones conscientes de integración.
