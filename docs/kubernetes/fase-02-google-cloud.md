# FASE 2 - Preparacion de Google Cloud

## Objetivo

Tener lista la infraestructura cloud donde se despliegan las aplicaciones.

## Proyecto

```text
project-47695a8e-7cb2-4352-af2
```

## APIs necesarias

```powershell
gcloud services enable container.googleapis.com --project project-47695a8e-7cb2-4352-af2
gcloud services enable artifactregistry.googleapis.com --project project-47695a8e-7cb2-4352-af2
gcloud services enable compute.googleapis.com --project project-47695a8e-7cb2-4352-af2
gcloud services enable iamcredentials.googleapis.com --project project-47695a8e-7cb2-4352-af2
```

## Cluster GKE

Se usa GKE Autopilot:

```text
Cluster: banquito-cluster-east
Region: us-east1
Mode: Autopilot
Status: Running
Endpoint administrativo Kubernetes: 34.148.92.193
```

Crear cluster:

```powershell
gcloud container clusters create-auto banquito-cluster-east `
  --project project-47695a8e-7cb2-4352-af2 `
  --region us-east1
```

Obtener credenciales:

```powershell
gcloud container clusters get-credentials banquito-cluster-east `
  --project project-47695a8e-7cb2-4352-af2 `
  --region us-east1
```

Validar:

```powershell
kubectl get nodes
```

## Permisos del Service Account de nodos

En GKE Autopilot puede aparecer la advertencia:

```text
Grant roles/container.defaultNodeServiceAccount role to Node service account to allow for non-degraded operations.
```

Esto no significa que los manifiestos esten mal. Significa que el Service Account usado por los nodos necesita el rol recomendado por GKE para operar sin degradacion.

Service Account de nodos usado en este proyecto:

```text
69503932816-compute@developer.gserviceaccount.com
```

Comando para asignar el rol:

```powershell
gcloud projects add-iam-policy-binding project-47695a8e-7cb2-4352-af2 `
  --member="serviceAccount:69503932816-compute@developer.gserviceaccount.com" `
  --role="roles/container.defaultNodeServiceAccount"
```

Validar:

```powershell
gcloud projects get-iam-policy project-47695a8e-7cb2-4352-af2 `
  --flatten="bindings[].members" `
  --filter="bindings.members:69503932816-compute@developer.gserviceaccount.com" `
  --format="table(bindings.role)"
```

## Cuota regional de GKE Autopilot

Si los Pods quedan en `Pending` y los eventos muestran:

```text
Can't scale up due to exceeded quota
GCE quota exceeded
```

la causa no es Kubernetes ni el microservicio. La causa es que Google Cloud no tiene cuota disponible para crear mas capacidad en la region del cluster.

Comandos de revision:

```powershell
gcloud compute regions describe us-east1 `
  --project project-47695a8e-7cb2-4352-af2 `
  --format="table(quotas.metric,quotas.limit,quotas.usage)"

kubectl get events -A --sort-by=.lastTimestamp
kubectl describe pod -n banquito-core <pod>
```

En PowerShell, el comando anterior puede salir como listas largas. Para verlo ordenado por cuota individual:

```powershell
$region = gcloud compute regions describe us-east1 `
  --project project-47695a8e-7cb2-4352-af2 `
  --format=json | ConvertFrom-Json

$region.quotas |
  Select-Object metric, limit, usage |
  Sort-Object metric |
  Format-Table -AutoSize
```

Para ver solo cuotas relevantes para GKE Autopilot:

```powershell
$region.quotas |
  Where-Object {
    $_.metric -in @(
      "CPUS",
      "E2_CPUS",
      "N2_CPUS",
      "C3_CPUS",
      "INSTANCES",
      "IN_USE_ADDRESSES",
      "STATIC_ADDRESSES",
      "SSD_TOTAL_GB",
      "DISKS_TOTAL_GB",
      "NETWORK_ENDPOINT_GROUPS",
      "EXTERNAL_MANAGED_FORWARDING_RULES"
    )
  } |
  Select-Object metric, limit, usage |
  Format-Table -AutoSize
```

Lectura observada en este proyecto:

```text
CPUS             2 / 32
IN_USE_ADDRESSES 1 / 4
INSTANCES        1 / 8
SSD_TOTAL_GB     100 / 250
```

Esas cuotas generales no estan al limite. Si GKE sigue mostrando `Can't scale up due to exceeded quota`, se debe revisar el evento exacto del Pod o del autoscaler, porque puede estar fallando por una cuota especifica de familia de maquina o por disponibilidad zonal dentro de `us-east1`.

Comandos para encontrar el mensaje exacto:

```powershell
kubectl get events -A --sort-by=.lastTimestamp
kubectl describe pod -n banquito-core <pod-pending>
kubectl describe pod -n banquito-switch <pod-pending>
kubectl describe pod -n banquito-frontend <pod-pending>
```

Soluciones posibles:

```text
1. Pedir aumento de cuota en us-east1.
2. Reducir replicas/HPAs mientras se prueba.
3. Ejecutar pruebas por bloques: Core, Switch o Frontends.
4. Cambiar a otra region con mejor disponibilidad de cuota.
```

Para laboratorio, la solucion recomendada es probar por bloques y mantener los Deployments en `0/0` cuando no se usen.

## Artifact Registry

Repositorio:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito
```

Crear repositorio:

```powershell
gcloud artifacts repositories create banquito `
  --repository-format=docker `
  --location=us-central1 `
  --description="Imagenes Docker BanQuito" `
  --project project-47695a8e-7cb2-4352-af2
```

Permitir que GKE lea imagenes:

```powershell
gcloud artifacts repositories add-iam-policy-binding banquito `
  --location=us-central1 `
  --project=project-47695a8e-7cb2-4352-af2 `
  --member=serviceAccount:69503932816-compute@developer.gserviceaccount.com `
  --role=roles/artifactregistry.reader
```

## Entregable

```powershell
kubectl get nodes
gcloud artifacts repositories list --location=us-central1
```
