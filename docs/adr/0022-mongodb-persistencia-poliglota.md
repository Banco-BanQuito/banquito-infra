# 0022. MongoDB para recepción de archivos y clearinghouse; SQL para el resto

## Estado
Aceptado — supersede a ADR-0002

## Contexto
El Switch recibe archivos de pago masivo en formatos variables (distintos layouts según banco origen/tipo de servicio) y genera archivos de salida para la cámara de compensación.

## Decisión
MongoDB para `file-reception-service` y `clearinghouse-service` — esquema flexible para datos semi-estructurados que varían por lote. PostgreSQL/MySQL para todo lo relacional por naturaleza (cuentas, clientes, transacciones contables).

## Alternativas consideradas
- Forzar todo a relacional con columnas JSON — antipatrón, pierde las ventajas de ambos mundos.
- Todo a Mongo (incluyendo cuentas/transacciones) — descartado porque el dominio contable necesita integridad referencial y transacciones ACID fuertes.

## Consecuencias
- Persistencia poliglota real: cada servicio elige el motor que mejor modela su propio dominio — database-per-service llevado también a nivel de tecnología, no solo de instancia (evolución directa de ADR-0002 del primer parcial, que ya separaba por instancia pero no por tipo de motor según la naturaleza del dato).
