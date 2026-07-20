# Fase 9 - GitHub Actions para GKE

## Objetivo

Eliminar el despliegue anterior basado en:

```text
GitHub Actions -> SSH -> VM -> docker compose
```

y reemplazarlo por un flujo orientado a Kubernetes:

```text
GitHub Actions -> Google Cloud -> Artifact Registry -> GKE -> kubectl apply
```

## Cambio aplicado en banquito-infra

Se reemplazo:

```text
.github/workflows/deploy.yml
```

Antes:

- conectaba por SSH a una VM;
- regeneraba `.env`;
- aplicaba scripts SQL;
- ejecutaba `docker compose down`;
- ejecutaba `docker compose up -d`.

Ahora:

- autentica contra Google Cloud;
- obtiene credenciales del cluster GKE;
- prepara los manifiestos Kubernetes;
- valida los YAML con `kubectl create --dry-run=client`;
- aplica los manifiestos con `kubectl apply --recursive`;
- muestra `Services` y `Pods`.

## Workflow nuevo

Archivo:

```text
banquito-infra/.github/workflows/deploy.yml
```

Flujo:

```text
checkout
auth Google Cloud
setup gcloud
get GKE credentials
prepare manifests
kubectl dry-run
kubectl apply
kubectl get svc
kubectl get pods
```

## Secretos requeridos en GitHub

En el repositorio `banquito-infra` deben existir estos secrets:

```text
GCP_SA_KEY
GCP_PROJECT_ID
GKE_CLUSTER
GKE_LOCATION
ARTIFACT_REGION
ARTIFACT_REPOSITORY
```

Ejemplo:

```text
GCP_PROJECT_ID=project-47695a8e-7cb2-4352-af2
GKE_CLUSTER=banquito-cluster
GKE_LOCATION=us-central1
ARTIFACT_REGION=us-central1
ARTIFACT_REPOSITORY=banquito
```

`GCP_SA_KEY` debe ser el JSON de una cuenta de servicio con permisos para:

- leer/escribir Artifact Registry, si se usa en pipelines de servicios;
- obtener credenciales del cluster GKE;
- aplicar recursos Kubernetes.

## Plantilla para microservicios

El repo `banquito-infra` no contiene el codigo Maven de los microservicios, por eso no puede compilar todos los servicios directamente desde este workflow.

Para los repos de cada microservicio se agrego una plantilla:

```text
banquito-infra/templates/github-actions-gke-service.yml
```

Esa plantilla si hace:

```text
Maven package
Docker build
Docker push a Artifact Registry
kubectl set image
kubectl rollout status
```

Cada microservicio debe copiar esa plantilla a:

```text
.github/workflows/deploy.yml
```

y reemplazar:

```text
SERVICE_NAME
DEPLOYMENT_NAME
```

Ejemplo para `account-core-service`:

```yaml
SERVICE_NAME: account-core-service
DEPLOYMENT_NAME: account-core-service
```

## Comandos equivalentes del pipeline

Autenticacion:

```bash
gcloud auth configure-docker us-central1-docker.pkg.dev --quiet
```

Build Maven:

```bash
mvn -q -DskipTests package
```

Build Docker:

```bash
docker build -t us-central1-docker.pkg.dev/PROJECT_ID/banquito/account-core-service:GITHUB_SHA .
```

Push:

```bash
docker push us-central1-docker.pkg.dev/PROJECT_ID/banquito/account-core-service:GITHUB_SHA
```

Deploy:

```bash
kubectl set image deployment/account-core-service account-core-service=us-central1-docker.pkg.dev/PROJECT_ID/banquito/account-core-service:GITHUB_SHA -n banquito
kubectl rollout status deployment/account-core-service -n banquito
```

Infra apply:

```bash
kubectl apply --recursive -f rendered-k8s
```

## Nota importante

La solucion final deberia quedar asi:

- cada repositorio de microservicio construye y publica su propia imagen;
- `banquito-infra` aplica los manifiestos y mantiene la configuracion Kubernetes;
- Artifact Registry se usa como registro oficial de imagenes;
- GHCR queda solo como opcion temporal de prueba.

## Decision aplicada: usar Artifact Registry

Se decidio dejar de usar GHCR para el despliegue en GKE porque GHCR respondio:

```text
401 Unauthorized
```

El registro oficial para Google Cloud queda:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito
```

Los Deployments ahora apuntan directamente a Artifact Registry:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest
```

Y el mismo patron para el resto de servicios.

## Crear repositorio Artifact Registry

Si el repositorio `banquito` no existe, crearlo:

```powershell
gcloud artifacts repositories create banquito `
  --repository-format=docker `
  --location=us-central1 `
  --description="Imagenes Docker BanQuito"
```

Configurar Docker para autenticarse contra Artifact Registry:

```powershell
gcloud auth configure-docker us-central1-docker.pkg.dev
```

## Bloqueos locales encontrados

Al intentar avanzar localmente se encontro:

```text
Docker Desktop no estaba corriendo.
mvn no esta instalado globalmente, pero los repos Core tienen mvnw.cmd.
gcloud artifacts repositories list falla por SSL local en esta sesion.
docker push falla porque gcloud no puede refrescar tokens por SSLCertVerificationError.
```

Por eso la construccion/subida de imagenes debe hacerse desde:

- GitHub Actions, usando la plantilla de servicio; o
- una terminal local con Docker Desktop corriendo, Maven disponible y gcloud autenticado correctamente.

## Resultado local parcial

Se logro:

```text
Artifact Registry creado.
Docker configurado para us-central1-docker.pkg.dev.
account-core-service compilado con Maven Wrapper.
account-core-service construido como imagen Docker local.
```

Comandos exitosos:

```powershell
gcloud artifacts repositories create banquito --repository-format=docker --location=us-central1 --description="Imagenes Docker BanQuito"
gcloud auth configure-docker us-central1-docker.pkg.dev
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-account-core-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest .
```

Bloqueo actual:

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest
```

Error:

```text
gcloud.auth.docker-helper
There was a problem refreshing your current auth tokens
SSLCertVerificationError: certificate verify failed
Please run: gcloud auth login
```

Comandos para reautenticar:

```powershell
gcloud auth login
gcloud config set project project-47695a8e-7cb2-4352-af2
gcloud auth configure-docker us-central1-docker.pkg.dev
```

## Comandos para construir y subir 3 servicios Core localmente

### account-core-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-account-core-service
mvn -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest
```

### accounting-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-accounting-service
mvn -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest
```

### party-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-party-service
mvn -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest
```

Despues aplicar manifiestos:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply --recursive -f .
kubectl rollout restart deployment account-core-service accounting-service party-service -n banquito
kubectl get pods -n banquito
```

## Comandos utilizados

### Revisar workflow anterior

```powershell
Get-Content banquito-infra\.github\workflows\deploy.yml
```

### Listar workflows existentes

```powershell
Get-ChildItem -Path banquito-infra\.github\workflows -File | Select-Object Name,FullName
```

### Revisar estado Git antes del cambio

```powershell
git -C banquito-infra status --short
```

### Revisar plantilla anterior de CI

```powershell
Get-Content banquito-infra\.github\workflows\ci-template.yml
```

### Buscar imagenes actuales en manifiestos

```powershell
rg -n "PROJECT_ID|ghcr.io|us-central1-docker.pkg.dev|image:" banquito-infra\k8s -S
```

### Verificar que workflows activos ya no usen SSH ni Docker Compose

```powershell
rg -n "ssh|docker compose|VM_|appleboy|compose" banquito-infra\.github\workflows banquito-infra\templates\github-actions-gke-service.yml banquito-infra\docs\fase-9-github-actions.md -S
```

Resultado:

```text
Solo quedaron referencias historicas dentro del documento de Fase 9 explicando lo que se elimino.
Los workflows activos ya no usan SSH, VM ni Docker Compose.
```

### Revisar workflows nuevos

```powershell
Get-Content banquito-infra\.github\workflows\deploy.yml
Get-Content banquito-infra\.github\workflows\ci-template.yml
```

### Revisar estado Git despues del cambio

```powershell
git -C banquito-infra status --short
```

## Resultado real con Artifact Registry

Se creo y uso el repositorio:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito
```

Se publicaron imagenes para:

```text
account-core-service
accounting-service
party-service
file-reception-service
tariff-service
clearinghouse-service
report-service
notification-service
teller-frontend
web-personas-frontend
web-empresas-frontend
operador-frontend
```

Comando de verificacion:

```powershell
gcloud artifacts docker images list us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito --format="value(IMAGE)"
```

Tambien se corrigio el permiso requerido para que GKE descargue imagenes:

```powershell
gcloud artifacts repositories add-iam-policy-binding banquito `
  --location=us-central1 `
  --project=project-47695a8e-7cb2-4352-af2 `
  --member=serviceAccount:69503932816-compute@developer.gserviceaccount.com `
  --role=roles/artifactregistry.reader
```

Esto confirma el flujo requerido por la fase:

```text
Build -> Docker -> Artifact Registry -> GKE
```

Pendiente para automatizacion total:

```text
Copiar la plantilla de workflow a cada microservicio para que GitHub Actions haga el build/push/deploy automaticamente con cada cambio.
```

## Como se cumple el requisito de pipelines

El requisito pide:

```text
Se debe crear flujos (pipelines) para el despliegue automatizado de las aplicaciones en el orquestador de contenedores.
```

La solucion propuesta queda dividida en dos tipos de pipeline:

### 1. Pipeline por microservicio

Cada repositorio de aplicacion debe ejecutar:

```text
checkout
build/test
docker build
docker push a Artifact Registry
kubectl set image o actualizar manifiesto
kubectl rollout status
```

Plantilla creada:

```text
banquito-infra/templates/github-actions-gke-service.yml
```

Esa plantilla se copia en cada repo como:

```text
.github/workflows/deploy.yml
```

y se reemplaza:

```text
SERVICE_NAME
DEPLOYMENT_NAME
```

### 2. Pipeline de infraestructura aplicativa

El repositorio `banquito-infra` ejecuta:

```text
checkout
auth Google Cloud
get GKE credentials
kubectl dry-run
kubectl apply --recursive
kubectl get pods/services
```

Archivo:

```text
banquito-infra/.github/workflows/deploy.yml
```

### Relacion con la prueba manual

Los comandos manuales usados equivalen al pipeline:

```powershell
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/<deployment> -n banquito
```

En GitHub Actions se reemplaza `latest` por:

```text
${{ github.sha }}
```

para tener despliegues trazables.
