# Fase 8 - Pruebas en Kubernetes

## Objetivo

Probar los manifiestos Kubernetes aplicandolos al cluster GKE y revisando:

- Pods.
- Services.
- Logs.
- Estado `Running`.

## Comandos objetivo de la fase

Estos son los comandos que se deben ejecutar cuando el cluster, imagenes y variables reales esten listos:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply --recursive -f .
kubectl get pods -n banquito
kubectl get svc -n banquito
kubectl logs -n banquito <nombre-del-pod>
```

Tambien se puede usar la forma corta:

```powershell
kubectl apply -R -f .
```

Importante:

```powershell
kubectl apply -f .
```

aplica solo los YAML del nivel actual de `k8s`, por ejemplo:

```text
configmap.yaml
namespace.yaml
secret.yaml
```

No aplica los `deployment.yaml` ni `service.yaml` que estan dentro de subcarpetas como:

```text
account-core/
accounting/
party/
file-reception/
```

Por eso, si se usa `kubectl apply -f .`, es normal ver:

```text
configmap/banquito-config created
namespace/banquito unchanged
secret/banquito-secrets created
```

y despues:

```text
kubectl get pods -n banquito
No resources found in banquito namespace.

kubectl get svc -n banquito
No resources found in banquito namespace.
```

La solucion es aplicar recursivamente:

```powershell
kubectl apply --recursive -f .
```

## Preflight ejecutado

Antes de aplicar al cluster se revisaron placeholders:

```powershell
rg -n "PROJECT_ID|replace-with|example\.com" banquito-infra\k8s -S
```

Resultado:

```text
Existen placeholders pendientes:
- PROJECT_ID en imagenes Artifact Registry.
- replace-with-* en secret.yaml.
- example.com en configmap.yaml.
```

Por esta razon, si se aplican los manifiestos ahora, los Pods no quedaran correctamente en `Running`. Los errores esperados serian:

- `ImagePullBackOff`, porque `PROJECT_ID` no existe como imagen real.
- `CrashLoopBackOff`, porque las URLs y credenciales aun son placeholders.
- fallos de conexion a bases, RabbitMQ, MongoDB, API Manager u OAuth.

## Validacion local de manifiestos

Se valido que los YAML sean parseables por Kubernetes sin desplegar:

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

## Cluster configurado

Se reviso el contexto actual de Kubernetes:

```powershell
kubectl config current-context
```

Resultado:

```text
gke_project-47695a8e-7cb2-4352-af2_us-central1_banquito-cluster
```

## Prueba de acceso al cluster

Se intento consultar el namespace:

```powershell
kubectl get namespace banquito
```

Primer resultado:

```text
Unable to connect to the server: getting credentials:
exec: executable gke-gcloud-auth-plugin.exe failed with exit code 1
```

El error inicial fue por permisos al escribir en:

```text
C:\Users\User\AppData\Roaming\gcloud\credentials.db
```

Se reintento con permisos elevados. El segundo resultado fue:

```text
There was a problem refreshing your current auth tokens:
HTTPSConnectionPool(host='oauth2.googleapis.com', port=443):
SSLCertVerificationError: certificate verify failed

Please run:
gcloud auth login
```

## Estado actualizado de la Fase 8

La autenticacion al cluster fue resuelta desde la terminal del usuario y se pudo aplicar los manifiestos.

Al aplicar solo el nivel actual con:

```powershell
kubectl apply -f .
```

se crearon unicamente:

```text
configmap/banquito-config
namespace/banquito
secret/banquito-secrets
```

Despues se identifico que era necesario aplicar recursivamente porque los Deployments y Services estan en subcarpetas:

```powershell
kubectl apply --recursive -f .
```

Con eso se crearon los Services y Deployments.

## Pasos necesarios para poder aplicar

### 1. Autenticacion de Google Cloud

Si el acceso al cluster falla, ejecutar:

```powershell
gcloud auth login
gcloud config set project <PROJECT_ID>
gcloud container clusters get-credentials banquito-cluster --region us-central1
```

Si el cluster es zonal:

```powershell
gcloud container clusters get-credentials banquito-cluster --zone us-central1-a
```

### 2. Imagenes de contenedor

Inicialmente las imagenes estaban con placeholder de Artifact Registry:

```text
us-central1-docker.pkg.dev/PROJECT_ID/banquito/<image>:latest
```

Al aplicar los Deployments, Kubernetes mostro:

```text
InvalidImageName
```

La causa fue que `PROJECT_ID` no es un proyecto real.

Para avanzar la prueba, se reemplazaron temporalmente las imagenes por GHCR:

```text
ghcr.io/banco-banquito/account-core-service:latest
ghcr.io/banco-banquito/accounting-service:latest
ghcr.io/banco-banquito/party-service:latest
ghcr.io/banco-banquito/file-reception-service:latest
ghcr.io/banco-banquito/tariff-service:latest
ghcr.io/banco-banquito/clearinghouse-service:latest
ghcr.io/banco-banquito/report-service:latest
ghcr.io/banco-banquito/notification-service:latest
ghcr.io/banco-banquito/teller-frontend:latest
ghcr.io/banco-banquito/web-personas-frontend:latest
ghcr.io/banco-banquito/web-empresas-frontend:latest
ghcr.io/banco-banquito/operador-frontend:latest
```

Comando usado para validar que ya no quedara `PROJECT_ID`:

```powershell
rg -n "image:|PROJECT_ID|us-central1-docker.pkg.dev" banquito-infra\k8s -g "deployment.yaml"
```

Resultado:

```text
Todas las imagenes quedaron apuntando a ghcr.io/banco-banquito.
```

Nota:

Esto es una solucion temporal para continuar probando. La solucion final en Google Cloud es construir y publicar las imagenes en Artifact Registry con el proyecto real:

```text
us-central1-docker.pkg.dev/<PROJECT_ID_REAL>/banquito/<image>:<TAG>
```

### 3. Reemplazar placeholders de ConfigMap y Secret

Actualizar:

```text
k8s/configmap.yaml
k8s/secret.yaml
```

con valores reales o de ambiente demo.

### 4. Aplicar y verificar

```powershell
kubectl apply --recursive -f C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl get pods -n banquito
kubectl get svc -n banquito
```

Para logs:

```powershell
kubectl logs -n banquito <nombre-del-pod>
```

Importante: si el Pod esta en estado `Pending`, todavia no hay contenedor ejecutandose. En ese caso `kubectl logs` no es el primer comando util. Primero se debe revisar por que Kubernetes no puede programar el Pod.

## Caso real: Services creados y Pods en Pending

Despues de aplicar recursivamente, los Services quedaron creados correctamente:

```powershell
kubectl get svc -n banquito
```

Ejemplo de salida esperada:

```text
NAME                     TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)
account-core-service     ClusterIP   <ip-interna>     <none>        8081/TCP,9091/TCP
accounting-service       ClusterIP   <ip-interna>     <none>        8082/TCP,9092/TCP
party-service            ClusterIP   <ip-interna>     <none>        8083/TCP,9093/TCP
...
```

Si los Pods aparecen asi:

```powershell
kubectl get pods -n banquito
```

```text
NAME                                  READY   STATUS    RESTARTS
account-core-service-xxxxx            0/1     Pending   0
accounting-service-xxxxx              0/1     Pending   0
...
```

entonces el problema aun no esta en la aplicacion ni en los logs. `Pending` significa que el Pod todavia no fue asignado a un nodo o no puede arrancar por una condicion previa.

### Comandos para diagnosticar Pending

Tomar uno de los Pods en `Pending` y ejecutar:

```powershell
kubectl describe pod -n banquito account-core-service-758886ff5-7bmj4
```

Revisar especialmente la seccion:

```text
Events:
```

Tambien se pueden listar eventos del namespace ordenados por tiempo:

```powershell
kubectl get events -n banquito --sort-by=.lastTimestamp
```

Y revisar los Deployments:

```powershell
kubectl get deployments -n banquito
kubectl describe deployment -n banquito account-core-service
```

### Causas probables de Pending

Las causas mas comunes son:

1. GKE Autopilot aun esta aprovisionando capacidad.
2. No hay cuota suficiente de CPU/memoria en la region.
3. Los `requests` de recursos son altos para la cuota disponible.
4. El cluster no tiene nodos disponibles.
5. Hay restricciones de scheduling, aunque en estos manifiestos no se definieron `nodeSelector`, `affinity` ni `tolerations`.

### Diagnostico real obtenido

Se ejecuto:

```powershell
kubectl describe pod -n banquito account-core-service-758886ff5-7bmj4
```

El Pod estaba en `Pending` y sin nodo asignado:

```text
Node: <none>
PodScheduled: False
```

Los eventos mostraron:

```text
TriggeredScaleUp
Pod triggered scale-up

FailedScaleUp
Node scale up in zones us-central1-a associated with this pod failed: GCE quota exceeded.

FailedScheduling
no nodes available to schedule pods

FailedScheduling
0/1 nodes are available: 1 Insufficient memory.
```

Conclusion:

```text
El problema no es el codigo ni los Services. El cluster no tiene capacidad suficiente y GKE no puede escalar por cuota de GCE.
```

### Ajuste aplicado para modo demo

Para reducir consumo en el proyecto universitario, se ajustaron todos los Deployments:

- replicas: de `2` a `1`.
- backends: requests `100m / 256Mi`, limits `250m / 512Mi`.
- frontends: requests `50m / 64Mi`, limits `150m / 128Mi`.

Esto baja la cantidad de Pods de 24 a 12 y reduce memoria solicitada.

Validacion local despues del ajuste:

```powershell
kubectl create --dry-run=client --validate=false --recursive -f banquito-infra\k8s
```

Resultado:

```text
Todos los manifiestos fueron parseados correctamente.
```

Para aplicar el ajuste al cluster:

```powershell
kubectl apply --recursive -f .
```

Luego revisar:

```powershell
kubectl get pods -n banquito
kubectl get events -n banquito --sort-by=.lastTimestamp
```

### Prueba reducida a 3 servicios

Para evitar saturar el cluster mientras se depuran imagenes y configuracion, se escalaron todos los Deployments a 0 y luego se levantaron solo 3 servicios principales del Core:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito
kubectl delete pod --all -n banquito
kubectl scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito
kubectl get pods -n banquito
```

Resultado observado:

```text
account-core-service   ContainerCreating -> InvalidImageName
accounting-service     ContainerCreating -> InvalidImageName
party-service          ContainerCreating -> InvalidImageName
```

Diagnostico:

```text
El cluster ya intentaba crear los contenedores, pero el nombre de imagen era invalido por PROJECT_ID.
```

Accion tomada:

```text
Se reemplazaron las imagenes de PROJECT_ID/Artifact Registry placeholder por imagenes GHCR.
```

Siguiente comando a ejecutar:

```powershell
kubectl apply --recursive -f .
kubectl rollout restart deployment account-core-service accounting-service party-service -n banquito
kubectl get pods -n banquito
```

Posibles siguientes estados:

```text
Running           -> imagen descargada y app corriendo.
ImagePullBackOff  -> GHCR es privado o la imagen no existe.
CrashLoopBackOff  -> la imagen arranco, pero falla la app por variables/secrets/servicios externos.
```

### Caso real: Deployment seguia con PROJECT_ID

Se reviso el Deployment directamente en el cluster:

```powershell
kubectl describe deployment account-core-service -n banquito
```

Resultado observado:

```text
Image: us-central1-docker.pkg.dev/PROJECT_ID/banquito/account-core-service:latest
```

Eso significa que el cluster todavia tenia aplicada la version anterior del Deployment.

Se reviso el archivo local:

```powershell
Select-String -Path banquito-infra\k8s\account-core\deployment.yaml -Pattern "image:"
```

Resultado local:

```text
image: ghcr.io/banco-banquito/account-core-service:latest
```

Conclusion:

```text
El YAML local ya estaba corregido, pero faltaba aplicar ese Deployment actualizado al cluster.
```

Comandos para aplicar solo los 3 Deployments del Core:

```powershell
kubectl apply -f account-core\deployment.yaml
kubectl apply -f accounting\deployment.yaml
kubectl apply -f party\deployment.yaml
```

Verificacion:

```powershell
kubectl describe deployment account-core-service -n banquito
kubectl describe deployment accounting-service -n banquito
kubectl describe deployment party-service -n banquito
```

La imagen debe aparecer como:

```text
ghcr.io/banco-banquito/account-core-service:latest
ghcr.io/banco-banquito/accounting-service:latest
ghcr.io/banco-banquito/party-service:latest
```

Luego reiniciar rollout:

```powershell
kubectl rollout restart deployment account-core-service accounting-service party-service -n banquito
kubectl get pods -n banquito
```

Si despues de esto aparece `ImagePullBackOff`, el problema ya no es `InvalidImageName`, sino acceso o existencia de la imagen en GHCR.

### Resultado: imagen corregida en el Deployment

Despues de aplicar el Deployment actualizado, se verifico nuevamente:

```powershell
kubectl describe deployment account-core-service -n banquito
```

Resultado:

```text
Image: ghcr.io/banco-banquito/account-core-service:latest
```

Esto confirma que el problema `InvalidImageName` por `PROJECT_ID` fue corregido para `account-core-service`.

Tambien se observo:

```text
Replicas: 1 desired | 1 updated | 2 total | 0 available | 2 unavailable
OldReplicaSets: account-core-service-69c7c477fc
NewReplicaSet: account-core-service-7dcfd75d86
```

Interpretacion:

```text
El Deployment ya creo un ReplicaSet nuevo con la imagen GHCR, pero todavia existe un Pod viejo o ReplicaSet anterior durante el RollingUpdate.
```

Siguiente paso:

```powershell
kubectl get pods -n banquito
kubectl describe pod -n banquito <pod-nuevo-account-core>
```

Si el Pod viejo sigue bloqueando o se quiere limpiar la prueba:

```powershell
kubectl delete pod -n banquito -l app=account-core
```

Kubernetes recreara el Pod usando la imagen actual del Deployment.

Luego verificar:

```powershell
kubectl get pods -n banquito
```

Posibles estados despues de corregir la imagen:

```text
ImagePullBackOff  -> la imagen GHCR no existe o es privada.
CrashLoopBackOff  -> la imagen arranco, pero falla la app por configuracion/secrets/servicios externos.
Running           -> el contenedor arranco correctamente.
```

### Resultado: accounting y party tambien quedaron con GHCR

Se revisaron los Deployments:

```powershell
kubectl describe deployment accounting-service -n banquito
kubectl describe deployment party-service -n banquito
```

Resultado para `accounting-service`:

```text
Image: ghcr.io/banco-banquito/accounting-service:latest
SERVER_PORT: 8082
DB_SCHEMA: accounting
```

Resultado para `party-service`:

```text
Image: ghcr.io/banco-banquito/party-service:latest
SERVER_PORT: 8083
```

Esto confirma que ya se corrigio el `InvalidImageName` tambien para:

- `accounting-service`
- `party-service`

Tambien se observo que ambos Deployments tienen un ReplicaSet nuevo y ReplicaSets anteriores:

```text
accounting-service:
OldReplicaSets: accounting-service-7f678bd6f4, accounting-service-5b44dbd768
NewReplicaSet: accounting-service-9677f9d67

party-service:
OldReplicaSets: party-service-55bb747f4b, party-service-7cdbb5679b
NewReplicaSet: party-service-6fc957ffb5
```

Interpretacion:

```text
Kubernetes ya recibio la plantilla actualizada con GHCR, pero los Pods aun no estan disponibles.
```

Siguiente diagnostico:

```powershell
kubectl get pods -n banquito
kubectl describe pod -n banquito <pod-nuevo-accounting>
kubectl describe pod -n banquito <pod-nuevo-party>
```

Si el estado es `ImagePullBackOff`, revisar si GHCR es privado o si la imagen existe:

```powershell
kubectl describe pod -n banquito <pod>
```

Si el estado vuelve a `Pending`, revisar cuota/capacidad:

```powershell
kubectl get events -n banquito --sort-by=.lastTimestamp
```

### Resultado: estados mixtos despues de corregir imagenes

Se ejecuto:

```powershell
kubectl get pods -n banquito
```

Resultado observado:

```text
account-core-service-69c7c477fc-j78wc   Pending
account-core-service-7dcfd75d86-xg7cr   Pending
accounting-service-5b44dbd768-tqhbt     InvalidImageName
accounting-service-9677f9d67-z8tn8      ImagePullBackOff
party-service-6fc957ffb5-mkm42          ErrImagePull
party-service-7cdbb5679b-68lk9          Pending
```

Interpretacion:

```text
Pending          -> el Pod aun no fue programado por falta de capacidad/cuota.
InvalidImageName -> Pod viejo o ReplicaSet viejo todavia usa PROJECT_ID.
ImagePullBackOff -> la imagen tiene nombre valido, pero Kubernetes no puede descargarla.
ErrImagePull     -> fallo inicial al descargar la imagen.
```

Acciones recomendadas:

1. Limpiar Pods viejos con `InvalidImageName`.

```powershell
kubectl delete pod accounting-service-5b44dbd768-tqhbt -n banquito
```

2. Revisar el error real de pull en los Pods con `ImagePullBackOff` o `ErrImagePull`.

```powershell
kubectl describe pod -n banquito accounting-service-9677f9d67-z8tn8
kubectl describe pod -n banquito party-service-6fc957ffb5-mkm42
```

3. Revisar eventos del namespace.

```powershell
kubectl get events -n banquito --sort-by=.lastTimestamp
```

Diagnostico probable:

```text
GHCR no permite descargar la imagen desde GKE porque la imagen no existe, es privada, o requiere imagePullSecret.
```

Solucion definitiva:

```text
Construir y publicar las imagenes en Google Artifact Registry y actualizar los Deployments para usar Artifact Registry.
```

Solucion temporal si se mantiene GHCR:

```text
Crear un imagePullSecret con credenciales de GitHub Container Registry y asociarlo a los Deployments.
```

### Diagnostico real: GHCR devuelve 401 Unauthorized

Se ejecuto:

```powershell
kubectl describe pod -n banquito accounting-service-9677f9d67-z8tn8
kubectl describe pod -n banquito party-service-6fc957ffb5-mkm42
```

Resultado para `accounting-service`:

```text
Image: ghcr.io/banco-banquito/accounting-service:latest
State: Waiting
Reason: ImagePullBackOff

Failed to pull image "ghcr.io/banco-banquito/accounting-service:latest":
failed to authorize:
failed to fetch anonymous token:
unexpected status from GET request to https://ghcr.io/token?...: 401 Unauthorized
```

Resultado para `party-service`:

```text
Image: ghcr.io/banco-banquito/party-service:latest
State: Waiting
Reason: ErrImagePull

Failed to pull image "ghcr.io/banco-banquito/party-service:latest":
failed to authorize:
failed to fetch anonymous token:
unexpected status from GET request to https://ghcr.io/token?...: 401 Unauthorized
```

Interpretacion:

```text
El nombre de imagen ya es valido, pero GHCR no permite descarga anonima desde GKE.
```

Esto puede pasar porque:

- el paquete en GHCR es privado;
- la organizacion requiere autenticacion;
- el cluster no tiene un `imagePullSecret`;
- la imagen no esta publicada publicamente.

### Solucion temporal: crear imagePullSecret para GHCR

Crear un token de GitHub con permiso:

```text
read:packages
```

Luego crear el secret en Kubernetes:

```powershell
kubectl create secret docker-registry ghcr-pull-secret `
  --docker-server=ghcr.io `
  --docker-username=<GITHUB_USER> `
  --docker-password=<GITHUB_PAT_READ_PACKAGES> `
  --docker-email=<EMAIL> `
  -n banquito
```

Asociar el secret al ServiceAccount default del namespace:

```powershell
kubectl patch serviceaccount default -n banquito -p '{"imagePullSecrets":[{"name":"ghcr-pull-secret"}]}'
```

Recrear los Pods que estan en `ImagePullBackOff` o `ErrImagePull`:

```powershell
kubectl delete pod -n banquito accounting-service-9677f9d67-z8tn8
kubectl delete pod -n banquito party-service-6fc957ffb5-mkm42
```

Verificar:

```powershell
kubectl get pods -n banquito
kubectl describe pod -n banquito <pod-nuevo>
```

### Solucion definitiva: Artifact Registry

Para el despliegue final en Google Cloud, no conviene depender de GHCR.

La solucion definitiva es:

1. Construir las imagenes.
2. Publicarlas en Artifact Registry.
3. Cambiar los Deployments a:

```text
us-central1-docker.pkg.dev/<PROJECT_ID_REAL>/banquito/<image>:<tag>
```

Con Artifact Registry, GKE puede descargar imagenes del mismo proyecto con IAM correctamente configurado.

### Decision tomada: usar Artifact Registry

Se decidio dejar GHCR como prueba temporal y usar Artifact Registry como solucion correcta para Google Cloud.

Se actualizaron los Deployments para usar:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
```

Ejemplos:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest
```

Comando de verificacion local:

```powershell
rg -n "ghcr.io|PROJECT_ID|image:" banquito-infra\k8s -g "deployment.yaml"
```

Siguiente paso antes de aplicar:

```text
Las imagenes deben existir en Artifact Registry. Si no existen, el siguiente error sera ImagePullBackOff por imagen no encontrada.
```

## Control de costos durante pruebas

Como GKE Autopilot cobra por recursos usados por Pods y puede aprovisionar capacidad automaticamente, durante pruebas es recomendable apagar los Deployments cuando no se esten validando.

### Validar estado actual

```powershell
kubectl get pods -n banquito
kubectl get deployments -n banquito
kubectl get svc -n banquito
kubectl get events -n banquito --sort-by=.lastTimestamp
```

### Apagar todos los Pods de la aplicacion

Este comando deja los Deployments en 0 replicas:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito
```

Verificar:

```powershell
kubectl get pods -n banquito
kubectl get deployments -n banquito
```

Los Deployments deben aparecer con:

```text
READY 0/0
```

### Borrar Pods trabados

Si quedan Pods en `Pending`, `ImagePullBackOff`, `ErrImagePull` o `InvalidImageName`:

```powershell
kubectl delete pod --all -n banquito
```

Verificar:

```powershell
kubectl get pods -n banquito
```

### Borrar todo el namespace si ya no se va a probar

Esto elimina Deployments, Services, ConfigMap y Secret del namespace:

```powershell
kubectl delete namespace banquito
```

Usar esto solo si se quiere detener completamente la prueba en Kubernetes.

### Problema local detectado

Al intentar validar desde esta maquina, `kubectl` fallo con:

```text
Unable to connect to the server: proxyconnect tcp: dial tcp 127.0.0.1:9
```

Esto indica que la configuracion local de proxy esta interfiriendo con `kubectl`. Si ocurre, revisar variables de entorno:

```powershell
Get-ChildItem Env:HTTP_PROXY
Get-ChildItem Env:HTTPS_PROXY
Get-ChildItem Env:NO_PROXY
```

Para la sesion actual de PowerShell, se pueden limpiar asi:

```powershell
Remove-Item Env:HTTP_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:HTTPS_PROXY -ErrorAction SilentlyContinue
Remove-Item Env:NO_PROXY -ErrorAction SilentlyContinue
```

Luego reintentar:

```powershell
kubectl get pods -n banquito
```

### Si es GKE Autopilot

En Autopilot, cuando se crean muchos Pods al mismo tiempo, puede tardar algunos minutos en aprovisionar capacidad. Esperar y volver a revisar:

```powershell
kubectl get pods -n banquito -w
```

Si despues de varios minutos siguen en `Pending`, revisar eventos:

```powershell
kubectl get events -n banquito --sort-by=.lastTimestamp
```

### Si el evento indica falta de recursos

Si aparece algo como `Insufficient cpu`, `Insufficient memory` o problemas de quota, reducir temporalmente replicas o requests.

Para bajar todos los Deployments a 1 replica:

```powershell
kubectl scale deployment --all --replicas=1 -n banquito
```

Luego revisar:

```powershell
kubectl get pods -n banquito
```

Tambien se pueden reducir los `resources.requests` en los `deployment.yaml` si la cuota del proyecto es pequena.

Para ver eventos si un Pod no queda `Running`:

```powershell
kubectl describe pod -n banquito <nombre-del-pod>
```

Para seguir el rollout:

```powershell
kubectl rollout status deployment/account-core-service -n banquito
```

## Resultado real de despliegue completo

Se verifico que Artifact Registry contiene las 12 imagenes:

```powershell
gcloud artifacts docker images list us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito --format="value(IMAGE)"
```

Se aplicaron los manifiestos completos:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl --insecure-skip-tls-verify=true apply --validate=false --recursive -f .
```

Se corrigio el error de pull contra Artifact Registry:

```text
failed to fetch oauth token: 403 Forbidden
```

Causa:

```text
La cuenta de servicio del cluster no tenia permiso de lectura sobre Artifact Registry.
```

Cuenta usada por GKE:

```text
69503932816-compute@developer.gserviceaccount.com
```

Comando aplicado:

```powershell
gcloud artifacts repositories add-iam-policy-binding banquito `
  --location=us-central1 `
  --project=project-47695a8e-7cb2-4352-af2 `
  --member=serviceAccount:69503932816-compute@developer.gserviceaccount.com `
  --role=roles/artifactregistry.reader
```

Luego se recrearon los Pods:

```powershell
kubectl --insecure-skip-tls-verify=true delete pod --all -n banquito
```

Estado final observado:

```text
Todos los Deployments y Services existen en el namespace banquito.
Las imagenes ya se descargan correctamente desde Artifact Registry.
Los frontends operador y empresas quedaron Ready 1/1.
Varios backends quedaron Running pero no Ready por configuracion de base de datos.
Algunos Pods quedaron Pending por falta de capacidad en GKE Autopilot.
```

Ejemplo de error de aplicacion real:

```text
Driver org.postgresql.Driver claims to not accept jdbcUrl, replace-with-cloud-sql-url
```

Conclusion:

```text
Kubernetes, Artifact Registry e IAM ya estan funcionando. El siguiente bloqueo no es Docker ni pull de imagenes; falta reemplazar placeholders de base de datos/Rabbit/OAuth por servicios reales de nube y resolver capacidad/cuota del cluster.
```

Comando para detener costo de Pods si no se esta probando:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito
```

## Estado posterior observado

Salida observada:

```text
account-core-service      CrashLoopBackOff
accounting-service        CrashLoopBackOff
clearinghouse-service     CrashLoopBackOff
file-reception-service    CrashLoopBackOff
notification-service      CrashLoopBackOff
operador-frontend         Running 1/1
web-empresas-frontend     Running 1/1
party-service             Pending
report-service            Pending
tariff-service            Pending
teller-frontend           Pending
web-personas-frontend     Pending
```

Interpretacion:

```text
CrashLoopBackOff ya no es problema de imagen ni de Artifact Registry. El contenedor arranca, pero la aplicacion termina con error.
Pending no es problema de la aplicacion. Kubernetes no consigue nodo/capacidad suficiente para programar el Pod.
```

Diagnostico confirmado por logs:

```text
replace-with-cloud-sql-url
```

Esto indica que todavia existen placeholders de base de datos en `ConfigMap` o `Secret`. Los backends no pueden quedar `Ready` hasta reemplazar esos valores por endpoints reales de Cloud SQL, MongoDB, RabbitMQ, OAuth y demas servicios cloud.

Accion recomendada para no seguir consumiendo mientras se configuran servicios externos:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service clearinghouse-service file-reception-service notification-service party-service report-service tariff-service --replicas=0 -n banquito
```

Dejar solo frontends que ya estan `Running`:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

Cuando ya existan URLs reales de servicios cloud, actualizar:

```text
k8s/configmap.yaml
k8s/secret.yaml
```

y aplicar:

```powershell
kubectl --insecure-skip-tls-verify=true apply --validate=false --recursive -f .
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=1 -n banquito
```

## Prueba por bloques para proyecto universitario

Como el cluster GKE Autopilot mostro falta de capacidad (`Pending`, `Insufficient memory`, `Too many pods`, `GCE out of resources`), la estrategia de prueba sera levantar la plataforma por bloques.

### 1. Apagar todo

Este comando fue ejecutado correctamente y dejo todos los Deployments en `0/0`:

```powershell
$deployments = 'account-core-service','accounting-service','clearinghouse-service','file-reception-service','notification-service','operador-frontend','party-service','report-service','tariff-service','teller-frontend','web-empresas-frontend','web-personas-frontend'
kubectl --insecure-skip-tls-verify=true scale deployment $deployments --replicas=0 -n banquito
```

Verificacion:

```powershell
kubectl --insecure-skip-tls-verify=true get deployments -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

Resultado esperado:

```text
Deployments READY 0/0
No resources found in banquito namespace.
```

### 2. Bloque Frontends

Levantar solo frontends:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment operador-frontend teller-frontend web-empresas-frontend web-personas-frontend --replicas=1 -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

Si algun frontend queda `Pending`, probar solo dos:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment operador-frontend web-empresas-frontend --replicas=1 -n banquito
```

### 3. Bloque Core Bancario

Apagar frontends si se necesita liberar capacidad:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment operador-frontend teller-frontend web-empresas-frontend web-personas-frontend --replicas=0 -n banquito
```

Levantar Core:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
kubectl --insecure-skip-tls-verify=true logs -n banquito deployment/account-core-service --tail=80
```

Nota:

```text
Si aparece CrashLoopBackOff, revisar ConfigMap/Secret. Actualmente los backends aun tienen placeholders de servicios cloud.
```

### 4. Bloque Switch de Pagos Masivos

Apagar Core si se necesita liberar capacidad:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service party-service --replicas=0 -n banquito
```

Levantar Switch:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment file-reception-service tariff-service clearinghouse-service report-service notification-service --replicas=1 -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

### 5. Volver a apagar todo

```powershell
$deployments = 'account-core-service','accounting-service','clearinghouse-service','file-reception-service','notification-service','operador-frontend','party-service','report-service','tariff-service','teller-frontend','web-empresas-frontend','web-personas-frontend'
kubectl --insecure-skip-tls-verify=true scale deployment $deployments --replicas=0 -n banquito
```

Esta es la forma recomendada para controlar costos durante pruebas.

## Configuracion de Cloud SQL recibida

Se recibieron IPs publicas de Cloud SQL:

```text
MySQL 8.4:      136.111.132.119
PostgreSQL 18:  136.112.87.173
```

Se actualizaron manifiestos para usar:

```text
account-core-service   -> jdbc:postgresql://136.112.87.173:5432/banquito
accounting-service     -> jdbc:postgresql://136.112.87.173:5432/banquito
party-service          -> jdbc:mysql://136.111.132.119:3306/partydb
file-reception-service -> jdbc:mysql://136.111.132.119:3306/filedb
tariff-service         -> jdbc:mysql://136.111.132.119:3306/tariffdb
```

Validacion local:

```powershell
kubectl create --dry-run=client --validate=false --recursive -f banquito-infra\k8s
```

Resultado:

```text
Todos los manifiestos fueron parseados correctamente.
```

Pendiente antes de esperar `Running/Ready` en backends:

```text
1. Colocar usuarios y contrasenas reales en secret.yaml.
2. Autorizar la red de GKE en Cloud SQL o usar Cloud SQL Auth Proxy/Connector.
3. Configurar MongoDB y RabbitMQ reales para servicios del Switch.
```

## Ajuste para evitar Pending durante actualizaciones

Se detecto que `RollingUpdate` podia dejar Pods nuevos en `Pending` porque Kubernetes intentaba crear el nuevo Pod antes de eliminar el anterior.

En un cluster con poca capacidad esto aumenta temporalmente el numero de Pods y dispara:

```text
Insufficient memory
Too many pods
GCE out of resources
```

Se cambio la estrategia de todos los Deployments a:

```yaml
strategy:
  type: Recreate
```

Efecto:

```text
Kubernetes elimina el Pod anterior y despues crea el nuevo.
```

Esto es adecuado para el ambiente demo porque reduce consumo durante despliegues. Para produccion se recomienda volver a `RollingUpdate` cuando exista capacidad suficiente.

## Limpieza de ReplicaSets y Secret real

Se revisaron ReplicaSets:

```powershell
kubectl --insecure-skip-tls-verify=true get rs -n banquito
```

Se eliminaron ReplicaSets antiguos con `spec.replicas=0`:

```text
account-core-service-7f6944874d
accounting-service-6764db6b79
file-reception-service-c98db4f96
party-service-6c6dc9cd7f
tariff-service-5b5cbf5c78
```

El Secret `banquito-secrets` tenia placeholders codificados en base64:

```text
replace-with-db-user
replace-with-db-password
replace-with-mongodb-uri
replace-with-rabbitmq-password
```

Se reemplazo directamente en Kubernetes con valores reales, sin guardar passwords reales en `secret.yaml`.

Resultado verificado:

```text
account-core-service conecto correctamente a PostgreSQL 18.
clearinghouse-service conecto correctamente a Mongo Atlas.
```

Tambien se agrego al ConfigMap:

```yaml
MANAGEMENT_HEALTH_MAIL_ENABLED: "false"
```

Motivo:

```text
El health check de mail intentaba validar SMTP aunque SMTP no esta configurado para esta prueba.
```

Estado posterior:

```text
Los CrashLoopBackOff por placeholders fueron corregidos.
Los Pods que siguen Pending son por capacidad/scheduling del cluster.
Los Pods Running pero 0/1 requieren revisar readiness especifica con logs y describe.
```

## Prueba por bloques ejecutada

### Core Bancario

Se apagaron los demas servicios y se levanto solo Core:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment clearinghouse-service file-reception-service notification-service report-service tariff-service operador-frontend teller-frontend web-empresas-frontend web-personas-frontend --replicas=0 -n banquito
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito
```

Resultado:

```text
account-core-service   1/1 Running
accounting-service     1/1 Running
party-service          1/1 Running
```

Logs verificados:

```text
account-core-service conecto a PostgreSQL 18.
accounting-service conecto a PostgreSQL 18.
party-service conecto a MySQL 8.4.
```

Conclusion:

```text
Core Bancario corre correctamente por bloque en GKE.
```

### Switch de Pagos Masivos

Se apago Core y se levanto Switch:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service party-service --replicas=0 -n banquito
kubectl --insecure-skip-tls-verify=true scale deployment file-reception-service tariff-service clearinghouse-service report-service notification-service --replicas=1 -n banquito
```

Resultado:

```text
notification-service    1/1 Running
report-service          1/1 Running
tariff-service          1/1 Running
file-reception-service  0/1 Running
clearinghouse-service   0/1 Running
```

Logs verificados:

```text
file-reception-service conecto a MySQL filedb.
file-reception-service conecto a Mongo Atlas.
tariff-service conecto a MySQL tariffdb.
notification-service conecto a Mongo Atlas.
report-service conecto a Mongo Atlas.
```

Bloqueo detectado:

```text
file-reception-service intenta conectar a RabbitMQ en 35.184.45.161:5672 y recibe timeout.
```

Conclusion:

```text
Switch esta correctamente desplegado y conectado a bases/Mongo, pero depende de corregir acceso a RabbitMQ.
```

Acciones para RabbitMQ:

```text
1. Verificar que RabbitMQ este levantado.
2. Verificar que RabbitMQ escuche en 0.0.0.0:5672 y no solo localhost.
3. Abrir firewall TCP 5672 hacia la red/origen de GKE.
4. Preferible para entrega final: usar RabbitMQ administrado o servicio cloud equivalente.
```

## Decision: un cluster vs dos clusters

No es obligatorio separar en dos clusters. La arquitectura puede funcionar asi:

```text
Un solo cluster GKE
Namespace banquito
Core y Switch como Deployments separados
API Manager como entrada/control de integraciones
```

El problema actual no es de arquitectura, sino de capacidad del cluster/proyecto:

```text
Too many pods
Insufficient memory
GCE out of resources
```

Opciones:

```text
1. Mantener un solo cluster y pedir mas cuota/capacidad.
2. Usar GKE Standard con nodos mas grandes.
3. Separar Core y Switch en dos clusters si se quiere aislar cargas o si la cuota actual no permite correr todo junto.
4. Para demo universitaria, probar por bloques y explicar la limitacion de capacidad.
```

Si se usan dos clusters:

```text
Cluster 1: Core Bancario
Cluster 2: Switch de Pagos Masivos
Comunicacion entre dominios: API Manager
Servicios internos de cada dominio: Kubernetes Service
Bases, RabbitMQ, OAuth: servicios cloud externos
```
