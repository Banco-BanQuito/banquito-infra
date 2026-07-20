# Guia operativa para subir microservicios a GKE

Esta guia resume los comandos practicos para:

- subir una nueva version de un microservicio;
- publicar imagenes en Artifact Registry;
- aplicar cambios en Kubernetes;
- levantar servicios por bloques;
- apagar Pods para controlar costos.

Proyecto GCP:

```text
project-47695a8e-7cb2-4352-af2
```

Artifact Registry:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito
```

Namespace Kubernetes:

```text
banquito
```

## 1. Preparar terminal

```powershell
$env:HTTP_PROXY=''
$env:HTTPS_PROXY=''
$env:NO_PROXY=''
gcloud config set project project-47695a8e-7cb2-4352-af2
gcloud auth configure-docker us-central1-docker.pkg.dev
```

Validar contexto de Kubernetes:

```powershell
kubectl config current-context
kubectl --insecure-skip-tls-verify=true get namespace banquito
```

## 2. Aplicar manifiestos Kubernetes

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl --insecure-skip-tls-verify=true apply --validate=false --recursive -f .
```

Verificar:

```powershell
kubectl --insecure-skip-tls-verify=true get deployments -n banquito
kubectl --insecure-skip-tls-verify=true get svc -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

## 3. Apagar todo para no consumir

```powershell
$deployments = 'account-core-service','accounting-service','clearinghouse-service','file-reception-service','notification-service','operador-frontend','party-service','report-service','tariff-service','teller-frontend','web-empresas-frontend','web-personas-frontend'
kubectl --insecure-skip-tls-verify=true scale deployment $deployments --replicas=0 -n banquito
```

Verificar:

```powershell
kubectl --insecure-skip-tls-verify=true get deployments -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

## 4. Levantar por bloques

### Frontends

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment operador-frontend teller-frontend web-empresas-frontend web-personas-frontend --replicas=1 -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

### Core Bancario

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment operador-frontend teller-frontend web-empresas-frontend web-personas-frontend --replicas=0 -n banquito
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

### Switch de Pagos Masivos

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service party-service --replicas=0 -n banquito
kubectl --insecure-skip-tls-verify=true scale deployment file-reception-service tariff-service clearinghouse-service report-service notification-service --replicas=1 -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

## 5. Subir mejora de un backend Java

Patron general:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\<repo>
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/<deployment> -n banquito
kubectl --insecure-skip-tls-verify=true rollout status deployment/<deployment> -n banquito
```

### account-core-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-account-core-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/account-core-service -n banquito
```

### accounting-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-accounting-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/accounting-service -n banquito
```

### party-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-party-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/party-service -n banquito
```

### file-reception-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-file-reception-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/file-reception-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/file-reception-service:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/file-reception-service -n banquito
```

### tariff-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-tariff-service\banquito-tariff-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/tariff-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/tariff-service:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/tariff-service -n banquito
```

### clearinghouse-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-clearinghouse-service\banquito-clearinghouse-service
.\mvnw.cmd -q -DskipTests package
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-clearinghouse-service
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/clearinghouse-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/clearinghouse-service:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/clearinghouse-service -n banquito
```

### report-service

Si Maven no esta instalado localmente, usar Maven dentro de Docker:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-report-service
docker run --rm -v ${PWD}:/workspace -w /workspace maven:3.9.9-eclipse-temurin-21 mvn -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/report-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/report-service:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/report-service -n banquito
```

### notification-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-notification-service
docker run --rm -v ${PWD}:/workspace -w /workspace maven:3.9.9-eclipse-temurin-21 mvn -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/notification-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/notification-service:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/notification-service -n banquito
```

## 6. Subir mejora de un frontend

Patron general:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\<repo-frontend>
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/<deployment> -n banquito
```

### teller-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-teller-frontend
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/teller-frontend:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/teller-frontend:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/teller-frontend -n banquito
```

### web-personas-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-web-personas-frontend
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/web-personas-frontend -n banquito
```

### web-empresas-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-web-empresas-frontend
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-empresas-frontend:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-empresas-frontend:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/web-empresas-frontend -n banquito
```

### operador-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-frontend-web-operador
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/operador-frontend:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/operador-frontend:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/operador-frontend -n banquito
```

## 7. Ver logs y errores

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito
kubectl --insecure-skip-tls-verify=true describe pod -n banquito <pod>
kubectl --insecure-skip-tls-verify=true logs -n banquito <pod> --tail=100
```

Logs por Deployment:

```powershell
kubectl --insecure-skip-tls-verify=true logs -n banquito deployment/account-core-service --tail=100
```

## 8. Errores esperados

### Pending

```text
Insufficient memory
Too many pods
GCE out of resources
```

Solucion:

```text
Probar por bloques o pedir mas capacidad/cuota en GKE.
```

### CrashLoopBackOff

```text
La imagen arranco, pero la aplicacion fallo.
```

Revisar logs:

```powershell
kubectl --insecure-skip-tls-verify=true logs -n banquito <pod> --tail=100
```

Si aparece:

```text
replace-with-cloud-sql-url
```

falta actualizar:

```text
banquito-infra/k8s/configmap.yaml
banquito-infra/k8s/secret.yaml
```

## 10. Configuracion actual de bases Cloud SQL

Se configuraron las IPs publicas indicadas:

```text
MySQL 8.4:       136.111.132.119
PostgreSQL 18:   136.112.87.173
MySQL connection name:
project-47695a8e-7cb2-4352-af2:us-central1:banquito-mysql
```

URLs configuradas:

```text
account-core-service:     jdbc:postgresql://136.112.87.173:5432/banquito
accounting-service:       jdbc:postgresql://136.112.87.173:5432/banquito
party-service:            jdbc:mysql://136.111.132.119:3306/partydb
file-reception-service:   jdbc:mysql://136.111.132.119:3306/filedb
tariff-service:           jdbc:mysql://136.111.132.119:3306/tariffdb
```

Archivos modificados:

```text
banquito-infra/k8s/configmap.yaml
banquito-infra/k8s/secret.yaml
banquito-infra/k8s/account-core/deployment.yaml
banquito-infra/k8s/accounting/deployment.yaml
banquito-infra/k8s/party/deployment.yaml
banquito-infra/k8s/file-reception/deployment.yaml
banquito-infra/k8s/tariff/deployment.yaml
```

Pendiente:

```text
Reemplazar usuarios y passwords reales en secret.yaml.
Configurar MongoDB y RabbitMQ reales para los servicios del Switch.
Verificar que Cloud SQL permita conexiones desde GKE por red autorizada o usar Cloud SQL Auth Proxy/Connector.
```

### Crear Secret real sin guardar passwords en Git

No guardar contrasenas reales en `secret.yaml`. Crear o actualizar el Secret directamente en Kubernetes:

```powershell
$cloudPass = Read-Host "Cloud SQL password"
$mongoPass = Read-Host "MongoDB password"
$rabbitPass = Read-Host "RabbitMQ password"
$smtpPass = Read-Host "SMTP password"

kubectl create secret generic banquito-secrets `
  --namespace banquito `
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
```

Si falla por TLS local:

```powershell
$cloudPass = Read-Host "Cloud SQL password"
$mongoPass = Read-Host "MongoDB password"
$rabbitPass = Read-Host "RabbitMQ password"
$smtpPass = Read-Host "SMTP password"

kubectl create secret generic banquito-secrets `
  --namespace banquito `
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
  --dry-run=client -o yaml | kubectl --insecure-skip-tls-verify=true apply -f -
```

Aplicar configuracion:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply --recursive -f .
```

Si tu terminal vuelve a fallar por TLS local:

```powershell
kubectl --insecure-skip-tls-verify=true apply --validate=false --recursive -f .
```

Probar solo Core:

```powershell
kubectl scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito
kubectl get pods -n banquito
kubectl logs -n banquito deployment/account-core-service --tail=100
```

## 9. Pipeline automatizado requerido

El flujo manual anterior debe convertirse en GitHub Actions:

```text
checkout
build/test
docker build
docker push Artifact Registry
kubectl set image o kubectl apply
kubectl rollout status
```

Plantilla disponible:

```text
banquito-infra/templates/github-actions-gke-service.yml
```

El repo `banquito-infra` mantiene el pipeline de manifiestos:

```text
banquito-infra/.github/workflows/deploy.yml
```

Con esto se cumple:

```text
Las aplicaciones se despliegan en GKE.
Las imagenes se publican en Artifact Registry.
Los despliegues pueden automatizarse con GitHub Actions.
```

## 11. Estrategia de actualizacion en Kubernetes

Para el ambiente demo se usa:

```yaml
strategy:
  type: Recreate
```

Motivo:

```text
El cluster GKE Autopilot tiene poca capacidad disponible. RollingUpdate crea temporalmente Pods duplicados y puede causar Pending por falta de memoria o limite de Pods.
```

Con `Recreate`, Kubernetes baja el Pod viejo antes de crear el nuevo.

Validar:

```powershell
rg -n "strategy:|type: Recreate|RollingUpdate" banquito-infra\k8s -g deployment.yaml
```

Aplicar:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl --insecure-skip-tls-verify=true apply --validate=false --recursive -f .
```

## 12. Limpiar ReplicaSets viejos

Ver ReplicaSets:

```powershell
kubectl --insecure-skip-tls-verify=true get rs -n banquito
```

Eliminar automaticamente los ReplicaSets con 0 replicas:

```powershell
$json = kubectl --insecure-skip-tls-verify=true get rs -n banquito -o json | ConvertFrom-Json
$oldRs = $json.items | Where-Object { $_.spec.replicas -eq 0 } | Select-Object -ExpandProperty metadata | Select-Object -ExpandProperty name
foreach ($rs in $oldRs) {
  kubectl --insecure-skip-tls-verify=true delete rs $rs -n banquito
}
```

Reiniciar backends despues de actualizar Secret o ConfigMap:

```powershell
kubectl --insecure-skip-tls-verify=true rollout restart deployment account-core-service accounting-service clearinghouse-service file-reception-service notification-service party-service report-service tariff-service -n banquito
```

Ver estado:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito -o wide
kubectl --insecure-skip-tls-verify=true get deployments -n banquito
```

## 13. Resultado de pruebas por bloques

### Core Bancario

Core corrio completo:

```text
account-core-service   1/1 Running
accounting-service     1/1 Running
party-service          1/1 Running
```

### Switch de Pagos Masivos

Switch corrio parcialmente:

```text
notification-service    1/1 Running
report-service          1/1 Running
tariff-service          1/1 Running
file-reception-service  0/1 Running
clearinghouse-service   0/1 Running
```

El bloqueo observado fue RabbitMQ:

```text
Attempting to connect to: [35.184.45.161:5672]
Broker not available
java.net.SocketTimeoutException: Connect timed out
```

Para corregir RabbitMQ:

```text
Verificar proceso RabbitMQ.
Abrir firewall TCP 5672.
Confirmar que RabbitMQ escuche en 0.0.0.0.
Confirmar usuario/password/vhost.
Preferible: usar RabbitMQ administrado.
```

## 14. Un cluster o dos clusters

No es obligatorio separar en dos clusters.

Para arquitectura limpia:

```text
Core y Switch pueden vivir en el mismo GKE.
Se pueden separar por namespaces.
El API Manager gobierna el trafico externo y entre dominios.
```

Para tu proyecto actual, el bloqueo para correr todo junto es capacidad:

```text
Too many pods
Insufficient memory
GCE out of resources
```

Opciones:

```text
Opcion A: Un cluster, pedir mas cuota/capacidad o usar GKE Standard con nodos mas grandes.
Opcion B: Dos clusters, uno para Core y otro para Switch, comunicados por API Manager.
Opcion C: Mantener un cluster y probar por bloques para demo.
```

Recomendacion para defensa:

```text
La arquitectura objetivo puede ser un solo orquestador GKE con servicios separados.
La separacion en dos clusters es una decision operacional de capacidad/aislamiento, no una obligacion funcional.
```

## 15. Opcion de cambiar de region

El cluster actual esta en:

```text
us-central1
```

El problema observado fue:

```text
Can't scale up due to exceeded quota
GCE out of resources
Too many pods
Insufficient memory
```

Se revisaron cuotas regionales del proyecto:

```powershell
$project='project-47695a8e-7cb2-4352-af2'
$regions = 'us-central1','us-east1','us-west1','southamerica-east1'
$wanted = 'CPUS','E2_CPUS','N2_CPUS','N2D_CPUS','IN_USE_ADDRESSES','DISKS_TOTAL_GB','SSD_TOTAL_GB','INSTANCES'

foreach ($region in $regions) {
  Write-Host "==== $region ===="
  $data = gcloud compute regions describe $region --project $project --format=json | ConvertFrom-Json
  $data.quotas |
    Where-Object { $wanted -contains $_.metric } |
    Select-Object @{n='Region';e={$region}}, metric, limit, usage, @{n='available';e={[double]$_.limit - [double]$_.usage}} |
    Format-Table -AutoSize
}
```

Resultado relevante:

```text
us-central1:
CPUS disponibles: 24
E2_CPUS disponibles: 8
IP disponibles: 1

us-east1:
CPUS disponibles: 32
E2_CPUS disponibles: 8
IP disponibles: 4

southamerica-east1:
CPUS disponibles: 32
E2_CPUS disponibles: 8
IP disponibles: 4
```

`us-west1` no se pudo validar por un error de conexion local contra la API de Google, por eso no queda como primera opcion.

Recomendacion:

```text
Para seguir en Autopilot, probar primero us-east1.
Tiene cuota limpia, mas IPs disponibles y suele tener buena disponibilidad.
southamerica-east1 tambien es viable, pero puede tener menos disponibilidad/capacidad que regiones de Estados Unidos.
```

### Crear un nuevo cluster Autopilot en us-east1

Usar este comando solo cuando se decida crear el nuevo cluster, porque puede generar costo:

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

Validar contexto:

```powershell
kubectl config current-context
kubectl --insecure-skip-tls-verify=true get nodes
```

Aplicar manifiestos:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl --insecure-skip-tls-verify=true apply --validate=false --recursive -f .
```

Importante:

```text
Si se aplica secret.yaml, se pueden sobrescribir los secretos reales con placeholders.
Despues de aplicar manifiestos, recrear el Secret real usando los valores del ambiente.
```

Levantar por bloques:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

Luego probar Switch:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service party-service --replicas=0 -n banquito
kubectl --insecure-skip-tls-verify=true scale deployment file-reception-service tariff-service clearinghouse-service report-service notification-service --replicas=1 -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

### Si se crea Artifact Registry en otra region

Las imagenes actuales estan en:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito
```

Un cluster en `us-east1` puede descargar imagenes desde `us-central1`, pero para reducir latencia y mantener todo en la misma region se puede crear otro registry:

```powershell
gcloud artifacts repositories create banquito `
  --repository-format=docker `
  --location=us-east1 `
  --description="Imagenes Docker BanQuito"
```

En ese caso tambien hay que cambiar las imagenes en los `deployment.yaml` a:

```text
us-east1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
```

Para la demo, es aceptable mantener Artifact Registry en `us-central1` y mover solo el cluster a `us-east1`.

## 16. Separacion por namespaces

Se separo el despliegue en tres namespaces:

```text
banquito-core       -> Core Bancario
banquito-switch     -> Switch de Pagos Masivos
banquito-frontend   -> Frontends
```

Distribucion:

```text
banquito-core:
account-core-service
accounting-service
party-service

banquito-switch:
file-reception-service
tariff-service
clearinghouse-service
report-service
notification-service

banquito-frontend:
teller-frontend
web-personas-frontend
web-empresas-frontend
operador-frontend
```

Archivos actualizados:

```text
banquito-infra/k8s/namespace.yaml
banquito-infra/k8s/configmap.yaml
banquito-infra/k8s/secret.yaml
banquito-infra/k8s/*/deployment.yaml
banquito-infra/k8s/*/service.yaml
```

Validacion local:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO
kubectl create --dry-run=client --validate=false --recursive -f banquito-infra\k8s
```

Resultado esperado:

```text
namespace/banquito-core created (dry run)
namespace/banquito-switch created (dry run)
namespace/banquito-frontend created (dry run)
configmap/banquito-config created (dry run)
secret/banquito-secrets created (dry run)
deployment.apps/account-core-service created (dry run)
...
```

### DNS interno entre namespaces

Cuando los servicios estan en namespaces distintos, se usa DNS completo de Kubernetes:

```text
account-core-service.banquito-core.svc.cluster.local
accounting-service.banquito-core.svc.cluster.local
party-service.banquito-core.svc.cluster.local
file-reception-service.banquito-switch.svc.cluster.local
tariff-service.banquito-switch.svc.cluster.local
notification-service.banquito-switch.svc.cluster.local
```

Esto se configuro en:

```text
banquito-infra/k8s/configmap.yaml
```

### Aplicar al cluster nuevo

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl --insecure-skip-tls-verify=true apply --validate=false --recursive -f .
```

Ver recursos por namespace:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core
kubectl --insecure-skip-tls-verify=true get pods -n banquito-switch
kubectl --insecure-skip-tls-verify=true get pods -n banquito-frontend

kubectl --insecure-skip-tls-verify=true get svc -n banquito-core
kubectl --insecure-skip-tls-verify=true get svc -n banquito-switch
kubectl --insecure-skip-tls-verify=true get svc -n banquito-frontend
```

### Apagar todo por namespace

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-core
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-switch
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-frontend
```

### Levantar por bloques

Core:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=1 -n banquito-core
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core
```

Switch:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=1 -n banquito-switch
kubectl --insecure-skip-tls-verify=true get pods -n banquito-switch
```

Frontends:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=1 -n banquito-frontend
kubectl --insecure-skip-tls-verify=true get pods -n banquito-frontend
```

### Recrear Secret real en cada namespace

No guardar contrasenas reales en Git. Crear el Secret real en cada namespace:

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
    --dry-run=client -o yaml | kubectl --insecure-skip-tls-verify=true apply -f -
}
```

## 17. Migracion ejecutada a us-east1

Se intento crear el cluster nuevo en `us-east1` manteniendo el cluster viejo en `us-central1`, pero Google Cloud bloqueo la operacion por cuota global:

```text
CPUS_ALL_REGIONS
quota: 12
available: 4
required: 8
```

Para liberar cuota se apago primero la aplicacion en el cluster viejo:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito
```

Como el cluster viejo seguia consumiendo nodos de sistema, se elimino:

```powershell
gcloud container clusters delete banquito-cluster `
  --project project-47695a8e-7cb2-4352-af2 `
  --region us-central1 `
  --quiet
```

Despues la cuota global quedo:

```text
CPUS_ALL_REGIONS
quota: 12
usage: 4
available: 8
```

Se creo el nuevo cluster:

```powershell
gcloud container clusters create-auto banquito-cluster-east `
  --project project-47695a8e-7cb2-4352-af2 `
  --region us-east1
```

Resultado:

```text
NAME: banquito-cluster-east
LOCATION: us-east1
STATUS: RUNNING
MASTER_VERSION: 1.35.5-gke.1241004
MACHINE_TYPE: ek-standard-8
NUM_NODES: 3
```

Se aplicaron los manifiestos en orden explicito porque `kubectl apply --recursive -f .` puede intentar crear Deployments antes que Namespaces:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s

kubectl --insecure-skip-tls-verify=true apply --validate=false -f namespace.yaml
kubectl --insecure-skip-tls-verify=true apply --validate=false -f configmap.yaml
kubectl --insecure-skip-tls-verify=true apply --validate=false -f secret.yaml

kubectl --insecure-skip-tls-verify=true apply --validate=false -f account-core
kubectl --insecure-skip-tls-verify=true apply --validate=false -f accounting
kubectl --insecure-skip-tls-verify=true apply --validate=false -f party

kubectl --insecure-skip-tls-verify=true apply --validate=false -f file-reception
kubectl --insecure-skip-tls-verify=true apply --validate=false -f tariff
kubectl --insecure-skip-tls-verify=true apply --validate=false -f clearinghouse
kubectl --insecure-skip-tls-verify=true apply --validate=false -f report
kubectl --insecure-skip-tls-verify=true apply --validate=false -f notification

kubectl --insecure-skip-tls-verify=true apply --validate=false -f teller
kubectl --insecure-skip-tls-verify=true apply --validate=false -f personas
kubectl --insecure-skip-tls-verify=true apply --validate=false -f empresas
kubectl --insecure-skip-tls-verify=true apply --validate=false -f operador
```

Para controlar costos, se dejaron todos los Deployments apagados:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-core
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-switch
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-frontend
```

Estado final:

```text
banquito-core:
account-core-service   0/0
accounting-service     0/0
party-service          0/0

banquito-switch:
clearinghouse-service    0/0
file-reception-service   0/0
notification-service     0/0
report-service           0/0
tariff-service           0/0

banquito-frontend:
operador-frontend       0/0
teller-frontend         0/0
web-empresas-frontend   0/0
web-personas-frontend   0/0
```

Siguiente paso obligatorio antes de levantar backends:

```text
Recrear banquito-secrets con valores reales en los tres namespaces.
El archivo secret.yaml del repositorio mantiene placeholders para no guardar passwords en Git.
```

## 18. Validacion de microservicios en Kubernetes

Se reviso el contexto activo:

```text
gke_project-47695a8e-7cb2-4352-af2_us-east1_banquito-cluster-east
```

Se levantaron los microservicios de Core y se verifico:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core -o wide
kubectl --insecure-skip-tls-verify=true get events -n banquito-core --sort-by=.lastTimestamp
kubectl --insecure-skip-tls-verify=true logs -n banquito-core deployment/account-core-service --tail=120
kubectl --insecure-skip-tls-verify=true logs -n banquito-core deployment/accounting-service --tail=120
kubectl --insecure-skip-tls-verify=true logs -n banquito-core deployment/party-service --tail=120
```

Resultado:

```text
account-core-service   CrashLoopBackOff
accounting-service     CrashLoopBackOff
party-service          CrashLoopBackOff
```

Lo que si funciona:

```text
Cluster GKE us-east1 activo.
Namespaces creados.
Deployments creados.
Services creados.
Imagenes descargadas correctamente desde Artifact Registry.
Pods programados en nodo GKE.
```

Evidencia de imagen correcta:

```text
Successfully pulled image "us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest"
Successfully pulled image "us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest"
Successfully pulled image "us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest"
```

Bloqueo real:

```text
Los Secrets aplicados siguen usando placeholders.
```

Validacion ejecutada sin imprimir valores sensibles:

```powershell
$namespaces='banquito-core','banquito-switch','banquito-frontend'
foreach ($ns in $namespaces) {
  Write-Host "==== $ns ===="
  $secret = kubectl --insecure-skip-tls-verify=true get secret banquito-secrets -n $ns -o json | ConvertFrom-Json
  foreach ($key in 'DB_USER','DB_PASS','POSTGRES_USER','POSTGRES_PASSWORD','MONGO_URI','RABBITMQ_USERNAME','RABBITMQ_PASSWORD') {
    $raw = $secret.data.$key
    if ($null -eq $raw) { Write-Host "$key=MISSING"; continue }
    $value = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($raw))
    $isPlaceholder = $value -like 'replace-with-*'
    $len = $value.Length
    Write-Host "$key placeholder=$isPlaceholder length=$len"
  }
}
```

Resultado:

```text
banquito-core:
DB_USER placeholder=True
DB_PASS placeholder=True
POSTGRES_USER placeholder=True
POSTGRES_PASSWORD placeholder=True
MONGO_URI placeholder=True
RABBITMQ_USERNAME placeholder=True
RABBITMQ_PASSWORD placeholder=True

banquito-switch:
DB_USER placeholder=True
DB_PASS placeholder=True
POSTGRES_USER placeholder=True
POSTGRES_PASSWORD placeholder=True
MONGO_URI placeholder=True
RABBITMQ_USERNAME placeholder=True
RABBITMQ_PASSWORD placeholder=True

banquito-frontend:
DB_USER placeholder=True
DB_PASS placeholder=True
POSTGRES_USER placeholder=True
POSTGRES_PASSWORD placeholder=True
MONGO_URI placeholder=True
RABBITMQ_USERNAME placeholder=True
RABBITMQ_PASSWORD placeholder=True
```

Errores observados en logs:

```text
PostgreSQL:
FATAL: password authentication failed for user "postgres"

MySQL:
Access denied for user 'root'@'<ip-salida-gke>' (using password: YES)
```

Conclusion:

```text
La plataforma Kubernetes esta funcionando.
El problema actual no es GKE, Docker, Artifact Registry ni namespaces.
El problema actual es que banquito-secrets tiene placeholders y no credenciales reales.
```

Para detener reinicios mientras se corrige:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-core
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-switch
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-frontend
```

Despues de recrear Secrets reales:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=1 -n banquito-core
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core -w
```

## 19. Error por aplicar desde la carpeta equivocada

No ejecutar este comando desde la raiz del workspace:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO
kubectl apply --recursive -f .
```

Ese comando recorre todos los repositorios y Kubernetes intenta aplicar archivos que no son manifiestos Kubernetes:

```text
.github/workflows/*.yml
docker-compose.yml
package.json
package-lock.json
postman/*.json
application.yml
```

Por eso aparecen errores como:

```text
apiVersion not set, kind not set
```

Forma correcta:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl --insecure-skip-tls-verify=true apply --validate=false -f namespace.yaml
kubectl --insecure-skip-tls-verify=true apply --validate=false -f configmap.yaml
kubectl --insecure-skip-tls-verify=true apply --validate=false -f secret.yaml
kubectl --insecure-skip-tls-verify=true apply --validate=false -f account-core
kubectl --insecure-skip-tls-verify=true apply --validate=false -f accounting
kubectl --insecure-skip-tls-verify=true apply --validate=false -f party
kubectl --insecure-skip-tls-verify=true apply --validate=false -f file-reception
kubectl --insecure-skip-tls-verify=true apply --validate=false -f tariff
kubectl --insecure-skip-tls-verify=true apply --validate=false -f clearinghouse
kubectl --insecure-skip-tls-verify=true apply --validate=false -f report
kubectl --insecure-skip-tls-verify=true apply --validate=false -f notification
kubectl --insecure-skip-tls-verify=true apply --validate=false -f teller
kubectl --insecure-skip-tls-verify=true apply --validate=false -f personas
kubectl --insecure-skip-tls-verify=true apply --validate=false -f empresas
kubectl --insecure-skip-tls-verify=true apply --validate=false -f operador
```

Alternativa en una sola ruta:

```powershell
kubectl --insecure-skip-tls-verify=true apply --validate=false --recursive -f C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
```

Advertencia:

```text
Si aplicas secret.yaml desde Git, se vuelve a configurar banquito-secrets con placeholders.
Despues de aplicar manifiestos, recrear los Secrets reales en los tres namespaces.
```
