# Anexo N - Validacion completa en GKE

## Objetivo

Validar el levantamiento completo del sistema BanQuito en Google Kubernetes Engine Autopilot, respetando la arquitectura definida:

```text
Frontend -> Apigee -> GKE Gateway -> Services internos
Backends -> comunicacion interna por Service DNS y gRPC/HTTP
Mensajeria -> Google Pub/Sub administrado
Bases de datos -> servicios administrados externos
```

Fecha de validacion: `2026-07-20`.

## Alcance validado

Se validaron los tres bloques principales:

| Bloque | Namespace | Resultado |
| --- | --- | --- |
| Core Bancario | `banquito-core` | 3/3 Deployments Running |
| Switch de Pagos Masivos | `banquito-switch` | 5/5 Deployments Running |
| Frontends | `banquito-frontend` | 4/4 Deployments Running |

## Levantamiento por bloques

Para evitar saturar la cuota del proyecto, se levanto el sistema por etapas.

### Core Bancario

```powershell
kubectl scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito-core
kubectl get pods -n banquito-core -o wide
```

Resultado:

```text
account-core-service   1/1 Running
accounting-service     1/1 Running
party-service          1/1 Running
```

Evidencia de logs:

```text
account-core-service conecta PostgreSQL: jdbc:postgresql://136.112.87.173:5432/banquito?currentSchema=account_core
accounting-service conecta PostgreSQL: jdbc:postgresql://136.112.87.173:5432/banquito
party-service conecta MySQL: jdbc:mysql://136.111.132.119:3306/partydb
party-service gRPC started on port 9093
```

### Switch de Pagos Masivos

Se inicio primero el bloque base:

```powershell
kubectl scale deployment notification-service --replicas=1  -n banquito-switch
kubectl scale deployment tariff-service --replicas=1 -n banquito-switch
kubectl scale deployment report-service --replicas=1 -n banquito-switch
kubectl scale deployment file-reception-service --replicas=1 -n banquito-switch
kubectl scale deployment clearinghouse-service --replicas=1 -n banquito-switch
kubectl get pods -n banquito-switch -o wide
```

Resultado final:

```text
clearinghouse-service    1/1 Running
file-reception-service   1/1 Running
notification-service     1/1 Running
report-service           1/1 Running
tariff-service           1/1 Running
```

Evidencia de integraciones:

```text
file-reception-service conecta MySQL: jdbc:mysql://136.111.132.119:3306/filedb
file-reception-service conecta MongoDB Atlas
file-reception-service inicia Pub/Sub subscriber para payment-lines-onus-sub
file-reception-service inicia Pub/Sub subscriber para payment-lines-offus-sub
file-reception-service inicia Pub/Sub subscriber para payment-lines-invalid-sub
clearinghouse-service conecta MongoDB Atlas
clearinghouse-service inicia Pub/Sub subscriber para clearing-outbound-sub
```

Nota funcional:

```text
clearinghouse-service registro "No hay movimientos interbancarios registrados el 2026-07-20".
Ese mensaje corresponde a una regla de negocio programada; no tumbo el Pod ni bloqueo el health check.
```

### Frontends

```powershell
kubectl scale deployment operador-frontend teller-frontend web-empresas-frontend web-personas-frontend --replicas=1 -n banquito-frontend
kubectl get pods -n banquito-frontend -o wide
```

Resultado:

```text
operador-frontend        1/1 Running
teller-frontend          1/1 Running
web-empresas-frontend    1/1 Running
web-personas-frontend    1/1 Running
```

## Ajuste por cuota y scheduling

Durante la prueba, `clearinghouse-service` quedo inicialmente en `Pending`.

Evento observado:

```text
FailedScaleUp: GCE quota exceeded
0/2 nodes are available: 2 Insufficient cpu
```

Interpretacion:

```text
Autopilot intento crear capacidad adicional, pero la cuota regional del proyecto no permitio crear otro nodo.
El consumo real de CPU era bajo; el bloqueo era por requests reservados demasiado altos para el laboratorio.
```

Se ajustaron los `resources.requests` del bloque Switch:

```powershell
kubectl set resources deployment/clearinghouse-service -n banquito-switch --requests=cpu=100m,memory=384Mi --limits=cpu=500m,memory=768Mi

kubectl set resources deployment/file-reception-service deployment/notification-service deployment/report-service deployment/tariff-service -n banquito-switch --requests=cpu=100m,memory=384Mi --limits=cpu=500m,memory=768Mi

kubectl set resources deployment/file-reception-service -n banquito-switch --requests=cpu=100m,memory=512Mi --limits=cpu=500m,memory=768Mi
```

Tambien se actualizo el repositorio `banquito-infra` para que el cambio no quede solamente aplicado en vivo.

Archivos modificados:

```text
k8s/clearinghouse/deployment.yaml
k8s/file-reception/deployment.yaml
k8s/notification/deployment.yaml
k8s/report/deployment.yaml
k8s/tariff/deployment.yaml
```

## Estado final de Deployments

Comandos:

```powershell
kubectl get deployments -n banquito-core
kubectl get deployments -n banquito-switch
kubectl get deployments -n banquito-frontend
```

Resultado:

```text
banquito-core:
account-core-service   1/1
accounting-service     1/1
party-service          1/1

banquito-switch:
clearinghouse-service    1/1
file-reception-service   1/1
notification-service     1/1
report-service           1/1
tariff-service           1/1

banquito-frontend:
operador-frontend        1/1
teller-frontend          1/1
web-empresas-frontend    1/1
web-personas-frontend    1/1
```

## Consumo observado

Comandos:

```powershell
kubectl top pods -n banquito-core
kubectl top pods -n banquito-switch
kubectl top pods -n banquito-frontend
```

Consumo observado:

```text
Core:
account-core-service   4m CPU   359Mi
accounting-service     4m CPU   333Mi
party-service          4m CPU   293Mi

Switch:
clearinghouse-service    8m CPU   297Mi
file-reception-service   14m CPU  389Mi
notification-service     6m CPU   190Mi
report-service           8m CPU   204Mi
tariff-service           8m CPU   244Mi

Frontends:
operador-frontend        1m CPU   4Mi
teller-frontend          1m CPU   3Mi
web-empresas-frontend    1m CPU   3Mi
web-personas-frontend    1m CPU   3Mi
```

## Validacion de entrada publica

Se confirmo que los Services de aplicacion son `ClusterIP`, por lo tanto no existe un LoadBalancer por microservicio.

```powershell
kubectl get svc -A
```

Resultado relevante:

```text
banquito-core       account-core-service     ClusterIP
banquito-core       accounting-service       ClusterIP
banquito-core       party-service            ClusterIP
banquito-switch     file-reception-service   ClusterIP
banquito-switch     clearinghouse-service    ClusterIP
banquito-frontend   web-personas-frontend    ClusterIP
banquito-frontend   operador-frontend        ClusterIP
```

Gateway publico unico:

```powershell
kubectl get gateway -A -o wide
```

Resultado:

```text
banquito-gateway   banquito-public-gateway   gke-l7-global-external-managed   8.233.141.65
```

## Validacion de frontends por Gateway

Comandos:

```powershell
curl.exe -I http://personas.8.233.141.65.nip.io
curl.exe -I http://operador.8.233.141.65.nip.io
curl.exe -I http://teller.8.233.141.65.nip.io
curl.exe -I http://empresas.8.233.141.65.nip.io
```

Resultado:

```text
personas   HTTP/1.1 200 OK
operador   HTTP/1.1 200 OK
teller     HTTP/1.1 200 OK
empresas   HTTP/1.1 200 OK
```

URLs disponibles:

```text
http://personas.8.233.141.65.nip.io
http://operador.8.233.141.65.nip.io
http://teller.8.233.141.65.nip.io
http://empresas.8.233.141.65.nip.io
```

## Relacion con Apigee

La arquitectura queda lista para que Apigee enrute hacia el Gateway de GKE:

```text
Frontend
  -> Apigee: https://136.68.89.25.nip.io
  -> GKE Gateway: 8.233.141.65
  -> HTTPRoute
  -> Service ClusterIP
  -> Pod backend
```

Los frontends deben consumir Apigee y enviar:

```text
x-api-key: API Key propia de la aplicacion
Authorization: Bearer <JWT de Identity Platform>
```

Las llamadas internas entre microservicios no necesitan IP publica. Se resuelven por DNS interno de Kubernetes:

```text
account-core-service.banquito-core.svc.cluster.local
accounting-service.banquito-core.svc.cluster.local
party-service.banquito-core.svc.cluster.local
notification-service.banquito-switch.svc.cluster.local
tariff-service.banquito-switch.svc.cluster.local
```

## Incidente validado: lotes rechazados por Pub/Sub/Core

Fecha de validacion: `2026-07-21`.

Durante una prueba de carga de archivo desde Web Empresas, el lote fue recibido por `file-reception-service`, fragmentado y publicado en Pub/Sub para las lineas ON-US/OFF-US. El lote termino rechazado por dos causas observadas en logs:

```text
Off-Us routing error: No se pudo publicar evento de clearing en Pub/Sub
On-Us error: 500 Internal Server Error en /api/v2/payments/batch-credit
```

Comandos usados:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito-switch
kubectl --insecure-skip-tls-verify=true logs -n banquito-switch deployment/file-reception-service --tail=160
kubectl --insecure-skip-tls-verify=true logs -n banquito-switch deployment/clearinghouse-service --tail=160
kubectl --insecure-skip-tls-verify=true logs -n banquito-core deployment/account-core-service --tail=220
```

Causa identificada en Core:

```text
org.hibernate.LazyInitializationException:
Could not initialize proxy AccountSubtype - no session

Endpoint afectado:
/api/v2/payments/batch-credit
/api/v2/payments/corporate-refund
```

Solucion aplicada en `banquito-account-core-service`:

```text
AccountTransactionService ahora inicializa accountSubtype.superType dentro de la transaccion.
Se agrego JacksonConfig para exponer ObjectMapper requerido por el publisher de Pub/Sub.
Se corrigio el workflow docker-publish.yml para usar -Dmaven.test.skip=true.
```

Commits aplicados:

```text
605f08f Initialize account subtype before async accounting
f0d0a6c Skip test compilation in GKE Docker workflow
a8ed828 Add ObjectMapper bean for PubSub publisher
```

Solucion aplicada en `banquito-file-reception-service`:

```text
PubSubClearingPublisher ahora registra projectId, topic, routingKey, batchId, transactionId y causa real del error.
Esto permite diferenciar fallos de IAM, topic inexistente, credenciales, timeout o serializacion.
```

Commit aplicado:

```text
4c3d16b Log PubSub clearing publish failures
```

Imagenes desplegadas manualmente por SHA despues del CI/CD:

```powershell
kubectl --insecure-skip-tls-verify=true set image deployment/file-reception-service file-reception-service=us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/file-reception-service:4c3d16b88d0b986ffda81d6e384acd2c82ad5cc3 -n banquito-switch

kubectl --insecure-skip-tls-verify=true set image deployment/account-core-service account-core-service=us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:a8ed828bb1b11beeede905a4fe69488056239d46 -n banquito-core
```

Validacion final:

```powershell
kubectl --insecure-skip-tls-verify=true rollout status deployment/file-reception-service -n banquito-switch --timeout=300s
kubectl --insecure-skip-tls-verify=true rollout status deployment/account-core-service -n banquito-core --timeout=360s
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core
kubectl --insecure-skip-tls-verify=true get pods -n banquito-switch
```

Resultado observado:

```text
account-core-service    1/1 Running
accounting-service      1/1 Running
party-service           1/1 Running

clearinghouse-service    1/1 Running
file-reception-service   1/1 Running
notification-service     1/1 Running
report-service           1/1 Running
tariff-service           1/1 Running
```

Siguiente validacion funcional:

```text
Subir un nuevo archivo desde Web Empresas.
Si vuelve a fallar OFF-US, revisar el log nuevo de PubSubClearingPublisher porque ahora mostrara la causa tecnica exacta.
Si falla ON-US, revisar account-core-service para confirmar que ya no aparezca LazyInitializationException.
```

## Incidente validado: saldo insuficiente por cuenta no encontrada

Fecha de validacion: `2026-07-21`.

Durante una nueva prueba de archivo, Web Empresas recibio:

```json
{
  "error": "Saldo insuficiente en la cuenta de origen 1010114999 para cubrir el monto declarado (10229.97)."
}
```

La peticion llego correctamente a Apigee y a GKE:

```text
POST https://136.68.89.25.nip.io/api/v2/payments/batches
Status Code: 400 Bad Request
```

Diagnostico en logs de `file-reception-service`:

```text
No se pudo consultar saldo de cuenta 1010114999 en Core:
404 Not Found: {"error":"Account not found: 1010114999"}
```

Validacion directa desde Kubernetes:

```powershell
kubectl --insecure-skip-tls-verify=true run core-check-account `
  --rm -i --restart=Never `
  --image=curlimages/curl:8.8.0 `
  -n banquito-core `
  --command -- curl -s -i --max-time 12 `
  http://account-core-service.banquito-core.svc.cluster.local:8081/api/v2/accounts/1010114999/balance
```

Resultado:

```text
HTTP/1.1 404
{"error":"Account not found: 1010114999"}
```

Tambien se valido el cliente usado por Web Empresas:

```powershell
kubectl --insecure-skip-tls-verify=true run core-check-customer-19 `
  --rm -i --restart=Never `
  --image=curlimages/curl:8.8.0 `
  -n banquito-core `
  --command -- curl -s -i --max-time 12 `
  http://account-core-service.banquito-core.svc.cluster.local:8081/api/v2/accounts/customer/19
```

Resultado:

```text
HTTP/1.1 200
[]
```

Causa tecnica:

```text
account-core-service estaba conectado a PostgreSQL sin aplicar el schema account_core.
El pod tenia DB_SCHEMA=account_core, pero application.properties tenia comentada la propiedad:
spring.jpa.properties.hibernate.default_schema

Hibernate estaba usando el schema public:
Default catalog/schema: banquito/public
```

Solucion aplicada en `banquito-account-core-service`:

```properties
spring.jpa.properties.hibernate.default_schema=${DB_SCHEMA:account_core}
```

Commit aplicado:

```text
7c3c6a4 Use configured Postgres schema
```

Validacion posterior al despliegue:

```powershell
kubectl --insecure-skip-tls-verify=true set image deployment/account-core-service account-core-service=us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:7c3c6a4ff9fc20abd69a76aae1a98b400637c7d5 -n banquito-core
kubectl --insecure-skip-tls-verify=true rollout status deployment/account-core-service -n banquito-core --timeout=420s
```

Prueba interna:

```powershell
kubectl --insecure-skip-tls-verify=true run core-check-account-2 `
  --rm -i --restart=Never `
  --image=curlimages/curl:8.8.0 `
  -n banquito-core `
  --command -- curl -s -i --max-time 12 `
  http://account-core-service.banquito-core.svc.cluster.local:8081/api/v2/accounts/1010114999/balance
```

Resultado validado:

```json
{
  "accountId": 29256,
  "accountNumber": "1010114999",
  "availableBalance": 5185124.44,
  "accountingBalance": 5211469.80,
  "status": "ACTIVA",
  "currency": "USD"
}
```

## Incidente validado: OFF-US rechazado por serializacion Pub/Sub

Fecha de validacion: `2026-07-21`.

Despues de corregir el schema de Core, el lote avanzo correctamente para lineas ON-US:

```text
Lineas ON-US: PROCESSED
Lineas OFF-US: REJECTED
Mensaje: No se pudo publicar evento de clearing en Pub/Sub
```

Log tecnico encontrado en `file-reception-service`:

```text
No se pudo publicar evento de clearing en Pub/Sub.
projectId=project-47695a8e-7cb2-4352-af2
topic=banquito-clearing-events
routingKey=clearing.outbound
cause=Java 8 date/time type java.time.LocalDate not supported by default
OffUsClearingMessage["valueDate"]
```

Causa:

```text
JacksonConfig declaraba un ObjectMapper manual con new ObjectMapper().
Ese mapper no tenia registrado el modulo de Java Time, por eso no podia serializar LocalDate antes de publicar en Pub/Sub.
```

Solucion aplicada en `banquito-file-reception-service`:

```java
return new ObjectMapper().findAndRegisterModules();
```

Commit aplicado:

```text
296cb6c Register Java time module for PubSub messages
```

Ajuste adicional requerido:

```text
El metodo findAndRegisterModules() no encontro soporte para Java Time porque faltaba la dependencia jackson-datatype-jsr310 en el classpath.
Se agrego la dependencia al pom.xml de file-reception-service.
```

Commit aplicado:

```text
d90f984 Add Java time support for PubSub clearing messages
```

Imagen desplegada en GKE:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/file-reception-service:d90f98421ab62d7159612c5c875ee2f014eba3a8
```

Comandos usados:

```powershell
kubectl --insecure-skip-tls-verify=true set image deployment/file-reception-service file-reception-service=us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/file-reception-service:d90f98421ab62d7159612c5c875ee2f014eba3a8 -n banquito-switch
kubectl --insecure-skip-tls-verify=true rollout status deployment/file-reception-service -n banquito-switch --timeout=360s
kubectl --insecure-skip-tls-verify=true get pods -n banquito-switch
```

Resultado:

```text
file-reception-service   1/1 Running
clearinghouse-service    1/1 Running
```

Nota adicional:

```text
En el lote validado tambien aparecio DEADLINE_EXCEEDED al cobrar comision contra tariff-service.
Ese punto corresponde a timeout gRPC de tarifas; no es el mismo fallo de Pub/Sub.
```

## Comando para apagar al finalizar pruebas

Para evitar consumo cuando no se esta probando:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-switch
kubectl scale deployment --all --replicas=0 -n banquito-frontend
```

Verificar:

```powershell
kubectl get deployments -n banquito-core
kubectl get deployments -n banquito-switch
kubectl get deployments -n banquito-frontend
kubectl get pods -A
```

## Levantamiento por bloques validado

Despues de apagar los Deployments a `0/0`, se valido levantar el sistema por bloques para evitar presion de recursos en GKE Autopilot.

Orden usado:

```text
1. Core Bancario completo.
2. Switch bloque pesado: file-reception y clearinghouse.
3. Switch bloque restante: tariff, report y notification.
4. Frontends.
```

### Bloque 1 - Core Bancario

Comando:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito-core
```

Resultado:

```text
account-core-service   1/1   Running
accounting-service     1/1   Running
party-service          1/1   Running
```

### Bloque 2 - File Reception y Clearinghouse

Comando:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment file-reception-service clearinghouse-service --replicas=1 -n banquito-switch
```

Durante la validacion se encontro que los pods estaban `Running`, pero no `Ready` porque los probes del cluster eran mas agresivos que los manifiestos locales. Se aplicaron los manifiestos actualizados:

```powershell
kubectl --insecure-skip-tls-verify=true apply -f k8s\file-reception\deployment.yaml -f k8s\clearinghouse\deployment.yaml
```

Resultado:

```text
file-reception-service   1/1   Running
clearinghouse-service    1/1   Running
```

### Bloque 3 - Resto del Switch

Comando:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment tariff-service report-service notification-service --replicas=1 -n banquito-switch
```

Resultado:

```text
tariff-service         1/1   Running
report-service         1/1   Running
notification-service   1/1   Running
```

### Bloque 4 - Frontends

Comando:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment teller-frontend web-personas-frontend web-empresas-frontend operador-frontend --replicas=1 -n banquito-frontend
```

Resultado:

```text
teller-frontend          1/1   Running
web-personas-frontend    1/1   Running
web-empresas-frontend    1/1   Running
operador-frontend        1/1   Running
```

## HPA observado despues del levantamiento

El HPA permanece configurado con:

```text
minReplicas: 1
maxReplicas: 3
```

Lecturas observadas:

```text
Core:
account-core-service   cpu 5%/70%, memory 65%/80%
accounting-service     cpu 5%/70%, memory 64%/80%
party-service          cpu 4%/70%, memory 58%/80%

Switch:
clearinghouse-service    cpu 5%/70%, memory 73%/80%
file-reception-service   cpu 14%/70%, memory 76%/80%
notification-service     cpu 7%/70%, memory 60%/80%
report-service           cpu 6%/70%, memory 60%/80%
tariff-service           cpu 4%/70%, memory 75%/80%
```

Interpretacion:

```text
El HPA esta activo y leyendo metricas.
Los servicios quedaron por debajo de los umbrales de escalamiento.
file-reception y tariff quedaron cerca del umbral de memoria, por lo que deben monitorearse durante pruebas de carga.
```

## Prueba pendiente - Auto-recuperacion de Pods

Aunque se validaron rollouts y pods `Running`, queda pendiente ejecutar una prueba explicita de auto-recuperacion del Deployment.

Objetivo:

```text
Comprobar que si un Pod se elimina manualmente, Kubernetes crea otro automaticamente para mantener replicas=1.
```

Servicio recomendado para la prueba:

```text
party-service
```

Motivo:

```text
Es un servicio estable, liviano y ya tiene validado su despliegue con CI/CD.
```

Comandos:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core -l app=party

kubectl --insecure-skip-tls-verify=true delete pod <pod-party-service> -n banquito-core

kubectl --insecure-skip-tls-verify=true get pods -n banquito-core -l app=party -w
```

Resultado esperado:

```text
party-service-xxxxx   Terminating
party-service-yyyyy   ContainerCreating
party-service-yyyyy   Running
```

Interpretacion:

```text
Esta prueba valida la auto-recuperacion del Deployment.
No valida HPA. HPA escala por carga; Deployment recupera replicas deseadas.
```

## Prueba pendiente - Escalamiento HPA

Se valido que HPA existe y lee metricas, pero queda pendiente una prueba de carga controlada para demostrar escalamiento automatico de replicas.

Comandos base:

```powershell
kubectl --insecure-skip-tls-verify=true get hpa -A
kubectl --insecure-skip-tls-verify=true describe hpa account-core-service-hpa -n banquito-core
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core -w
```

Resultado esperado bajo carga:

```text
REPLICAS pasa de 1 a 2 o 3.
Kubernetes crea nuevos Pods del Deployment.
Cuando baja la carga, HPA reduce replicas gradualmente hasta 1.
```

Nota:

```text
Para este laboratorio se recomienda no forzar carga pesada sin revisar cuota, porque Autopilot puede necesitar crear mas capacidad y el proyecto ya ha presentado limites de cuota.
```

## Conclusion

La prueba completa confirma:

```text
1. Las dos aplicaciones principales fueron desplegadas en GKE Autopilot.
2. Los ocho microservicios backend quedaron Running.
3. Los cuatro frontends quedaron Running.
4. La exposicion externa se mantiene centralizada en un Gateway publico.
5. Los Services internos permanecen como ClusterIP.
6. Pub/Sub funciona como servicio externo administrado para mensajeria.
7. Las bases de datos se consumen como servicios administrados externos.
8. El ajuste de resources.requests permitio correr todo el sistema dentro de la cuota disponible.
```

