# ADR-012 (Fase 2): Redes Docker separadas entre Core y Switch

## Estado
Aceptado

## Contexto
El ADR-001 de esta fase declara Core y Switch como dos Bounded Contexts independientes, pero esa separación, si solo vive en la organización de los repositorios y del `docker-compose.yml`, no es verificable en tiempo de ejecución — cualquier contenedor en la misma red Docker por defecto puede alcanzar a cualquier otro, sin importar a qué dominio pertenezca "en el papel".

## Decisión
Se declaran dos redes Docker explícitas — `banquito-core-net` y `banquito-switch-net` — además de una red de observabilidad separada. `party-service` y `teller-frontend` se conectan únicamente a la red del Core; `clearinghouse-service` y `tariff-service` únicamente a la del Switch. `account-core-service` es el **único** servicio conectado a ambas redes, actuando como el único puente legítimo entre los dos dominios.

## Por qué segmentar la red y no confiar solo en la separación de código
La separación de Bounded Contexts a nivel de código (paquetes, repositorios, contratos de API) no impide que, por error o por atajo bajo presión de tiempo, un desarrollador haga que un servicio del Switch llame directamente a la base de datos o a un puerto interno de un servicio del Core sin pasar por su API pública. Segmentar la red Docker convierte esa regla de "no debes" en una restricción técnica real: un contenedor que no está en la red del Core **no puede** alcanzarlo por red, sin importar qué diga el código que intenta escribirse.

## Consecuencias
- (+) La separación entre Core y Switch es verificable con una herramienta externa al código (`docker network inspect`), no solo argumentable en un diagrama.
- (+) Cualquier necesidad futura de comunicación directa entre dominios exige una decisión consciente y visible (agregar un servicio a ambas redes, como ya ocurre con `account-core-service`), no un atajo silencioso.
- (-) Depurar problemas de conectividad exige tener en cuenta explícitamente a qué red pertenece cada contenedor — un error de "connection refused" puede deberse a segmentación de red intencional, no a que el servicio destino esté caído.
