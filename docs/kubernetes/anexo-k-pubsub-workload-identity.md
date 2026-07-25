# Anexo K - Google Pub/Sub y Workload Identity

## Objetivo

Reemplazar RabbitMQ por Google Cloud Pub/Sub como servicio administrado de mensajeria asincrona.

```text
Antes:
Microservicios -> RabbitMQ

Ahora:
Microservicios -> Google Cloud Pub/Sub
```

## Infraestructura Pub/Sub existente

Topics existentes:

```text
banquito-payment-lines
banquito-clearing-events
banquito-dead-letter
```

Subscriptions existentes:

```text
payment-lines-onus-sub
payment-lines-offus-sub
payment-lines-invalid-sub
clearing-outbound-sub
dead-letter-monitor-sub
banquito-clearing-events-sub
banquito-dead-letter-sub
```

Subscription adicional observada:

```text
banquito-payment-lines-sub
```

Si ningun microservicio la usa, se puede eliminar para evitar consumo/lecturas no necesarias.

## Microservicios impactados

| Microservicio | Rol en Pub/Sub | Namespace |
| --- | --- | --- |
| account-core-service | Publisher de mensajes hacia clearing | banquito-core |
| file-reception-service | Publisher y subscriber de lineas de pago | banquito-switch |
| clearinghouse-service | Subscriber de mensajes de clearing | banquito-switch |

## Variables agregadas al ConfigMap

Archivo:

```text
k8s/configmap.yaml
```

Variables:

```text
GCP_PROJECT_ID=project-47695a8e-7cb2-4352-af2
PUBSUB_PROJECT_ID=project-47695a8e-7cb2-4352-af2
APP_PAYMENT_LINE_TRANSPORT=pubsub
PUBSUB_TOPIC_PAYMENT_LINES=banquito-payment-lines
PUBSUB_TOPIC_CLEARING_EVENTS=banquito-clearing-events
PUBSUB_TOPIC_DEAD_LETTER=banquito-dead-letter
PUBSUB_ROUTING_KEY_ONUS=onus
PUBSUB_ROUTING_KEY_OFFUS=offus
PUBSUB_ROUTING_KEY_INVALID=invalid
PUBSUB_ROUTING_KEY_CLEARING_OUTBOUND=clearing.outbound
PUBSUB_SUBSCRIPTION_PAYMENT_LINES_ONUS=payment-lines-onus-sub
PUBSUB_SUBSCRIPTION_PAYMENT_LINES_OFFUS=payment-lines-offus-sub
PUBSUB_SUBSCRIPTION_PAYMENT_LINES_INVALID=payment-lines-invalid-sub
PUBSUB_SUBSCRIPTION_CLEARING_OUTBOUND=clearing-outbound-sub
PUBSUB_SUBSCRIPTION_DEAD_LETTER_MONITOR=dead-letter-monitor-sub
```

Modelo de ruteo:

```text
banquito-payment-lines
  -> payment-lines-onus-sub     filter attributes.routingKey = "onus"
  -> payment-lines-offus-sub    filter attributes.routingKey = "offus"
  -> payment-lines-invalid-sub  filter attributes.routingKey = "invalid"

banquito-clearing-events
  -> clearing-outbound-sub      filter attributes.routingKey = "clearing.outbound"
```

Nota: RabbitMQ queda como referencia historica/local. El flujo asincrono objetivo en GKE usa Google Cloud Pub/Sub.

## Atributos de mensajes

La clasificacion no la hace Pub/Sub. La clasificacion la hace `payment-line-classifier-service`, porque es regla de negocio del Switch.

Pub/Sub solo distribuye mensajes ya clasificados usando atributos:

| Atributo | Ejemplo | Uso |
| --- | --- | --- |
| `messageType` | `PAYMENT_LINE_CLASSIFIED` | Identifica el tipo de evento. |
| `routingKey` | `onus`, `offus`, `invalid` | Permite filtrar subscriptions. |
| `routingClassification` | `ON_US`, `OFF_US`, `INVALID` | Expone la decision de dominio. |
| `batchId` | `24a0cc51-b98a-48a8-b722-a80dc67a1604` | Trazabilidad del lote. |
| `lineNumber` | `125` | Trazabilidad de linea. |
| `source` | `payment-line-classifier-service` | Servicio que publico el evento. |
| `scheduledProcessAt` | `2026-07-23T14:00:00Z` | Fecha programada del proceso. |

Verificar filtros de subscriptions:

```powershell
gcloud pubsub subscriptions describe payment-lines-onus-sub --project=project-47695a8e-7cb2-4352-af2 --format="value(filter)"
gcloud pubsub subscriptions describe payment-lines-offus-sub --project=project-47695a8e-7cb2-4352-af2 --format="value(filter)"
gcloud pubsub subscriptions describe payment-lines-invalid-sub --project=project-47695a8e-7cb2-4352-af2 --format="value(filter)"
gcloud pubsub subscriptions describe clearing-outbound-sub --project=project-47695a8e-7cb2-4352-af2 --format="value(filter)"
```

Valores esperados:

```text
attributes.routingKey = "onus"
attributes.routingKey = "offus"
attributes.routingKey = "invalid"
attributes.routingKey = "clearing.outbound"
```

## Kubernetes ServiceAccounts creadas

Archivo:

```text
k8s/pubsub-serviceaccounts.yaml
```

ServiceAccounts:

```text
account-core-pubsub-ksa
file-reception-pubsub-ksa
clearinghouse-pubsub-ksa
```

Aplicar:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO

kubectl apply -f .\banquito-infra\k8s\pubsub-serviceaccounts.yaml
kubectl apply -f .\banquito-infra\k8s\configmap.yaml
```

Verificar:

```powershell
kubectl get serviceaccount account-core-pubsub-ksa -n banquito-core -o yaml
kubectl get serviceaccount file-reception-pubsub-ksa -n banquito-switch -o yaml
kubectl get serviceaccount clearinghouse-pubsub-ksa -n banquito-switch -o yaml
```

## Deployments actualizados

Los deployments fueron configurados para usar las Kubernetes ServiceAccounts:

```powershell
kubectl set serviceaccount deployment/account-core-service account-core-pubsub-ksa -n banquito-core
kubectl set serviceaccount deployment/file-reception-service file-reception-pubsub-ksa -n banquito-switch
kubectl set serviceaccount deployment/clearinghouse-service clearinghouse-pubsub-ksa -n banquito-switch
```

Verificar:

```powershell
kubectl get deployment account-core-service -n banquito-core -o jsonpath="{.spec.template.spec.serviceAccountName}"
kubectl get deployment file-reception-service -n banquito-switch -o jsonpath="{.spec.template.spec.serviceAccountName}"
kubectl get deployment clearinghouse-service -n banquito-switch -o jsonpath="{.spec.template.spec.serviceAccountName}"
```

## Google Service Accounts

Crear las cuentas en Google Cloud:

```powershell
gcloud iam service-accounts create file-reception-pubsub `
  --project project-47695a8e-7cb2-4352-af2 `
  --display-name="File Reception PubSub"

gcloud iam service-accounts create account-core-pubsub `
  --project project-47695a8e-7cb2-4352-af2 `
  --display-name="Account Core PubSub"

gcloud iam service-accounts create clearinghouse-pubsub `
  --project project-47695a8e-7cb2-4352-af2 `
  --display-name="Clearinghouse PubSub"
```

## Permisos IAM de Pub/Sub

File Reception publica y consume:

```powershell
gcloud projects add-iam-policy-binding project-47695a8e-7cb2-4352-af2 `
  --member="serviceAccount:file-reception-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com" `
  --role="roles/pubsub.publisher"

gcloud projects add-iam-policy-binding project-47695a8e-7cb2-4352-af2 `
  --member="serviceAccount:file-reception-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com" `
  --role="roles/pubsub.subscriber"
```

Account Core publica:

```powershell
gcloud projects add-iam-policy-binding project-47695a8e-7cb2-4352-af2 `
  --member="serviceAccount:account-core-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com" `
  --role="roles/pubsub.publisher"
```

Clearinghouse consume:

```powershell
gcloud projects add-iam-policy-binding project-47695a8e-7cb2-4352-af2 `
  --member="serviceAccount:clearinghouse-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com" `
  --role="roles/pubsub.subscriber"
```

## Bindings de Workload Identity

Permitir que cada Kubernetes ServiceAccount use su Google Service Account:

```powershell
gcloud iam service-accounts add-iam-policy-binding `
  account-core-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com `
  --project project-47695a8e-7cb2-4352-af2 `
  --role roles/iam.workloadIdentityUser `
  --member "serviceAccount:project-47695a8e-7cb2-4352-af2.svc.id.goog[banquito-core/account-core-pubsub-ksa]"

gcloud iam service-accounts add-iam-policy-binding `
  file-reception-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com `
  --project project-47695a8e-7cb2-4352-af2 `
  --role roles/iam.workloadIdentityUser `
  --member "serviceAccount:project-47695a8e-7cb2-4352-af2.svc.id.goog[banquito-switch/file-reception-pubsub-ksa]"

gcloud iam service-accounts add-iam-policy-binding `
  clearinghouse-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com `
  --project project-47695a8e-7cb2-4352-af2 `
  --role roles/iam.workloadIdentityUser `
  --member "serviceAccount:project-47695a8e-7cb2-4352-af2.svc.id.goog[banquito-switch/clearinghouse-pubsub-ksa]"
```

## Validaciones

Ver cluster, namespaces y deployments:

```powershell
gcloud container clusters list --project project-47695a8e-7cb2-4352-af2
kubectl get namespaces
kubectl get deployments -A
```

Ver Pub/Sub:

```powershell
gcloud pubsub topics list --project project-47695a8e-7cb2-4352-af2
gcloud pubsub subscriptions list --project project-47695a8e-7cb2-4352-af2
```

Ver que los Pods usaran la ServiceAccount correcta:

```powershell
kubectl describe deployment account-core-service -n banquito-core
kubectl describe deployment file-reception-service -n banquito-switch
kubectl describe deployment clearinghouse-service -n banquito-switch
```

## Validacion ejecutada desde GKE

Fecha de validacion: `2026-07-18`.

Se ejecuto un Pod temporal en el namespace `banquito-switch` usando:

```text
Kubernetes ServiceAccount: file-reception-pubsub-ksa
Google Service Account: file-reception-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com
```

Resultado de autenticacion:

```text
El comando dentro del Pod se autentico como file-reception-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com
```

Prueba realizada:

```text
1. Publicar mensaje en topic banquito-payment-lines.
2. Usar atributo routingKey=onus.
3. Consumir desde subscription payment-lines-onus-sub.
```

Resultado:

```text
messageIds:
- '20592781892587795'

DATA             ATTRIBUTES
test-gke-pubsub  routingKey=onus
                 source=gke-workload-identity-test
```

Interpretacion:

```text
Workload Identity funciona.
El Pod puede publicar en Pub/Sub.
El filtro de subscription por routingKey=onus funciona.
El Pod puede consumir desde la subscription asignada.
```

Observacion:

```text
gcloud pubsub topics list fallo con pubsub.topics.list denegado.
Esto no bloquea la aplicacion porque el microservicio no necesita listar topics.
Por minimo privilegio, file-reception-pubsub conserva solo publisher y subscriber.
```

Al finalizar, el Pod temporal fue eliminado:

```powershell
kubectl delete pod pubsub-wi-test -n banquito-switch
```

Estado final:

```text
banquito-switch: No resources found
```

## Validacion Core -> Pub/Sub -> Clearinghouse

Fecha de validacion: `2026-07-18`.

Objetivo:

```text
account-core-service
  -> banquito-clearing-events
      -> clearing-outbound-sub
          -> clearinghouse-service
```

Se uso un Pod temporal en `banquito-core` con:

```text
Kubernetes ServiceAccount: account-core-pubsub-ksa
Google Service Account: account-core-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com
```

Publicacion realizada:

```text
Topic: banquito-clearing-events
Message: test-core-clearing-event
Attributes:
  routingKey=clearing.outbound
  source=account-core-workload-identity-test
```

Resultado:

```text
messageIds:
- '20593339624516906'
```

Luego se uso un Pod temporal en `banquito-switch` con:

```text
Kubernetes ServiceAccount: clearinghouse-pubsub-ksa
Google Service Account: clearinghouse-pubsub@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com
```

Consumo realizado:

```text
Subscription: clearing-outbound-sub
```

Resultado:

```text
DATA                      ATTRIBUTES
test-core-clearing-event  routingKey=clearing.outbound
                          source=account-core-workload-identity-test
```

Interpretacion:

```text
La identidad de account-core puede publicar eventos de clearing.
La identidad de clearinghouse puede consumir eventos de clearing.
El filtro routingKey=clearing.outbound funciona.
El flujo asincrono que reemplaza RabbitMQ queda validado a nivel infraestructura.
```

Al finalizar, los Pods temporales fueron eliminados:

```powershell
kubectl delete pod pubsub-core-publish-test -n banquito-core
kubectl delete pod pubsub-clearing-pull-test -n banquito-switch
```

Estado final:

```text
banquito-core: No resources found
banquito-switch: No resources found
```

## Migracion de codigo ejecutada

Se migro el codigo Java de los servicios que dependian de RabbitMQ para el flujo asincrono principal:

| Microservicio | Cambio aplicado | Resultado |
| --- | --- | --- |
| `banquito-file-reception-service` | Se reemplazo publicacion/consumo RabbitMQ por publishers/subscribers de Google Pub/Sub. La separacion final queda documentada en `anexo-r-separacion-switch-pubsub.md`. | Pod `1/1 Running` |
| `banquito-clearinghouse-service` | Se reemplazo el listener RabbitMQ por subscriber de Google Pub/Sub sobre `clearing-outbound-sub`. | Pod `1/1 Running` |

Tambien se agrego configuracion explicita de Jackson (`ObjectMapper`) porque Spring Boot 4 no estaba registrando automaticamente el bean requerido por los componentes Pub/Sub.

## Ajuste de runtime Docker

Durante la validacion en GKE, `clearinghouse-service` inicio Pub/Sub pero el runtime Java tuvo un fallo nativo con Netty/OpenSSL:

```text
Problematic frame:
libio_grpc_netty_shaded_netty_tcnative_linux_x86_64...
```

Correccion aplicada en los Dockerfiles de `file-reception-service` y `clearinghouse-service`:

```dockerfile
FROM eclipse-temurin:21-jre
ENV JAVA_TOOL_OPTIONS="-Dio.netty.handler.ssl.noOpenSsl=true"
```

Con esto se evita depender de OpenSSL nativo dentro del contenedor y Pub/Sub usa SSL de Java.

## Commits desplegados por CI/CD

Los cambios fueron subidos a GitHub y desplegados por GitHub Actions hacia GKE:

| Repositorio | Commit | Imagen desplegada |
| --- | --- | --- |
| `banquito-file-reception-service` | `e4aaf39` | `us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/file-reception-service:e4aaf39673bc97b9930fd4bcc40d3726311d4a62` |
| `banquito-clearinghouse-service` | `ce72988` | `us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/clearinghouse-service:ce72988b8a4f1ea1a59d8cba59740fc9b68cfaf5` |

## Validacion en GKE

Comandos ejecutados desde Windows 11:

```powershell
kubectl --insecure-skip-tls-verify=true get deployment file-reception-service clearinghouse-service -n banquito-switch -o wide
kubectl --insecure-skip-tls-verify=true get pods -n banquito-switch -o wide
kubectl --insecure-skip-tls-verify=true logs -n banquito-switch deployment/file-reception-service --tail=120
kubectl --insecure-skip-tls-verify=true logs -n banquito-switch deployment/clearinghouse-service --tail=100
```

Resultado de deployments:

```text
file-reception-service   1/1   AVAILABLE   image: .../file-reception-service:e4aaf39673bc97b9930fd4bcc40d3726311d4a62
clearinghouse-service    1/1   AVAILABLE   image: .../clearinghouse-service:ce72988b8a4f1ea1a59d8cba59740fc9b68cfaf5
```

Resultado de Pods:

```text
clearinghouse-service-867d45b89-8xzf8     1/1   Running   0
file-reception-service-56dd77b65b-q8pgw   1/1   Running   0
```

Evidencia en logs de `file-reception-service`:

```text
Pub/Sub subscriber iniciado para payment-lines-onus-sub
Pub/Sub subscriber iniciado para payment-lines-offus-sub
Pub/Sub subscriber iniciado para payment-lines-invalid-sub
Started BatchApplication
CI/CD backend validation: file-reception-service started
```

Evidencia en logs de `clearinghouse-service`:

```text
Picked up JAVA_TOOL_OPTIONS: -Dio.netty.handler.ssl.noOpenSsl=true
Pub/Sub subscriber iniciado para clearing-outbound-sub
Started BanquitoClearinghouseServiceApplication
CI/CD backend validation: clearinghouse-service started
```

## Estado final

El reemplazo operativo de RabbitMQ por Google Pub/Sub queda validado en GKE para:

```text
file-reception-service
clearinghouse-service
```

La infraestructura Pub/Sub, Workload Identity, CI/CD, Artifact Registry y runtime Kubernetes estan funcionando para estos servicios.


