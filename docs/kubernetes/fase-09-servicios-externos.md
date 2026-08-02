# FASE 9 - Integracion con servicios externos

## Objetivo

Conectar los microservicios con servicios administrados o externos: Apigee, OAuth, Cloud SQL, MongoDB, Pub/Sub y SMTP.

## Servicios configurados o esperados

| Necesidad | Servicio |
| --- | --- |
| API Manager | Apigee |
| OAuth/JWT | Google Identity Platform / Firebase Secure Token |
| PostgreSQL | Cloud SQL PostgreSQL |
| MySQL | Cloud SQL MySQL |
| MongoDB | MongoDB Atlas |
| Mensajeria asincrona | Google Cloud Pub/Sub |
| SMTP | Servicio externo |
| Baul de secretos | Google Secret Manager |

## Endpoints conocidos

| Servicio | Endpoint |
| --- | --- |
| Apigee | `https://136.68.89.25.nip.io` |
| PostgreSQL | `136.112.87.173:5432` |
| MySQL | `136.111.132.119:3306` |
| MongoDB | `banquito-cluster.ffdlgoy.mongodb.net` |
| Pub/Sub | `project-47695a8e-7cb2-4352-af2` |

## OAuth / JWT

Issuer:

```text
https://securetoken.google.com/project-47695a8e-7cb2-4352-af2
```

Audience:

```text
project-47695a8e-7cb2-4352-af2
```

JWKS:

```text
https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
```

## Baul de secretos

El requisito no se debe justificar solo con `Kubernetes Secret`. La fuente oficial de credenciales debe ser Google Secret Manager, que cumple el rol de Key Vault en Google Cloud.

Modelo correcto:

```text
Google Secret Manager
  -> GKE
      -> Kubernetes Secret o volumen CSI
          -> Pod
```

`ConfigMap` se usa solo para datos no sensibles como hosts, puertos, nombres de servicio y URLs publicas.

`Kubernetes Secret` se usa como mecanismo de inyeccion al Pod, pero no como baul maestro.

Ver detalle operativo:

```text
anexo-i-secret-manager-key-vault.md
```

## Secrets reales en Kubernetes

No guardar passwords reales en Git.

Validar si hay placeholders:

```powershell
$namespaces='banquito-core','banquito-switch','banquito-frontend'
foreach ($ns in $namespaces) {
  Write-Host "==== $ns ===="
  $secret = kubectl get secret banquito-secrets -n $ns -o json | ConvertFrom-Json
  foreach ($key in 'DB_USER','DB_PASS','POSTGRES_USER','POSTGRES_PASSWORD','MONGO_URI','RABBITMQ_USERNAME','RABBITMQ_PASSWORD') {
    $raw = $secret.data.$key
    if ($null -eq $raw) { Write-Host "$key=MISSING"; continue }
    $value = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($raw))
    Write-Host "$key placeholder=$($value -like 'replace-with-*') length=$($value.Length)"
  }
}
```

Crear Secrets reales:

```powershell
$cloudPass = Read-Host "Cloud SQL password"
$mongoPass = Read-Host "MongoDB password"
$rabbitPass = Read-Host "RabbitMQ password"
$smtpPass = Read-Host "SMTP password"

$namespaces = 'banquito-core','banquito-switch','banquito-frontend'
foreach ($namespace in $namespaces) {
  kubectl create secret generic banquito-secrets `
    --namespace $namespace `
    --from-literal=DB_URL="jdbc:postgresql://136.112.87.173:5432/banquito" `
    --from-literal=DB_USER="postgres" `
    --from-literal=DB_PASS="$cloudPass" `
    --from-literal=POSTGRES_URL="jdbc:mysql://136.111.132.119:3306/tariffdb" `
    --from-literal=POSTGRES_USER="root" `
    --from-literal=POSTGRES_PASSWORD="$cloudPass" `
    --from-literal=MONGO_URI="mongodb+srv://banquito:$mongoPass@banquito-cluster.ffdlgoy.mongodb.net/banquito" `
    --from-literal=MONGODB_URI="mongodb+srv://banquito:$mongoPass@banquito-cluster.ffdlgoy.mongodb.net/banquito" `
    --from-literal=SPRING_DATA_MONGODB_URI="mongodb+srv://banquito:$mongoPass@banquito-cluster.ffdlgoy.mongodb.net/banquito" `
    --from-literal=RABBITMQ_USERNAME="banquito" `
    --from-literal=RABBITMQ_PASSWORD="$rabbitPass" `
    --from-literal=SPRING_RABBITMQ_USERNAME="banquito" `
    --from-literal=SPRING_RABBITMQ_PASSWORD="$rabbitPass" `
    --from-literal=SMTP_USER="" `
    --from-literal=SMTP_PASS="$smtpPass" `
    --dry-run=client -o yaml | kubectl apply -f -
}
```

## Migracion RabbitMQ a Pub/Sub

Fecha de decision: `2026-07-18`.

RabbitMQ deja de ser el broker objetivo. La mensajeria asincrona se migra a Google Cloud Pub/Sub.

Subscriptions informadas:

```text
payment-lines-onus-sub
payment-lines-offus-sub
payment-lines-invalid-sub
clearing-outbound-sub
dead-letter-monitor-sub
```

Topics reales verificados:

```text
banquito-payment-lines
banquito-clearing-events
banquito-dead-letter
```

Las subscriptions de lineas usan filtros por atributo `routingKey`:

```text
onus
offus
invalid
clearing.outbound
```

Se agrego infraestructura Kubernetes para Workload Identity:

```text
k8s/pubsub-serviceaccounts.yaml
```

ServiceAccounts:

```text
account-core-pubsub-ksa
file-reception-pubsub-ksa
clearinghouse-pubsub-ksa
```

Se agregaron variables Pub/Sub no sensibles al ConfigMap:

```text
PUBSUB_PROJECT_ID
PUBSUB_TOPIC_PAYMENT_LINES_ONUS
PUBSUB_TOPIC_PAYMENT_LINES_OFFUS
PUBSUB_TOPIC_PAYMENT_LINES_INVALID
PUBSUB_TOPIC_CLEARING_OUTBOUND
PUBSUB_SUBSCRIPTION_PAYMENT_LINES_ONUS
PUBSUB_SUBSCRIPTION_PAYMENT_LINES_OFFUS
PUBSUB_SUBSCRIPTION_PAYMENT_LINES_INVALID
PUBSUB_SUBSCRIPTION_CLEARING_OUTBOUND
PUBSUB_SUBSCRIPTION_DEAD_LETTER_MONITOR
```

Ver detalle operativo:

```text
anexo-k-pubsub-workload-identity.md
```

## Estado observado

Los Pods llegaron a programarse y descargar imagenes, pero varios quedaron en `CrashLoopBackOff` por credenciales invalidas o placeholders en Secrets.

## Aplicacion realizada: Secret Manager hacia Kubernetes

Fecha de aplicacion: `2026-07-17`.

Se valido que los secretos ya estaban creados en Google Secret Manager:

```powershell
gcloud secrets list --project project-47695a8e-7cb2-4352-af2

gcloud secrets versions list banquito-postgres-password --project project-47695a8e-7cb2-4352-af2
gcloud secrets versions list banquito-mysql-password --project project-47695a8e-7cb2-4352-af2
gcloud secrets versions list banquito-mongo-uri --project project-47695a8e-7cb2-4352-af2
```

Secretos encontrados en Secret Manager:

```text
banquito-postgres-url
banquito-postgres-user
banquito-postgres-password
banquito-mysql-party-url
banquito-mysql-file-url
banquito-mysql-tariff-url
banquito-mysql-user
banquito-mysql-password
banquito-mongo-uri
```

Luego se sincronizaron hacia Kubernetes Secrets por microservicio:

| Namespace | Kubernetes Secret | Microservicio |
| --- | --- | --- |
| `banquito-core` | `account-core-secrets` | `account-core-service` |
| `banquito-core` | `accounting-secrets` | `accounting-service` |
| `banquito-core` | `party-secrets` | `party-service` |
| `banquito-switch` | `file-reception-secrets` | `file-reception-service` |
| `banquito-switch` | `tariff-secrets` | `tariff-service` |
| `banquito-switch` | `mongo-services-secrets` | `clearinghouse-service`, `report-service`, `notification-service` |

Comando base utilizado para crear cada Kubernetes Secret desde valores obtenidos de Secret Manager:

```powershell
$PROJECT_ID = "project-47695a8e-7cb2-4352-af2"

$PG_URL = gcloud secrets versions access latest --secret=banquito-postgres-url --project $PROJECT_ID
$PG_USER = gcloud secrets versions access latest --secret=banquito-postgres-user --project $PROJECT_ID
$PG_PASS = gcloud secrets versions access latest --secret=banquito-postgres-password --project $PROJECT_ID

$MYSQL_PARTY_URL = gcloud secrets versions access latest --secret=banquito-mysql-party-url --project $PROJECT_ID
$MYSQL_FILE_URL = gcloud secrets versions access latest --secret=banquito-mysql-file-url --project $PROJECT_ID
$MYSQL_TARIFF_URL = gcloud secrets versions access latest --secret=banquito-mysql-tariff-url --project $PROJECT_ID
$MYSQL_USER = gcloud secrets versions access latest --secret=banquito-mysql-user --project $PROJECT_ID
$MYSQL_PASS = gcloud secrets versions access latest --secret=banquito-mysql-password --project $PROJECT_ID

$MONGO_URI = gcloud secrets versions access latest --secret=banquito-mongo-uri --project $PROJECT_ID
```

Ejemplo aplicado para `account-core-service`:

```powershell
kubectl create secret generic account-core-secrets `
  -n banquito-core `
  --from-literal=DB_URL=$PG_URL `
  --from-literal=DB_USER=$PG_USER `
  --from-literal=DB_PASS=$PG_PASS `
  --from-literal=POSTGRES_URL=$PG_URL `
  --from-literal=POSTGRES_USER=$PG_USER `
  --from-literal=POSTGRES_PASSWORD=$PG_PASS `
  --dry-run=client -o yaml | kubectl apply -f -
```

Se actualizaron los Deployments backend para dejar de usar el Secret generico `banquito-secrets` y usar Secrets especificos:

```text
account-core-service      -> account-core-secrets
accounting-service        -> accounting-secrets
party-service             -> party-secrets
file-reception-service    -> file-reception-secrets
tariff-service            -> tariff-secrets
clearinghouse-service     -> mongo-services-secrets
report-service            -> mongo-services-secrets
notification-service      -> mongo-services-secrets
```

### Notification Service y SMTP

Fecha de aplicacion: `2026-07-25`.

Se reviso `notification-service` y se confirmo su responsabilidad:

| Responsabilidad | Detalle |
| --- | --- |
| Envio de notificaciones | Recibe solicitudes de notificacion por HTTP/gRPC y construye el mensaje. |
| Auditoria | Registra en MongoDB el resultado de la notificacion. |
| Modo simulacion | Si `SMTP_ENABLED=false`, no envia correo real; registra la notificacion como simulada/enviada para pruebas. |
| Modo SMTP real | Si `SMTP_ENABLED=true`, usa `JavaMailSender` y las credenciales SMTP para enviar el correo. |

Variables requeridas por el servicio:

```text
SMTP_HOST
SMTP_PORT
SMTP_USER
SMTP_PASS
SMTP_FROM
SMTP_ENABLED
```

Estas variables ya no deben depender del `ConfigMap`, porque contienen credenciales o controlan integracion externa. Se crearon en Google Secret Manager:

```text
banquito-smtp-host
banquito-smtp-port
banquito-smtp-user
banquito-smtp-password
banquito-smtp-from
banquito-smtp-enabled
```

Y se sincronizaron al namespace `banquito-switch` como:

```text
notification-secrets
```

El Deployment `notification-service` ahora consume:

| Secret Kubernetes | Uso |
| --- | --- |
| `mongo-services-secrets` | URI MongoDB Atlas para auditoria |
| `notification-secrets` | Configuracion SMTP |

Comandos utilizados:

```powershell
$PROJECT_ID='project-47695a8e-7cb2-4352-af2'

gcloud secrets list --project $PROJECT_ID --filter='name:banquito-smtp'

$SMTP_HOST = gcloud secrets versions access latest --secret=banquito-smtp-host --project $PROJECT_ID
$SMTP_PORT = gcloud secrets versions access latest --secret=banquito-smtp-port --project $PROJECT_ID
$SMTP_USER = gcloud secrets versions access latest --secret=banquito-smtp-user --project $PROJECT_ID
$SMTP_PASS = gcloud secrets versions access latest --secret=banquito-smtp-password --project $PROJECT_ID
$SMTP_FROM = gcloud secrets versions access latest --secret=banquito-smtp-from --project $PROJECT_ID
$SMTP_ENABLED = gcloud secrets versions access latest --secret=banquito-smtp-enabled --project $PROJECT_ID

kubectl --insecure-skip-tls-verify=true create secret generic notification-secrets `
  -n banquito-switch `
  --from-literal=SMTP_HOST=$SMTP_HOST `
  --from-literal=SMTP_PORT=$SMTP_PORT `
  --from-literal=SMTP_USER=$SMTP_USER `
  --from-literal=SMTP_PASS=$SMTP_PASS `
  --from-literal=SMTP_FROM=$SMTP_FROM `
  --from-literal=SMTP_ENABLED=$SMTP_ENABLED `
  --dry-run=client -o yaml | kubectl --insecure-skip-tls-verify=true apply -f -

kubectl --insecure-skip-tls-verify=true apply -f .\banquito-infra\k8s\notification\deployment.yaml
kubectl --insecure-skip-tls-verify=true rollout restart deployment/notification-service -n banquito-switch
kubectl --insecure-skip-tls-verify=true describe pod -n banquito-switch -l app=notification
kubectl --insecure-skip-tls-verify=true logs -n banquito-switch deployment/notification-service --tail=160
```

Resultado validado:

```text
notification-service Ready=True
MongoDB Atlas conectado
gRPC Server iniciado en puerto 9092
Variables SMTP tomadas desde notification-secrets
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=notificacionbanquito@gmail.com
SMTP_FROM=notificacionbanquito@gmail.com
SMTP_ENABLED=true
```

Se aplicaron los Deployments actualizados:

```powershell
kubectl apply -f .\account-core\deployment.yaml
kubectl apply -f .\accounting\deployment.yaml
kubectl apply -f .\party\deployment.yaml
kubectl apply -f .\file-reception\deployment.yaml
kubectl apply -f .\tariff\deployment.yaml
kubectl apply -f .\clearinghouse\deployment.yaml
kubectl apply -f .\report\deployment.yaml
kubectl apply -f .\notification\deployment.yaml
```

Para evitar consumo despues de la validacion, se apagaron los backends:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-switch
```

Verificacion final:

```powershell
kubectl get secret -n banquito-core
kubectl get secret -n banquito-switch
kubectl get deploy -n banquito-core
kubectl get deploy -n banquito-switch
```

Resultado esperado:

```text
banquito-core:   Deployments 0/0
banquito-switch: Deployments 0/0
```

## Integracion de clearing con banco externo

Se agrego la configuracion para que `clearinghouse-service` pueda conectarse a un banco externo de prueba llamado BanQuil.

La configuracion no sensible queda en `ConfigMap`:

```text
BANQUITO_ROUTING_CODE
BANQUIL_BANK_CODE
BANQUIL_ROUTING_CODES
BANQUIL_ENDPOINT_URL
BANQUIL_API_KEY_HEADER_NAME
BANQUIL_TIMEOUT_SECONDS
```

Las credenciales quedan en Google Secret Manager y se sincronizan como Kubernetes Secret:

```text
external-bank-secrets
```

Variables sensibles:

```text
BANQUIL_API_KEY
BANQUIL_BEARER_TOKEN
```

Documento detallado:

```text
docs/kubernetes/anexo-x-clearing-banco-externo-secret-manager.md
```

## Validacion por bloques

Fecha de validacion: `2026-07-17`.

Para evitar que GKE Autopilot deje Pods en `Pending` por falta temporal de capacidad, la validacion se realizo encendiendo un microservicio a la vez.

### Comandos base

Apagar todos los backends antes de cada bloque:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-switch
```

Encender un microservicio:

```powershell
kubectl scale deployment <deployment> --replicas=1 -n <namespace>
kubectl get pods -n <namespace> -o wide
kubectl logs -n <namespace> deployment/<deployment> --tail=120
```

Apagar el microservicio validado:

```powershell
kubectl scale deployment <deployment> --replicas=0 -n <namespace>
```

### Resultados

| Microservicio | Namespace | Dependencia validada | Resultado |
| --- | --- | --- | --- |
| `party-service` | `banquito-core` | MySQL `partydb`, gRPC `9093` | `1/1 Running` |
| `tariff-service` | `banquito-switch` | MySQL `tariffdb` | `1/1 Running` |
| `account-core-service` | `banquito-core` | PostgreSQL `banquito` | `1/1 Running` |
| `accounting-service` | `banquito-core` | PostgreSQL `banquito` | `1/1 Running` |
| `file-reception-service` | `banquito-switch` | MySQL `filedb`, MongoDB Atlas, Pub/Sub | MySQL, MongoDB y Pub/Sub como objetivo cloud |
| `report-service` | `banquito-switch` | MongoDB Atlas | `1/1 Running` |

### Evidencia tecnica observada

`party-service`:

```text
Database JDBC URL [jdbc:mysql://136.111.132.119:3306/partydb]
Party gRPC server started on port 9093
READY 1/1
```

`tariff-service`:

```text
Database JDBC URL [jdbc:mysql://136.111.132.119:3306/tariffdb]
READY 1/1
```

`account-core-service`:

```text
READY 1/1
```

`accounting-service`:

```text
Database JDBC URL [jdbc:postgresql://136.112.87.173:5432/banquito]
READY 1/1
```

`file-reception-service`:

```text
Database JDBC URL [jdbc:mysql://136.111.132.119:3306/filedb]
MongoDB Atlas connected
Attempting to connect to: [35.184.45.161:5672]
Broker not available: java.net.SocketTimeoutException: Connect timed out
```

`report-service`:

```text
MongoDB Atlas connected
Started ReportServiceApplication
READY 1/1
```

### Conclusiones de la validacion

Las credenciales cargadas desde Secret Manager y sincronizadas hacia Kubernetes Secrets funcionan para:

```text
PostgreSQL
MySQL
MongoDB Atlas
```

La dependencia RabbitMQ ya no se mantiene como objetivo de arquitectura:

```text
RabbitMQ legacy -> reemplazo por Google Cloud Pub/Sub
```

El flujo principal del Switch ya queda orientado a Pub/Sub. La separacion final de responsabilidades queda documentada en `anexo-r-separacion-switch-pubsub.md`: recepcion, router publisher, subscriber ON-US/INVALID y subscriber OFF-US.

Al finalizar la prueba, los backends quedaron apagados para evitar consumo:

```text
banquito-core:   0/0
banquito-switch: 0/0
```

## Entregable

Microservicios conectados correctamente a servicios externos y Pods `Running/Ready`.

