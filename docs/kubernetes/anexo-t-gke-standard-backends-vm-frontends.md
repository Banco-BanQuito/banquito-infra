# Anexo T - GKE Standard para backends y frontends en VM

## Decision

Para una defensa tecnica donde se quiere mostrar configuracion explicita de Kubernetes, la opcion recomendada es migrar los backends desde GKE Autopilot hacia un cluster GKE Standard.

Los frontends no se despliegan en Kubernetes. Se mantienen en una VM con Nginx porque son aplicaciones estaticas Vite y consumen las APIs mediante Apigee.

## Objetivo

Reducir costo y complejidad dentro del cluster, pero mantener una configuracion suficientemente visible para sustentar Kubernetes:

- GKE Standard solo para microservicios backend.
- VM/Nginx para frontends.
- Apigee como entrada publica de APIs.
- Services internos tipo `ClusterIP`.
- Gateway de GKE solo para exponer backends hacia Apigee.
- HPA para Pods backend.
- Node autoscaling para agregar o quitar worker nodes.

## Arquitectura objetivo

```text
Usuarios
  -> Frontends en VM/Nginx
  -> Apigee
  -> GKE Gateway publico
  -> Services ClusterIP
  -> Pods backend Core/Switch
  -> Cloud SQL / MongoDB Atlas / Pub/Sub / Secret Manager
```

Los frontends quedan fuera del cluster:

```text
VM/Nginx
  /var/www/banquito/personas
  /var/www/banquito/empresas
  /var/www/banquito/teller
  /var/www/banquito/operador
```

## Por que Standard en este caso

| Punto | Autopilot | Standard |
| --- | --- | --- |
| Nodos worker | Google los decide | Se configuran explicitamente |
| Tipo de maquina | Automatico | Definido por el equipo |
| Node autoscaling | Administrado por Google | Configurable y defendible |
| Costo base | Por recursos solicitados | Por VM encendida |
| Control para sustentacion | Medio | Alto |
| Riesgo operativo | Bajo | Medio |

Para la entrega, Standard ayuda a explicar:

- tipo de maquina;
- cantidad minima y maxima de nodos;
- HPA de Pods;
- autoscaling de nodos;
- separacion por namespaces;
- consumo de CPU/memoria por Pod y por nodo.

## Configuracion recomendada para no encarecer

Para poder explicar correctamente alta disponibilidad de Kubernetes, usar un cluster regional Standard. En GKE el plano de control es administrado por Google y, al ser regional, queda replicado en varias zonas de la region. Para el plano de datos se configura un node pool con 1 worker node por zona, dando 3 worker nodes iniciales.

Configuracion sugerida:

| Recurso | Valor |
| --- | --- |
| Tipo de cluster | GKE Standard |
| Region | `us-east1` |
| Zonas | `us-east1-b`, `us-east1-c`, `us-east1-d` |
| Node pool | `backend-pool` |
| Tipo de maquina | `e2-standard-2` |
| Nodos iniciales | 3 total, 1 por zona |
| Min nodes por zona | `1` |
| Max nodes por zona | `2` |
| Disco por nodo | `50GB` |
| Frontends | Fuera de GKE, VM/Nginx |

Esta configuracion permite defender 3 replicas del plano de control administrado y 3 worker nodes en el plano de datos. Para no encarecer, se usa `e2-standard-2` y se mantiene el maximo en 2 nodos por zona.

Nota: en Kubernetes no significa que cada worker node ejecute un unico microservicio. Cada microservicio se despliega como Deployment y cada Pod ejecuta normalmente un contenedor principal. El scheduler distribuye varios Pods sobre los worker nodes disponibles segun CPU, memoria, requests, limits y reglas de afinidad.

## Comandos para crear el cluster Standard

Ejecutar desde Windows 11 PowerShell.

```powershell
gcloud config set project project-47695a8e-7cb2-4352-af2
```

Crear cluster regional con 3 worker nodes iniciales:

```powershell
gcloud container clusters create banquito-cluster-standard `
  --region us-east1 `
  --node-locations us-east1-b,us-east1-c,us-east1-d `
  --machine-type e2-standard-2 `
  --num-nodes 1 `
  --enable-autoscaling `
  --min-nodes 1 `
  --max-nodes 2 `
  --disk-size 50 `
  --enable-ip-alias `
  --workload-pool=project-47695a8e-7cb2-4352-af2.svc.id.goog `
  --project project-47695a8e-7cb2-4352-af2
```

Obtener credenciales:

```powershell
gcloud container clusters get-credentials banquito-cluster-standard `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2
```

Validar nodos:

```powershell
kubectl get nodes -o wide
```

Validar capacidad:

```powershell
kubectl top nodes
```

## Desplegar solo backends

La carpeta activa `banquito-infra/k8s` ya no contiene manifiestos de frontends. Contiene Core, Switch, Gateway, ConfigMaps, Secrets y HPA.

Aplicar manifiestos:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply --recursive -f .
```

Validar namespaces:

```powershell
kubectl get ns
```

Validar Core:

```powershell
kubectl get pods -n banquito-core -o wide
kubectl get svc -n banquito-core
```

Validar Switch:

```powershell
kubectl get pods -n banquito-switch -o wide
kubectl get svc -n banquito-switch
```

Validar Gateway:

```powershell
kubectl get gateway -A
kubectl get httproute -A
kubectl get svc -A
```

## Levantar por bloques

Core:

```powershell
kubectl scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito-core
```

Switch minimo para pagos masivos:

```powershell
kubectl scale deployment file-reception-service payment-line-classifier-service payment-line-publisher-service payment-line-subscriber-service clearinghouse-service --replicas=1 -n banquito-switch
```

Switch complementario:

```powershell
kubectl scale deployment tariff-service report-service notification-service --replicas=1 -n banquito-switch
```

Ver estado:

```powershell
kubectl get pods -n banquito-core -o wide
kubectl get pods -n banquito-switch -o wide
```

## Apagar para no consumir

Apagar Core:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
```

Apagar Switch:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-switch
```

Validar que no quedan Pods de aplicacion:

```powershell
kubectl get pods -n banquito-core
kubectl get pods -n banquito-switch
```

En GKE Standard, aunque los Pods esten en `0`, queda al menos un nodo por zona si el node pool tiene `min-nodes=1`. En esta configuracion eso significa 3 worker nodes encendidos.

## Bajar node pool a cero para ahorrar mas

Para reducir costo cuando no se esta usando la demo:

```powershell
gcloud container clusters update banquito-cluster-standard `
  --region us-east1 `
  --enable-autoscaling `
  --min-nodes 0 `
  --max-nodes 2 `
  --node-pool default-pool `
  --project project-47695a8e-7cb2-4352-af2
```

## Apagado ejecutado del cluster Standard

El apagado operativo se hizo en dos niveles:

1. Primero se apagaron los microservicios, dejando los Deployments en `0/0`.
2. Despues se bajo el `default-pool` a `0` nodos para que no queden VMs worker consumiendo.

### 1. Apagar Deployments de Core

En Windows 11 PowerShell:

```powershell
kubectl --insecure-skip-tls-verify=true scale `
  deployment/account-core-service `
  deployment/accounting-service `
  deployment/party-service `
  --replicas=0 `
  -n banquito-core
```

Resultado esperado:

```text
deployment.apps/account-core-service scaled
deployment.apps/accounting-service scaled
deployment.apps/party-service scaled
```

### 2. Apagar Deployments de Switch

```powershell
kubectl --insecure-skip-tls-verify=true scale `
  deployment/clearinghouse-service `
  deployment/file-reception-service `
  deployment/notification-service `
  deployment/payment-line-classifier-service `
  deployment/payment-line-publisher-service `
  deployment/payment-line-subscriber-service `
  deployment/report-service `
  deployment/tariff-service `
  --replicas=0 `
  -n banquito-switch
```

Resultado esperado:

```text
deployment.apps/clearinghouse-service scaled
deployment.apps/file-reception-service scaled
deployment.apps/notification-service scaled
deployment.apps/payment-line-classifier-service scaled
deployment.apps/payment-line-publisher-service scaled
deployment.apps/payment-line-subscriber-service scaled
deployment.apps/report-service scaled
deployment.apps/tariff-service scaled
```

Nota: se usaron nombres explicitos porque `kubectl scale deployment --all` puede fallar si la conexion al API server se corta durante operaciones de ajuste del cluster.

### 3. Validar Deployments apagados

```powershell
kubectl --insecure-skip-tls-verify=true get deploy -n banquito-core
kubectl --insecure-skip-tls-verify=true get deploy -n banquito-switch
```

Validacion obtenida:

```text
banquito-core:
account-core-service   0/0
accounting-service     0/0
party-service          0/0

banquito-switch:
clearinghouse-service             0/0
file-reception-service            0/0
notification-service              0/0
payment-line-classifier-service   0/0
payment-line-publisher-service    0/0
payment-line-subscriber-service   0/0
report-service                    0/0
tariff-service                    0/0
```

### 4. Desactivar autoscaling temporalmente

Para poder reducir el node pool manualmente a cero, se desactivo el autoscaling del pool:

```powershell
gcloud container node-pools update default-pool `
  --cluster banquito-cluster-standard `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2 `
  --no-enable-autoscaling
```

### 5. Bajar el node pool a 0 nodos

```powershell
gcloud container clusters resize banquito-cluster-standard `
  --region us-east1 `
  --node-pool default-pool `
  --num-nodes 0 `
  --project project-47695a8e-7cb2-4352-af2 `
  --quiet
```

Si la consola corta por tiempo de espera, no significa necesariamente que fallo. Se debe revisar la operacion:

```powershell
gcloud container operations list `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2 `
  --sort-by="~startTime" `
  --limit=5
```

En la ejecucion realizada, la operacion fue:

```text
TYPE: SET_NODE_POOL_SIZE
TARGET: default-pool
STATUS: DONE
```

Para esperar una operacion especifica:

```powershell
gcloud container operations wait OPERATION_ID `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2
```

### 6. Confirmar que no quedan VMs worker

```powershell
gcloud compute instances list `
  --project project-47695a8e-7cb2-4352-af2 `
  --filter="name~gke-banquito-cluster-sta" `
  --format="table(name,zone,status,machineType.basename())"
```

Validacion obtenida: el comando no devolvio instancias, por lo tanto no quedaron worker nodes del cluster Standard encendidos.

### 7. Estado final del apagado

| Elemento | Estado |
| --- | --- |
| Deployments Core | `0/0` |
| Deployments Switch | `0/0` |
| Frontends | Fuera de GKE, en VM/Nginx |
| Node pool `default-pool` | Redimensionado a `0` |
| VMs worker GKE Standard | Sin instancias visibles |
| Cluster GKE Standard | Sigue creado |

Importante: esto reduce el consumo de worker nodes. El cluster Standard sigue existiendo, por lo que pueden quedar costos residuales del plano de control, Gateway/Load Balancer, IPs o recursos de red asociados. Para eliminar todo costo del cluster, la accion seria borrar el cluster, pero eso es distinto a apagarlo.

Si el node pool tiene otro nombre, obtenerlo con:

```powershell
gcloud container node-pools list `
  --cluster banquito-cluster-standard `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2
```

Volver a dejar minimo un nodo para pruebas:

```powershell
gcloud container clusters update banquito-cluster-standard `
  --region us-east1 `
  --enable-autoscaling `
  --min-nodes 1 `
  --max-nodes 2 `
  --node-pool default-pool `
  --project project-47695a8e-7cb2-4352-af2
```

## Que cambia en Apigee

Al crear el cluster Standard, el Gateway de GKE probablemente tendra una nueva IP publica.

Obtener IP:

```powershell
kubectl get gateway -n banquito-gateway
```

O revisar Services generados por Gateway:

```powershell
kubectl get svc -A
```

Esa IP debe enviarse al equipo de Apigee para actualizar el Target Endpoint.

Flujo esperado:

```text
Frontend VM
  -> https://136.68.89.25.nip.io/api/v2/...
  -> Apigee
  -> IP publica del Gateway GKE Standard
  -> Service interno backend
```

## Que no debe desplegarse en GKE

No desplegar en Kubernetes:

- `banquito-web-personas-frontend`
- `banquito-web-empresas-frontend`
- `banquito-teller-frontend`
- `banquito-frontend-web-operador`
- bases de datos
- Pub/Sub
- Apigee
- OAuth / Identity Platform
- Secret Manager

## Verificacion para defender

Comandos utiles:

```powershell
kubectl get nodes -o wide
kubectl top nodes
kubectl get pods -A -o wide
kubectl top pods -A
kubectl get deploy -A
kubectl get hpa -A
kubectl get svc -A
kubectl get gateway -A
kubectl get httproute -A
```

Frase para sustentacion:

> Se usa GKE Standard para los microservicios backend del Core y del Switch, porque permite demostrar configuracion explicita de node pools, tipo de maquina, autoscaling de nodos, HPA y distribucion de Pods. Los frontends no se ejecutan en Kubernetes porque son aplicaciones estaticas; se publican en una VM con Nginx y consumen las APIs mediante Apigee, manteniendo el cluster reservado para workloads backend.
