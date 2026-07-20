# Fase 6 - Deployments y Services Kubernetes

## Objetivo

Crear los manifiestos base de Kubernetes para ejecutar las aplicaciones BanQuito en Google Kubernetes Engine.

En esta fase se crearon:

- `deployment.yaml` por servicio.
- `service.yaml` por servicio.
- `configmap.yaml` compartido.
- `secret.yaml` compartido.

No se desplego nada en GKE.

## Convenciones aplicadas

- Namespace: `banquito`.
- Replicas por Deployment: `2`.
- Estrategia inicial: `RollingUpdate`.
- Estrategia ajustada para demo en GKE Autopilot: `Recreate`.
- Services: `ClusterIP`.
- Imagenes: placeholders de Artifact Registry.
- Variables no sensibles: `ConfigMap` `banquito-config`.
- Variables sensibles: `Secret` `banquito-secrets`.
- Backends: probes HTTP sobre `/actuator/health`.
- Frontends: probes HTTP sobre `/`.

## Imagenes Artifact Registry

Las imagenes quedaron con este patron:

```text
us-central1-docker.pkg.dev/PROJECT_ID/banquito/<image-name>:latest
```

Antes de desplegar se debe reemplazar:

- `PROJECT_ID`
- region si no se usa `us-central1`
- repositorio si no se llama `banquito`
- tag si no se usa `latest`

## Manifiestos creados

| Carpeta | Deployment | Service | Puertos Service |
| --- | --- | --- | --- |
| `account-core` | `account-core-service` | `account-core-service` | 8081, 9091 |
| `accounting` | `accounting-service` | `accounting-service` | 8082, 9092 |
| `party` | `party-service` | `party-service` | 8083, 9093 |
| `file-reception` | `file-reception-service` | `file-reception-service` | 8084 |
| `tariff` | `tariff-service` | `tariff-service` | 8086, 9090 |
| `notification` | `notification-service` | `notification-service` | 8089, 9092 |
| `report` | `report-service` | `report-service` | 8088 |
| `clearinghouse` | `clearinghouse-service` | `clearinghouse-service` | 8087 |
| `teller` | `teller-frontend` | `teller-frontend` | 8080 |
| `personas` | `web-personas-frontend` | `web-personas-frontend` | 8080 |
| `empresas` | `web-empresas-frontend` | `web-empresas-frontend` | 8080 |
| `operador` | `operador-frontend` | `operador-frontend` | 8080 |

## Por que algunos Services exponen gRPC

Aunque el ejemplo inicial de `account-core-service` solo mencionaba el puerto HTTP 8081, se incluyeron puertos gRPC donde la aplicacion los necesita.

Esto es necesario para las llamadas internas:

- `account-core-service` -> `accounting-service:9092`
- `account-core-service` -> `party-service:9093`
- `party-service` -> `account-core-service:9091`
- `file-reception-service` -> `tariff-service:9090`
- `file-reception-service` -> `notification-service:9092`

Si esos puertos no estan en el Service, los Pods no podran comunicarse por gRPC usando DNS interno de Kubernetes.

## Archivos compartidos

### ConfigMap

Archivo:

```text
k8s/configmap.yaml
```

Nombre:

```text
banquito-config
```

Contiene variables no sensibles, como puertos, nombres DNS internos y placeholders para URLs publicas.

### Secret

Archivo:

```text
k8s/secret.yaml
```

Nombre:

```text
banquito-secrets
```

Contiene placeholders para credenciales y endpoints sensibles. En un ambiente real debe reemplazarse por integracion con Secret Manager o por secrets generados desde el pipeline.

## Validacion

Se ejecuto validacion cliente sin desplegar:

```bash
kubectl create --dry-run=client --validate=false --recursive -f banquito-infra/k8s
```

Resultado:

```text
Todos los Deployments, Services, Namespace, ConfigMap y Secret fueron parseados correctamente en modo dry-run.
```

Nota:

`kubectl apply --dry-run=client` intento consultar el cluster configurado en el kubeconfig local y fallo por credenciales de `gcloud`. Ese fallo no corresponde a errores YAML.

## Pendientes antes de desplegar

1. Reemplazar `PROJECT_ID` por el ID real de Google Cloud.
2. Definir si se usara `latest`, `github.sha` o version semantica como tag.
3. Reemplazar placeholders de `secret.yaml`.
4. Conectar los Secrets con Google Secret Manager.
5. Crear `ingress.yaml` o Gateway para exponer frontends/API.
6. Crear pipeline CI/CD que construya imagenes, publique en Artifact Registry y aplique estos manifiestos.

## Comandos utilizados

### Revisar estructura `k8s`

Se uso este comando para listar las carpetas de servicios ya creadas:

```powershell
Get-ChildItem -Path banquito-infra\k8s -Directory | Select-Object -ExpandProperty Name
```

### Verificar archivos base existentes

Se reviso el contenido inicial de `configmap.yaml` e `ingress.yaml`:

```powershell
Get-Content banquito-infra\k8s\configmap.yaml
Get-Content banquito-infra\k8s\ingress.yaml
```

### Revisar estado Git antes de crear manifiestos

```powershell
git -C banquito-infra status --short
```

## Ajuste por capacidad: Recreate

Durante las pruebas en GKE Autopilot se observo que `RollingUpdate` creaba un Pod nuevo antes de eliminar el anterior. En un cluster con poca capacidad, eso causaba Pods en `Pending` por:

```text
Insufficient memory
Too many pods
GCE out of resources
```

Para el ambiente universitario/demo se cambio la estrategia de todos los Deployments a:

```yaml
strategy:
  type: Recreate
```

Esto hace que Kubernetes primero elimine el Pod anterior y luego cree el nuevo, reduciendo el consumo temporal durante actualizaciones.

Comando usado para verificar que ya no queden `RollingUpdate`:

```powershell
rg -n "RollingUpdate|rollingUpdate|maxSurge|maxUnavailable" banquito-infra\k8s -g deployment.yaml
```

Comando usado para validar manifiestos:

```powershell
kubectl create --dry-run=client --validate=false --recursive -f banquito-infra\k8s
```

Nota:

```text
En produccion, RollingUpdate es preferible para evitar downtime. En este proyecto demo se usa Recreate porque la capacidad del cluster es limitada.
```

### Confirmar que cada carpeta tenga Deployment y Service

Despues de crear los manifiestos, se valido que cada carpeta tuviera `deployment.yaml` y `service.yaml`:

```powershell
Get-ChildItem -Path banquito-infra\k8s -Directory | ForEach-Object {
  [PSCustomObject]@{
    Service=$_.Name
    Deployment=(Test-Path (Join-Path $_.FullName 'deployment.yaml'))
    ServiceYaml=(Test-Path (Join-Path $_.FullName 'service.yaml'))
  }
} | Format-Table -AutoSize
```

Resultado:

```text
Todas las carpetas devolvieron Deployment=True y ServiceYaml=True.
```

### Buscar referencias importantes en los manifiestos

Se uso este comando para validar namespace, replicas, tipo de Service, ConfigMap, Secret e imagenes Artifact Registry:

```powershell
rg -n "image:|namespace: banquito|replicas: 2|type: ClusterIP|envFrom:|banquito-config|banquito-secrets|PROJECT_ID" banquito-infra\k8s -S
```

### Verificar cliente kubectl

```powershell
kubectl version --client
```

Resultado:

```text
Client Version: v1.34.1
Kustomize Version: v5.7.1
```

### Intento de validacion con apply dry-run

Primero se intento:

```powershell
kubectl apply --dry-run=client --recursive -f banquito-infra\k8s
```

Tambien se intento:

```powershell
kubectl apply --dry-run=client --validate=false --recursive -f banquito-infra\k8s
```

Ambos intentos fallaron porque `kubectl apply` intento consultar el cluster configurado en el kubeconfig local. El error fue de credenciales/permisos de `gcloud`, no de los YAML:

```text
Unable to create private file C:\Users\User\AppData\Roaming\gcloud\credentials.db
```

### Validacion final sin consultar cluster

Para validar los manifiestos sin desplegar y sin consultar el cluster se uso:

```powershell
kubectl create --dry-run=client --validate=false --recursive -f banquito-infra\k8s
```

Resultado:

```text
deployment.apps/account-core-service created (dry run)
service/account-core-service created (dry run)
deployment.apps/accounting-service created (dry run)
service/accounting-service created (dry run)
deployment.apps/clearinghouse-service created (dry run)
service/clearinghouse-service created (dry run)
configmap/banquito-config created (dry run)
deployment.apps/web-empresas-frontend created (dry run)
service/web-empresas-frontend created (dry run)
deployment.apps/file-reception-service created (dry run)
service/file-reception-service created (dry run)
namespace/banquito created (dry run)
deployment.apps/notification-service created (dry run)
service/notification-service created (dry run)
deployment.apps/operador-frontend created (dry run)
service/operador-frontend created (dry run)
deployment.apps/party-service created (dry run)
service/party-service created (dry run)
deployment.apps/web-personas-frontend created (dry run)
service/web-personas-frontend created (dry run)
deployment.apps/report-service created (dry run)
service/report-service created (dry run)
secret/banquito-secrets created (dry run)
deployment.apps/tariff-service created (dry run)
service/tariff-service created (dry run)
deployment.apps/teller-frontend created (dry run)
service/teller-frontend created (dry run)
```

### Listar archivos Kubernetes generados

```powershell
Get-ChildItem -Path banquito-infra\k8s -Recurse -File |
  Select-Object FullName |
  ForEach-Object {
    $_.FullName.Substring((Get-Location).Path.Length + 1)
  }
```

### Estado final del repo de infraestructura

```powershell
git -C banquito-infra status --short
```
