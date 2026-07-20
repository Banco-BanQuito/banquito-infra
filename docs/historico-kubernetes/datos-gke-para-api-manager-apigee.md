# Datos GKE para configuracion de API Manager Apigee

## Objetivo

Este documento consolida la informacion actual del despliegue Kubernetes en GKE para que el equipo responsable de API Manager configure correctamente los proxies en Apigee.

La finalidad es que Apigee exponga rutas publicas seguras y enrute hacia los microservicios desplegados en GKE.

## Infraestructura GKE actual

| Componente | Valor |
| --- | --- |
| Proyecto GCP de GKE | `project-47695a8e-7cb2-4352-af2` |
| Cluster GKE | `banquito-cluster-east` |
| Region GKE | `us-east1` |
| Tipo de cluster | GKE Autopilot |
| Registro de imagenes | `Artifact Registry` |
| Artifact Registry | `us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito` |

## Namespaces

El despliegue esta separado logicamente en tres namespaces:

| Namespace | Proposito |
| --- | --- |
| `banquito-core` | Microservicios del Core Bancario |
| `banquito-switch` | Microservicios del Switch de Pagos Masivos |
| `banquito-frontend` | Aplicaciones frontend |

## Consideracion importante para Apigee

Los servicios Kubernetes estan definidos como:

```text
type: ClusterIP
```

Esto significa:

```text
Los Services solo son accesibles dentro del cluster Kubernetes.
Apigee no puede invocar directamente un Service ClusterIP.
```

Por lo tanto, Apigee no debe apuntar directamente a:

```text
http://account-core-service.banquito-core.svc.cluster.local:8081
```

Ese DNS es valido dentro del cluster, pero no desde Apigee si Apigee esta fuera de la red interna del cluster.

## Flujo recomendado

El flujo correcto es:

```text
Cliente / Frontend
  -> Apigee
  -> Ingress o Gateway de GKE
  -> Kubernetes Service
  -> Pod del microservicio
```

Representacion:

```text
Apigee
  -> https://<dominio-o-ip-ingress-gke>/api/v2/accounts
  -> account-core-service.banquito-core.svc.cluster.local:8081
```

## Advertencia sobre target anterior

En el documento de Apigee aparece:

```text
Target Endpoint: http://34.27.63.119:8081
```

Ese endpoint debe validarse porque el cluster fue migrado.

El cluster anterior estaba en:

```text
us-central1
```

El cluster actual esta en:

```text
us-east1
```

Por tanto, cualquier IP publica anterior puede haber quedado obsoleta.

El equipo de API Manager debe usar el endpoint publico vigente del Ingress/Gateway/LoadBalancer asociado al nuevo cluster:

```text
banquito-cluster-east
us-east1
```

## Account Core Service

| Campo | Valor |
| --- | --- |
| Deployment | `account-core-service` |
| Namespace | `banquito-core` |
| Service Kubernetes | `account-core-service` |
| Tipo de Service | `ClusterIP` |
| Puerto HTTP | `8081` |
| Puerto gRPC | `9091` |
| DNS interno Kubernetes | `account-core-service.banquito-core.svc.cluster.local` |
| URL interna HTTP | `http://account-core-service.banquito-core.svc.cluster.local:8081` |
| Imagen | `us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest` |

### Ruta sugerida en Apigee

| Campo | Valor sugerido |
| --- | --- |
| Nombre del proxy | `account-core-api` |
| Base Path | `/api/v2/accounts` |
| Target interno logico | `account-core-service.banquito-core.svc.cluster.local:8081` |
| Target real para Apigee | Endpoint publico de Ingress/Gateway de GKE |

Ejemplo conceptual:

```text
https://api.banquito.com/api/v2/accounts
  -> Apigee
  -> https://<ingress-gke>/api/v2/accounts
  -> account-core-service:8081
```

## Microservicios Core Bancario

| Microservicio | Namespace | Service | Tipo | HTTP | gRPC | DNS interno |
| --- | --- | --- | --- | ---: | ---: | --- |
| Account Core | `banquito-core` | `account-core-service` | `ClusterIP` | `8081` | `9091` | `account-core-service.banquito-core.svc.cluster.local` |
| Accounting | `banquito-core` | `accounting-service` | `ClusterIP` | `8082` | `9092` | `accounting-service.banquito-core.svc.cluster.local` |
| Party | `banquito-core` | `party-service` | `ClusterIP` | `8083` | `9093` | `party-service.banquito-core.svc.cluster.local` |

## Microservicios Switch de Pagos Masivos

| Microservicio | Namespace | Service | Tipo | HTTP | gRPC | DNS interno |
| --- | --- | --- | --- | ---: | ---: | --- |
| File Reception | `banquito-switch` | `file-reception-service` | `ClusterIP` | `8084` | n/a | `file-reception-service.banquito-switch.svc.cluster.local` |
| Tariff | `banquito-switch` | `tariff-service` | `ClusterIP` | `8086` | `9090` | `tariff-service.banquito-switch.svc.cluster.local` |
| Clearinghouse | `banquito-switch` | `clearinghouse-service` | `ClusterIP` | `8087` | n/a | `clearinghouse-service.banquito-switch.svc.cluster.local` |
| Report | `banquito-switch` | `report-service` | `ClusterIP` | `8088` | n/a | `report-service.banquito-switch.svc.cluster.local` |
| Notification | `banquito-switch` | `notification-service` | `ClusterIP` | `8089` | `9092` | `notification-service.banquito-switch.svc.cluster.local` |

## Frontends

| Frontend | Namespace | Service | Tipo | HTTP | DNS interno |
| --- | --- | --- | --- | ---: | --- |
| Teller | `banquito-frontend` | `teller-frontend` | `ClusterIP` | `8080` | `teller-frontend.banquito-frontend.svc.cluster.local` |
| Web Personas | `banquito-frontend` | `web-personas-frontend` | `ClusterIP` | `8080` | `web-personas-frontend.banquito-frontend.svc.cluster.local` |
| Web Empresas | `banquito-frontend` | `web-empresas-frontend` | `ClusterIP` | `8080` | `web-empresas-frontend.banquito-frontend.svc.cluster.local` |
| Operador | `banquito-frontend` | `operador-frontend` | `ClusterIP` | `8080` | `operador-frontend.banquito-frontend.svc.cluster.local` |

## Rutas sugeridas para Apigee

### Core Bancario

| Ruta publica sugerida | Backend Kubernetes |
| --- | --- |
| `/api/v2/accounts/**` | `account-core-service.banquito-core.svc.cluster.local:8081` |
| `/api/v2/accounting/**` | `accounting-service.banquito-core.svc.cluster.local:8082` |
| `/api/v2/parties/**` | `party-service.banquito-core.svc.cluster.local:8083` |

### Switch de Pagos Masivos

| Ruta publica sugerida | Backend Kubernetes |
| --- | --- |
| `/api/v2/files/**` | `file-reception-service.banquito-switch.svc.cluster.local:8084` |
| `/api/v2/tariffs/**` | `tariff-service.banquito-switch.svc.cluster.local:8086` |
| `/api/v2/clearing/**` | `clearinghouse-service.banquito-switch.svc.cluster.local:8087` |
| `/api/v2/reports/**` | `report-service.banquito-switch.svc.cluster.local:8088` |
| `/api/v2/notifications/**` | `notification-service.banquito-switch.svc.cluster.local:8089` |

## Configuracion OAuth/JWT recibida

La configuracion JWT indicada por el equipo de API Manager esta alineada con el proyecto GKE:

```xml
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<VerifyJWT async="false" continueOnError="false" enabled="true" name="Verify-OAuth2-Token">
    <DisplayName>Verify OAuth2 Token</DisplayName>
    <Algorithm>RS256</Algorithm>
    <Source>request.header.Authorization</Source>
    <IgnoreUnresolvedVariables>false</IgnoreUnresolvedVariables>

    <PublicKey>
        <JWKS uri="https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"/>
    </PublicKey>

    <Issuer>https://securetoken.google.com/project-47695a8e-7cb2-4352-af2</Issuer>
    <Audience>project-47695a8e-7cb2-4352-af2</Audience>
</VerifyJWT>
```

Valores relevantes:

| Campo | Valor |
| --- | --- |
| Issuer | `https://securetoken.google.com/project-47695a8e-7cb2-4352-af2` |
| Audience | `project-47695a8e-7cb2-4352-af2` |
| JWKS | `https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com` |
| Algoritmo | `RS256` |
| Header esperado | `Authorization: Bearer <token>` |

## Variables de configuracion actuales

El `ConfigMap` de Kubernetes contiene placeholders para API Manager:

```yaml
API_MANAGER_URL: https://api.example.com
CORE_GATEWAY_URL: https://api.example.com/core
SWITCH_GATEWAY_URL: https://api.example.com/switch
OAUTH_URL: https://oauth.example.com
```

Cuando Apigee tenga dominio final, se debe actualizar a valores reales. Ejemplo:

```yaml
API_MANAGER_URL: https://136.68.89.25.nip.io
CORE_GATEWAY_URL: https://136.68.89.25.nip.io/core
SWITCH_GATEWAY_URL: https://136.68.89.25.nip.io/switch
OAUTH_URL: https://securetoken.google.com/project-47695a8e-7cb2-4352-af2
```

Archivo:

```text
banquito-infra/k8s/configmap.yaml
```

Aplicar:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply -f configmap.yaml
```

## Comandos de verificacion para el equipo de infraestructura

Ver servicios Core:

```powershell
kubectl get svc -n banquito-core
```

Ver servicios Switch:

```powershell
kubectl get svc -n banquito-switch
```

Ver frontends:

```powershell
kubectl get svc -n banquito-frontend
```

Ver Pods:

```powershell
kubectl get pods -n banquito-core
kubectl get pods -n banquito-switch
kubectl get pods -n banquito-frontend
```

Ver detalle del Service `account-core-service`:

```powershell
kubectl describe svc account-core-service -n banquito-core
```

Ver detalle del Deployment:

```powershell
kubectl describe deployment account-core-service -n banquito-core
```

## Mensaje clave para API Manager

```text
El target endpoint de Apigee no debe apuntar directamente a un Kubernetes Service tipo ClusterIP. Se requiere exponer los backends mediante un Ingress/Gateway o LoadBalancer del cluster GKE actual en us-east1. Apigee debe apuntar a ese endpoint publico/controlado, y el Ingress/Gateway enruta internamente hacia account-core-service.banquito-core.svc.cluster.local:8081.
```

## Estado pendiente

Pendientes para completar integracion Apigee -> GKE:

```text
1. Definir si se usara GKE Ingress, Gateway API o LoadBalancer.
2. Obtener dominio/IP publica del endpoint de entrada del cluster en us-east1.
3. Actualizar el Target Endpoint de Apigee con ese endpoint vigente.
4. Confirmar que el backend account-core-service este Running y Ready.
5. Confirmar que los Secrets reales de base de datos esten configurados.
6. Probar llamada externa:
   Cliente -> Apigee -> Ingress/Gateway GKE -> account-core-service.
```
