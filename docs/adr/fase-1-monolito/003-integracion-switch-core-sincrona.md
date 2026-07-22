# ADR-003 (Fase 1): Integración Switch → Core síncrona vía HTTP (RestClient)

## Estado
Aceptado (histórico — superado por ADR-004 de Fase 2, RabbitMQ)

## Contexto
El Switch necesita consultar saldo, debitar/acreditar cuentas y cobrar comisiones en el Core durante el procesamiento de cada línea de un lote de pagos, y el usuario final necesita saber en la misma operación si el pago se aplicó o no.

## Decisión
Comunicación HTTP síncrona con `RestClient` (cliente moderno de Spring 6.1+, builder-style) para las llamadas de negocio, con timeouts explícitos (5s conexión / 15s lectura). Confirmado en el código: `RestTemplate` sobrevive únicamente en dos puntos secundarios no relacionados con el flujo principal (un bean de configuración sin consumidor aparente, y la validación de credenciales del servidor SFTP).

## Por qué síncrono y no asíncrono desde el inicio
En el primer parcial, el volumen esperado por lote era bajo y el requisito funcional pedía que el resultado de cada línea fuera visible inmediatamente en el reporte del lote — no había todavía un requisito explícito de procesar archivos de miles de líneas bajo pruebas de carga. Bajo esas condiciones, introducir un broker de mensajes (RabbitMQ) hubiera sido complejidad sin beneficio medible: el problema que resuelve la asincronía (no bloquear al usuario mientras se procesan miles de líneas) todavía no existía como requisito en esta fase.

## Por qué RestClient y no OpenFeign
`RestClient` fue adoptado porque es la API HTTP síncrona recomendada por el propio equipo de Spring desde la versión 3.2/6.1 (el proyecto usa `spring-boot-starter-parent` en una versión reciente), evitando la dependencia adicional de `spring-cloud-starter-openfeign` para un caso de uso de llamadas HTTP directas sin necesidad de balanceo de carga declarativo entre múltiples instancias del Core.

## Consecuencias
- (+) Simplicidad de implementación y depuración: el flujo de una transacción se puede seguir línea por línea en un único stack trace.
- (+) Timeouts explícitos evitan que una llamada colgada bloquee indefinidamente el hilo de procesamiento.
- (-) Cero retry, cero circuit breaker (`resilience4j` ausente de ambos `pom.xml`) — un fallo o lentitud puntual del Core bloquea directamente la línea del lote que se esté procesando en ese instante, sin degradación controlada.
- (-) El acoplamiento temporal (el Switch espera bloqueado la respuesta del Core) es precisamente la limitación que la Fase 2 elimina al introducir RabbitMQ como capa de desacople (ver ADR-004 de Fase 2).
