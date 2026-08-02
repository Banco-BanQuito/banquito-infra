# Anexo U - GKE Autopilot con namespaces separados para Pub/Sub

## Decision

Se retoma Google Kubernetes Engine en modo Autopilot para desplegar los backends de BanQuito.

El cluster Standard se mantiene como referencia tecnica, pero para la demo y operacion se usa Autopilot porque reduce la administracion manual de nodos y permite concentrarse en Pods, Deployments, Services, HPA, Gateway y namespaces.

## Cluster creado

| Campo | Valor |
| --- | --- |
| Cluster | `banquito-cluster-autopilot` |
| Modo | GKE Autopilot |
| Region | `us-east1` |
| Version | `1.35.6-gke.1250000` |
| Endpoint API server | `34.24.83.92` |
| Gateway publico | `8.233.141.65` |
| Estado | `RUNNING` |

## Organizacion de namespaces

| Namespace | Responsabilidad |
| --- | --- |
| `banquito-core` | Microservicios del Core Bancario. |
| `banquito-switch` | Microservicios de dominio del Switch de Pagos Masivos. |
| `banquito-pubsub` | Adaptadores tecnicos que publican o consumen mensajes desde Google Pub/Sub. |
| `banquito-gateway` | Gateway publico de GKE usado como Target Endpoint de Apigee. |

La separacion importante es `banquito-pubsub`.

Antes, los servicios relacionados con Pub/Sub estaban dentro de `banquito-switch`. Ahora:

| Servicio | Namespace | Motivo |
| --- | --- | --- |
| `payment-line-publisher-service` | `banquito-pubsub` | Publica lineas clasificadas hacia Google Pub/Sub. |
| `payment-line-subscriber-service` | `banquito-pubsub` | Consume mensajes desde Google Pub/Sub y delega al flujo correspondiente. |
| `payment-line-classifier-service` | `banquito-switch` | Clasifica lineas como parte del dominio de pagos, no del transporte. |

## Flujo logico

```text
file-reception-service
  -> payment-line-classifier-service
  -> payment-line-publisher-service
  -> Google Pub/Sub
  -> payment-line-subscriber-service
       -> ON-US / INVALID: procesamiento interno
       -> OFF-US: clearinghouse-service por gRPC
```

## Comandos usados

Crear cluster Autopilot:

```powershell
gcloud container clusters create-auto banquito-cluster-autopilot `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2 `
  --release-channel regular `
  --enable-secret-manager
```

Obtener credenciales:

```powershell
gcloud container clusters get-credentials banquito-cluster-autopilot `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2
```

Habilitar Gateway API:

```powershell
gcloud container clusters update banquito-cluster-autopilot `
  --region us-east1 `
  --gateway-api=standard `
  --project project-47695a8e-7cb2-4352-af2
```

Habilitar Secret Sync:

```powershell
gcloud beta container clusters update banquito-cluster-autopilot `
  --region us-east1 `
  --enable-secret-sync `
  --project project-47695a8e-7cb2-4352-af2
```

Aplicar namespaces, ConfigMaps y ServiceAccounts:

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\namespace.yaml
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\configmap.yaml
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\pubsub-serviceaccounts.yaml
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\secret-manager-serviceaccounts.yaml
```

Aplicar workloads backend:

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\account-core
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\accounting
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\party
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\file-reception
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\payment-line-classifier
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\payment-line-publisher
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\payment-line-subscriber
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\clearinghouse
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\tariff
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\report
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\notification
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\gateway
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\hpa
```

No se aplico `k8s/secret.yaml` porque contiene placeholders. Los secretos reales se crearon desde Google Secret Manager.

## Identidades Pub/Sub

Se separaron las identidades tecnicas:

| Kubernetes ServiceAccount | Namespace | Google Service Account | Rol |
| --- | --- | --- | --- |
| `payment-line-publisher-pubsub-ksa` | `banquito-pubsub` | `payment-line-publisher-pubsub@...` | `roles/pubsub.publisher` |
| `payment-line-subscriber-pubsub-ksa` | `banquito-pubsub` | `payment-line-subscriber-pubsub@...` | `roles/pubsub.subscriber` |

Esto permite defender minimo privilegio:

- el publicador solo puede publicar;
- el suscriptor solo puede consumir;
- no se usan archivos JSON dentro de los Pods.

## Secrets

La fuente oficial de secretos sigue siendo Google Secret Manager.

Para que los Deployments arranquen, se crearon Kubernetes Secrets nativos leyendo valores desde Secret Manager:

| Namespace | Secret Kubernetes | Uso |
| --- | --- | --- |
| `banquito-core` | `account-core-secrets` | PostgreSQL Core |
| `banquito-core` | `accounting-secrets` | PostgreSQL Accounting |
| `banquito-core` | `party-secrets` | MySQL Party |
| `banquito-switch` | `file-reception-secrets` | MySQL File + Mongo |
| `banquito-pubsub` | `file-reception-secrets` | MySQL File + Mongo para publisher/subscriber |
| `banquito-switch` | `tariff-secrets` | MySQL Tariff |
| `banquito-switch` | `mongo-services-secrets` | MongoDB para reportes, clearing y notificaciones |
| `banquito-switch` | `notification-secrets` | SMTP |

## Ajustes realizados

1. Se agrego el namespace `banquito-pubsub`.
2. `payment-line-publisher-service` se movio a `banquito-pubsub`.
3. `payment-line-subscriber-service` se movio a `banquito-pubsub`.
4. Los HPA de publisher/subscriber se movieron a `banquito-pubsub`.
5. Se actualizaron los DNS internos:

```text
payment-line-publisher-service.banquito-pubsub.svc.cluster.local
payment-line-subscriber-service.banquito-pubsub.svc.cluster.local
```

6. Se agrego un `ConfigMap` `banquito-config` en `banquito-pubsub`.
7. Se corrigio `tariff-secrets` agregando variables `POSTGRES_URL`, `POSTGRES_USER` y `POSTGRES_PASSWORD`, porque la aplicacion las espera para conectarse a MySQL.
8. Se aumento el `startupProbe` de `party-service` y `tariff-service` a 20 minutos para evitar reinicios prematuros en arranques lentos contra servicios cloud.

## Validacion final

Core:

```text
account-core-service   1/1 Running
accounting-service     1/1 Running
party-service          1/1 Running
```

Switch:

```text
clearinghouse-service             1/1 Running
file-reception-service            1/1 Running
notification-service              1/1 Running
payment-line-classifier-service   1/1 Running
report-service                    1/1 Running
tariff-service                    1/1 Running
```

Pub/Sub:

```text
payment-line-publisher-service    1/1 Running
payment-line-subscriber-service   1/1 Running
```

HPA:

```text
banquito-core       min 1 / max 3
banquito-switch     min 1 / max 3
banquito-pubsub     min 1 / max 3
```

Gateway:

```text
banquito-public-gateway   8.233.141.65   Programmed=True
```

## Nota para Apigee

El Target Endpoint de Apigee debe apuntar al Gateway publico de GKE:

```text
http://8.233.141.65
```

Apigee sigue siendo la entrada publica de APIs:

```text
Frontend VM
  -> Apigee
  -> GKE Gateway
  -> Services ClusterIP
  -> Pods backend
```

