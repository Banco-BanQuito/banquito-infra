# 0003. Integración Switch → Core síncrona con RestClient

## Estado
Aceptado (histórico — superado por ADR-0017 en el segundo parcial)

## Contexto
El Switch necesita consultar saldo, debitar/acreditar cuentas y cobrar comisiones en el Core durante el procesamiento de cada línea de un lote de pagos.

## Decisión
Comunicación HTTP síncrona usando `RestClient` de Spring (cliente moderno, builder-style) para las llamadas de negocio, con timeouts configurados (5s conexión / 15s lectura). `RestTemplate` sobrevive en dos puntos secundarios (un bean de configuración sin uso aparente y la validación de credenciales SFTP).

## Alternativas consideradas
- Spring Cloud OpenFeign (cliente declarativo).
- Mensajería asíncrona (Kafka/RabbitMQ) entre Switch y Core.
- Resilience4j para circuit breaking.

## Consecuencias
- Simplicidad de implementación.
- Sin retry ni circuit breaker (`resilience4j` ausente de ambos `pom.xml`) — un fallo o lentitud del Core bloquea directamente la línea del lote que se esté procesando en ese instante.
- Este es el punto que el segundo parcial resuelve directamente con RabbitMQ (ADR-0017): el Switch deja de depender de que el Core responda en el momento exacto de cada línea.
