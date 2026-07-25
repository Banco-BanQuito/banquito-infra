# Bounded Context - file-reception-service

## Objetivo

Definir claramente el limite de responsabilidad del microservicio `file-reception-service` dentro del Switch de Pagos Masivos BanQuito.

La finalidad es evitar que este microservicio concentre responsabilidades que pertenecen a otros contextos, como procesamiento transaccional, clearing, notificaciones o reportes.

## Contexto funcional

`file-reception-service` pertenece al dominio del **Switch de Pagos Masivos**.

Su responsabilidad principal debe ser:

> Recibir archivos de pagos masivos, validar su estructura, registrar el lote recibido y entregar el lote validado al servicio clasificador. El servicio clasificador es quien debe publicar las lineas en Pub/Sub.

## Bounded context propuesto

El bounded context de `file-reception-service` es **Ingesta de archivos de pago**.

| Elemento | Definicion |
| --- | --- |
| Nombre del contexto | Ingesta de archivos de pago |
| Microservicio | `file-reception-service` |
| Dominio mayor | Switch de Pagos Masivos |
| Responsabilidad central | Recibir, validar estructura y registrar lotes cargados |
| Tipo de procesamiento | Entrada e ingesta, no ejecucion transaccional |
| Salida esperada | Lote validado estructuralmente y entregado al servicio clasificador |

## Responsabilidades que si pertenecen al microservicio

Estas responsabilidades si corresponden a `file-reception-service`:

| Responsabilidad | Justificacion |
| --- | --- |
| Recibir archivo desde frontend/API | Es el punto de entrada del lote de pagos. |
| Validar extension y existencia del archivo | Es validacion basica de entrada. |
| Parsear CSV/TXT | Necesario para entender cabecera, detalle y pie. |
| Validar estructura del archivo | Pertenece a la recepcion: campos, secuenciales, totales y montos declarados. |
| Calcular hash del archivo | Sirve para control de duplicados. |
| Validar duplicidad del lote | Evita aceptar dos veces el mismo archivo. |
| Registrar lote recibido | Debe persistir evidencia de recepcion. |
| Guardar estado inicial del lote | Estados como `EN_PROCESO`, `PROGRAMADO` o `DUPLICATE`. |
| Entregar lote validado al clasificador | Permite que otro servicio clasifique y publique las lineas segun su ruta. |

## Responsabilidades que no deberian pertenecer al microservicio

Estas responsabilidades actualmente pueden existir en el codigo, pero arquitectonicamente no pertenecen al bounded context de recepcion:

| Responsabilidad | Por que no pertenece | Servicio sugerido |
| --- | --- | --- |
| Publicar lineas en Pub/Sub | Es una salida tecnica del contexto de clasificacion, no de la recepcion. | `payment-line-classifier-service` |
| Consumir lineas desde Pub/Sub | Es procesamiento, no recepcion. | `payment-line-subscriber-service` / `clearinghouse-subscriber-service` |
| Debitar el monto total del lote | Es operacion transaccional bancaria. | `payment-line-subscriber-service` / Core |
| Acreditar pagos ON-US | Es procesamiento de pago. | `payment-line-subscriber-service` |
| Procesar codigos de ruta invalidos | Es registro de resultado de procesamiento. | `payment-line-subscriber-service` |
| Procesar pagos OFF-US | Pertenece al clearing/compensacion. | `clearinghouse-subscriber-service` |
| Actualizar contadores finales de procesamiento | Pertenece al seguimiento del procesamiento, no a la ingesta. | `payment-line-subscriber-service` / `report-service` |
| Enviar notificaciones | Ya existe un microservicio dedicado. | `notification-service` |
| Generar reportes | Pertenece al contexto de reportes. | `report-service` |
| Compensacion OFF-US | Pertenece al clearing. | `clearinghouse-subscriber-service` |

## Estado actual identificado

Actualmente `file-reception-service` tiene dos grupos de responsabilidades:

| Grupo | Clases relacionadas | Evaluacion |
| --- | --- | --- |
| Recepcion e ingesta | `FileReceptionController`, `FileReceptionServiceImpl`, `CsvBatchParserImpl` | Pertenece al bounded context de recepcion. |
| Clasificacion/publicacion | `PaymentLinesReadyListener`, `PaymentLinePublisherImpl`, `PubSubPaymentLinePublisher` | Debe moverse al bounded context `payment-line-classifier-service`. |
| Procesamiento/dispatch | `PubSubPaymentLineSubscriber`, `PaymentDispatchService`, `dispatch.model.*`, `dispatch.repository.*`, `dispatch.client.*` | Debe moverse a otro bounded context. |

Por eso, aunque el microservicio ya usa Pub/Sub, todavia concentra recepcion y procesamiento.

## Arquitectura objetivo

La separacion recomendada es:

```text
file-reception-service
  -> Recibe archivo
  -> Valida estructura
  -> Guarda lote recibido
  -> Entrega lote validado al clasificador

payment-line-classifier-service
  -> Recibe lote validado
  -> Clasifica lineas ON-US / OFF-US / INVALID
  -> Publica lineas en Pub/Sub

payment-line-subscriber-service
  -> Consume lineas ON-US e INVALID desde Pub/Sub
  -> Debita lote
  -> Acredita ON-US
  -> Registra invalidas
  -> Actualiza progreso

clearinghouse-subscriber-service
  -> Consume lineas OFF-US desde Pub/Sub
  -> Procesa compensacion OFF-US
  -> Genera informacion de clearing

notification-service
  -> Recibe solicitudes de notificacion
  -> Envia correos/mensajes

report-service
  -> Consulta estados y resultados
  -> Genera reportes
```

## Flujo propuesto

```text
Frontend Empresas
  -> Apigee
  -> GKE Gateway
  -> file-reception-service
       - valida archivo
       - registra lote
       - envia lote validado al clasificador

  -> payment-line-classifier-service
       - clasifica lineas
       - publica ON-US / OFF-US / INVALID

Pub/Sub payment-lines-onus / payment-lines-invalid
  -> payment-line-subscriber-service
       - procesa ON-US e invalidas

Pub/Sub payment-lines-offus
  -> clearinghouse-subscriber-service
       - procesa compensacion OFF-US
```

## Decision arquitectonica

La decision es:

> `file-reception-service` debe limitarse al bounded context de ingesta de archivos. No debe ejecutar procesamiento transaccional de pagos ni publicar/consumir lineas de pago. La publicacion en Pub/Sub debe estar en `payment-line-classifier-service`, y el consumo debe estar en servicios subscriber especializados.

## Beneficios de separar el bounded context

| Beneficio | Explicacion |
| --- | --- |
| Menor acoplamiento | La recepcion del archivo no depende directamente del procesamiento de pagos. |
| Mejor escalabilidad | Se puede escalar recepcion y procesamiento por separado. |
| Mejor resiliencia | Si el procesamiento falla, la recepcion puede seguir aceptando lotes validos. |
| Mejor trazabilidad | Cada servicio tiene responsabilidad clara en logs y metricas. |
| Mejor mantenibilidad | Cambios en clearing o debito no afectan la recepcion del archivo. |
| Mejor defensa arquitectonica | Se demuestra separacion por dominio y responsabilidad. |

## Riesgo de cambiarlo de golpe

Mover el procesamiento fuera de `file-reception-service` requiere crear o adaptar otro microservicio consumidor.

Si simplemente se elimina el subscriber actual sin crear el reemplazo:

| Riesgo | Impacto |
| --- | --- |
| Las lineas se publican pero nadie las procesa | Los lotes quedan en proceso. |
| No se ejecuta debito inicial | No hay operacion bancaria real. |
| No se actualizan contadores | El frontend queda en 0% o sin avance. |
| No se procesa ON-US/OFF-US | El flujo de pagos se detiene. |

Por eso la migracion debe hacerse por fases.

## Plan de migracion recomendado

| Fase | Accion | Resultado |
| --- | --- | --- |
| 1 | Mantener el flujo actual para demo | No se rompe funcionalidad existente. |
| 2 | Crear `payment-line-classifier-service` | Nuevo bounded context de clasificacion de lineas. |
| 3 | Mover `PaymentLinesReadyListener`, `PaymentLinePublisherImpl` y `PubSubPaymentLinePublisher` al router publisher | File Reception deja de publicar lineas. |
| 4 | Crear `payment-line-subscriber-service` | Nuevo bounded context de consumo ON-US/INVALID. |
| 5 | Mover `PubSubPaymentLineSubscriber` y la parte ON-US/INVALID de `PaymentDispatchService` al subscriber | File Reception deja de consumir lineas. |
| 6 | Renombrar/adaptar `clearinghouse-service` como `clearinghouse-subscriber-service` a nivel arquitectonico | Clearing consume OFF-US y compensa. |
| 7 | Validar lotes de 10, 100 y 5000 lineas | Confirmar rendimiento y consistencia. |

## Cambio operativo aplicado

Para preparar la separacion sin romper la demo actual, `file-reception-service` queda con banderas de configuracion por rol:

```properties
app.file-reception.embedded-router-enabled=${APP_EMBEDDED_ROUTER_ENABLED:true}
app.file-reception.dispatch-enabled=${APP_DISPATCH_ENABLED:true}
app.file-reception.dispatch-on-us-enabled=${APP_DISPATCH_ONUS_ENABLED:true}
app.file-reception.dispatch-off-us-enabled=${APP_DISPATCH_OFFUS_ENABLED:true}
app.file-reception.dispatch-invalid-enabled=${APP_DISPATCH_INVALID_ENABLED:true}
```

| Variable | Comportamiento |
| --- | --- |
| `APP_EMBEDDED_ROUTER_ENABLED` | Enciende o apaga el listener interno que clasifica y publica lineas en Pub/Sub. |
| `APP_DISPATCH_ENABLED` | Enciende o apaga todo el subscriber interno `PubSubPaymentLineSubscriber`. |
| `APP_DISPATCH_ONUS_ENABLED` | Permite consumir lineas ON-US desde el subscriber interno. |
| `APP_DISPATCH_OFFUS_ENABLED` | Permite consumir lineas OFF-US desde el subscriber interno. |
| `APP_DISPATCH_INVALID_ENABLED` | Permite consumir lineas INVALID desde el subscriber interno. |

Con esto se puede migrar por pasos:

```text
Estado actual:
file-reception-service valida, publica y consume por compatibilidad operativa.

Estado intermedio:
payment-line-classifier-service clasifica lineas y las entrega a Pub/Sub y payment-line-subscriber-service consume en pruebas controladas.

Estado objetivo:
file-reception-service valida archivo.
payment-line-classifier-service clasifica lineas y las entrega a Pub/Sub.
payment-line-subscriber-service consume ON-US/INVALID.
clearinghouse-subscriber-service consume OFF-US.
APP_EMBEDDED_ROUTER_ENABLED=false en file-reception-service.
APP_DISPATCH_ENABLED=false en file-reception-service.
```

Nota importante:

```text
El evento actual de Spring solo funciona dentro del mismo Pod/JVM.
Para separar fisicamente el router publisher en otro Deployment, el router debe leer el lote validado desde persistencia o mediante un mecanismo durable.
```

## Como explicarlo en la defensa

Frase corta:

> El bounded context de `file-reception-service` es la ingesta de archivos. Su responsabilidad es recibir, validar estructura y registrar el lote. La publicacion de lineas debe quedar en `payment-line-classifier-service`, y el consumo/procesamiento debe quedar en servicios subscriber.

Frase ampliada:

> Actualmente `file-reception-service` concentra recepcion, publicacion y parte del procesamiento por simplicidad del proyecto. Sin embargo, usando bounded context identificamos que su limite correcto es la recepcion de archivos. El servicio `payment-line-classifier-service` debe clasificar las lineas y entregarlas a Pub/Sub mediante un adaptador tecnico, mientras los servicios subscriber consumen las colas correspondientes. Esta separacion mejora escalabilidad, mantenimiento y claridad de dominio.

## Resumen final

| Pregunta | Respuesta |
| --- | --- |
| Cual es el bounded context de `file-reception-service`? | Ingesta de archivos de pago. |
| Debe publicar lineas en Pub/Sub? | No idealmente; eso pertenece a `payment-line-classifier-service`. |
| Debe consumir Pub/Sub? | No; eso pertenece a servicios subscriber. |
| Debe debitar cuentas? | No; eso es procesamiento transaccional. |
| Debe validar estructura del CSV? | Si. |
| Debe guardar el lote recibido? | Si. |
| Debe actualizar resultados finales? | No idealmente; eso pertenece al procesamiento/reporte. |
| Que servicio deberia publicar lineas? | `payment-line-classifier-service`. |
| Que servicio deberia procesar ON-US/INVALID? | `payment-line-subscriber-service`. |
| Que servicio deberia procesar OFF-US? | `clearinghouse-subscriber-service`. |




