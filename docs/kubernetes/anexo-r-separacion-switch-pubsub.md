# Anexo R - Separacion del flujo Pub/Sub del Switch

## Objetivo

Separar las responsabilidades del procesamiento de pagos masivos para que `file-reception-service` no concentre recepcion, clasificacion, salida a Pub/Sub y consumo de mensajes.

La arquitectura objetivo queda asi:

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

## Por que Pub/Sub no clasifica

Pub/Sub no entiende reglas bancarias. Pub/Sub solo recibe mensajes, los almacena temporalmente y los entrega a subscribers.

La clasificacion ON-US, OFF-US o INVALID debe hacerla un microservicio porque depende de reglas de negocio:

| Clasificacion | Regla de negocio |
| --- | --- |
| ON-US | La cuenta destino pertenece al Core BanQuito. |
| OFF-US | La cuenta destino pertenece a otra institucion financiera. |
| INVALID | El codigo de ruta, formato o datos de la linea no son validos. |

Pub/Sub si puede usar filtros por atributos, pero esos atributos ya deben venir calculados por la aplicacion:

```text
attributes.routingKey = "onus"
attributes.routingKey = "offus"
attributes.routingKey = "invalid"
```

## Servicios objetivo

| Servicio | Rol |
| --- | --- |
| `file-reception-service` | Recibe y valida archivo. |
| `payment-line-classifier-service` | Clasifica lineas y las entrega a Pub/Sub mediante un adaptador tecnico. |
| `payment-line-subscriber-service` | Consume ON-US/INVALID. |
| `clearinghouse-subscriber-service` | Consume OFF-US. |

## Flujo detallado

```text
1. Web Empresas envia archivo a Apigee.
2. Apigee valida API Key y JWT.
3. Apigee enruta al Gateway de GKE.
4. Gateway envia la peticion a file-reception-service.
5. file-reception-service valida estructura, totales, duplicidad y registra el lote.
6. payment-line-classifier-service toma el lote validado.
7. payment-line-classifier-service clasifica cada linea.
8. payment-line-classifier-service publica mensajes en Pub/Sub.
9. payment-line-subscriber-service consume ON-US/INVALID.
10. clearinghouse-subscriber-service consume OFF-US.
11. report-service consulta el avance y resultados.
```

## Estado aplicado en codigo

En `banquito-file-reception-service` se agregaron banderas para preparar la separacion por roles sin romper la demo actual.

| Variable | Uso |
| --- | --- |
| `APP_EMBEDDED_ROUTER_ENABLED` | Enciende/apaga el listener interno que clasifica y publica lineas. |
| `APP_DISPATCH_ENABLED` | Enciende/apaga el subscriber Pub/Sub interno. |
| `APP_DISPATCH_ONUS_ENABLED` | Permite consumir ON-US desde el subscriber interno. |
| `APP_DISPATCH_OFFUS_ENABLED` | Permite consumir OFF-US desde el subscriber interno. |
| `APP_DISPATCH_INVALID_ENABLED` | Permite consumir INVALID desde el subscriber interno. |

Configuracion agregada:

```properties
app.file-reception.embedded-router-enabled=${APP_EMBEDDED_ROUTER_ENABLED:true}
app.file-reception.dispatch-enabled=${APP_DISPATCH_ENABLED:true}
app.file-reception.dispatch-on-us-enabled=${APP_DISPATCH_ONUS_ENABLED:true}
app.file-reception.dispatch-off-us-enabled=${APP_DISPATCH_OFFUS_ENABLED:true}
app.file-reception.dispatch-invalid-enabled=${APP_DISPATCH_INVALID_ENABLED:true}
```

## Importante para no romper el sistema

La separacion fisica en Pods distintos requiere que el router reciba el lote validado por un mecanismo durable.

No basta con mover el listener a otro Deployment si el evento actual es un evento interno de Spring, porque:

```text
ApplicationEventPublisher solo funciona dentro del mismo proceso JVM.
Un evento interno de Spring no viaja de un Pod a otro.
```

Por eso, para separar completamente los servicios, hay que implementar uno de estos mecanismos:

| Opcion | Explicacion | Recomendacion |
| --- | --- | --- |
| Persistencia + polling controlado | `file-reception-service` guarda lote y lineas; router lee lotes pendientes. | Buena para este proyecto. |
| Endpoint interno | `file-reception-service` llama HTTP/gRPC interno al router. | Simple, pero acopla recepcion con router. |
| Evento durable de lote | `file-reception-service` publica solo un evento de lote validado. | Valido, pero contradice la decision actual de no publicar desde recepcion. |

La opcion mas alineada con lo decidido es:

```text
file-reception-service guarda el lote validado en persistencia.
payment-line-classifier-service lee lotes pendientes, clasifica lineas y las entrega al broker administrado.
```

## Modo actual compatible con demo

Mientras no exista el nuevo router publisher como microservicio fisico, se mantiene:

```text
APP_EMBEDDED_ROUTER_ENABLED=true
APP_DISPATCH_ENABLED=true
APP_DISPATCH_ONUS_ENABLED=true
APP_DISPATCH_OFFUS_ENABLED=true
APP_DISPATCH_INVALID_ENABLED=true
```

Esto conserva el comportamiento actual y evita que los lotes queden sin procesar.

## Modo objetivo cuando existan los nuevos servicios

En `file-reception-service`:

```text
APP_EMBEDDED_ROUTER_ENABLED=false
APP_DISPATCH_ENABLED=false
```

En `payment-line-classifier-service`:

```text
APP_EMBEDDED_ROUTER_ENABLED=true
APP_DISPATCH_ENABLED=false
```

En `payment-line-subscriber-service`:

```text
APP_EMBEDDED_ROUTER_ENABLED=false
APP_DISPATCH_ENABLED=true
APP_DISPATCH_ONUS_ENABLED=true
APP_DISPATCH_INVALID_ENABLED=true
APP_DISPATCH_OFFUS_ENABLED=false
```

En `clearinghouse-subscriber-service`:

```text
Consume OFF-US.
No debe procesar ON-US ni INVALID.
```

## Diagrama para defensa

```text
                   +----------------------+
                   |   Web Empresas       |
                   +----------+-----------+
                              |
                              v
                   +----------------------+
                   | Apigee API Manager   |
                   | API Key + OAuth2 JWT |
                   +----------+-----------+
                              |
                              v
                   +----------------------+
                   | GKE Gateway          |
                   +----------+-----------+
                              |
                              v
                   +----------------------+
                   | file-reception       |
                   | recibe y valida      |
                   +----------+-----------+
                              |
                              v
          +------------------------------------------+
          | payment-line-classifier-service    |
          | clasifica lineas y entrega a Pub/Sub     |
          +------+----------------+------------------+
                 |                |
                 v                v
        +----------------+  +----------------+
        | ON-US/INVALID  |  | OFF-US         |
        | Pub/Sub        |  | Pub/Sub        |
        +-------+--------+  +-------+--------+
                |                   |
                v                   v
 +-----------------------------+  +-------------------------------+
 | payment-line-subscriber     |  | clearinghouse-subscriber      |
 | procesa ON-US e INVALID     |  | procesa compensacion OFF-US   |
 +-----------------------------+  +-------------------------------+
```

## Como explicarlo

Frase corta:

> Pub/Sub no clasifica archivos. La clasificacion es una regla de negocio y vive en `payment-line-classifier-service`. Pub/Sub hace el routing tecnico mediante filtros de atributos sobre mensajes ya clasificados.

Frase para defensa:

> Se separo el Switch por bounded context. `file-reception-service` queda como ingesta de archivos. El nuevo contexto `payment-line-classifier-service` clasifica las lineas y usa Pub/Sub como adaptador de salida. Luego los subscribers procesan segun el tipo de mensaje: ON-US/INVALID en `payment-line-subscriber-service` y OFF-US en `clearinghouse-subscriber-service`. Esto mejora escalabilidad, mantenibilidad y trazabilidad porque cada servicio tiene una responsabilidad concreta.




