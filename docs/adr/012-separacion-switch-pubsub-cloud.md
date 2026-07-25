# ADR-012: Separacion del flujo Pub/Sub del Switch de Pagos

## Estado

Aceptado.

Este ADR supersede la decision historica de mantener la clasificacion/publicacion/consumo dentro de `file-reception-service`.

## Contexto

El Switch de Pagos Masivos procesa archivos con muchas lineas. En la implementacion inicial, `file-reception-service` recibia el archivo, validaba estructura, clasificaba lineas, publicaba a Pub/Sub y tambien consumia mensajes para procesarlos.

Esa solucion funcionaba para una demo, pero concentra demasiadas responsabilidades en un solo microservicio.

## Decision

Separar el flujo en cuatro responsabilidades:

| Servicio | Rol |
| --- | --- |
| `file-reception-service` | Recibe y valida archivo. |
| `payment-line-classifier-service` | Clasifica lineas y las entrega a Pub/Sub mediante un adaptador tecnico. |
| `payment-line-subscriber-service` | Consume ON-US/INVALID. |
| `clearinghouse-subscriber-service` | Consume OFF-US. |

## Flujo objetivo

```text
file-reception-service
  -> recibe archivo
  -> valida estructura
  -> registra lote

payment-line-classifier-service
  -> toma las lineas del lote validado
  -> clasifica:
       ON-US
       OFF-US
       INVALID
  -> publica en Pub/Sub con atributos de ruteo

Pub/Sub
  -> entrega mensajes ya clasificados

payment-line-subscriber-service
  -> consume ON-US / INVALID

clearinghouse-subscriber-service
  -> consume OFF-US
```

## Justificacion

Pub/Sub no clasifica archivos ni interpreta reglas bancarias. Pub/Sub solo entrega mensajes. La clasificacion ON-US, OFF-US o INVALID es logica de negocio y debe vivir en un servicio de aplicacion.

## Consecuencias

- (+) `file-reception-service` queda limitado a ingesta y validacion.
- (+) El router publisher se puede escalar segun volumen de archivos.
- (+) Los consumers se pueden escalar segun backlog de Pub/Sub.
- (+) El clearing queda separado del procesamiento ON-US.
- (-) Se agregan mas artefactos desplegables y pipelines.
- (-) La separacion fisica requiere un mecanismo durable para que el router reciba el lote validado.

## Nota de implementacion

El evento interno actual de Spring no cruza Pods. Para que `payment-line-classifier-service` funcione como microservicio separado, debe leer el lote validado desde persistencia o recibirlo mediante una llamada interna controlada.

Mientras se completa esa extraccion, el codigo queda preparado con banderas:

```text
APP_EMBEDDED_ROUTER_ENABLED
APP_DISPATCH_ENABLED
APP_DISPATCH_ONUS_ENABLED
APP_DISPATCH_OFFUS_ENABLED
APP_DISPATCH_INVALID_ENABLED
```




