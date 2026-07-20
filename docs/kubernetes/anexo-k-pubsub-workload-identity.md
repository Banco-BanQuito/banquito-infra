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

Nota: las variables RabbitMQ se mantienen temporalmente porque el codigo Java actual todavia contiene dependencias y listeners Rabbit. Se retiraran cuando la migracion de codigo termine.

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

## Pendiente de codigo

La infraestructura ya queda preparada para Pub/Sub, pero los microservicios todavia deben cambiar codigo:

```text
1. Remover spring-boot-starter-amqp donde ya no aplique.
2. Agregar google-cloud-pubsub.
3. Reemplazar RabbitTemplate por Publisher de Pub/Sub.
4. Reemplazar @RabbitListener por Subscriber de Pub/Sub.
5. Leer topics/subscriptions desde variables de entorno.
6. Reconstruir imagenes Docker.
7. Ejecutar CI/CD.
8. Desplegar en GKE.
```

Mientras ese cambio no se haga, `file-reception-service` y `clearinghouse-service` pueden seguir intentando conectarse a RabbitMQ porque el codigo actual aun contiene listeners Rabbit.
