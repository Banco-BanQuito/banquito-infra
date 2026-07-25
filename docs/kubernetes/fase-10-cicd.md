# FASE 10 - Automatizacion CI/CD

## Objetivo

Crear pipelines para que los cambios de las aplicaciones se desplieguen automaticamente.

Para backends, el despliegue automatizado termina en el orquestador de contenedores GKE. Para frontends, el despliegue automatizado termina en una VM con Nginx, porque las aplicaciones Vite generan archivos estaticos y ya no se ejecutan como Pods.

El requisito se cumple cuando:

```text
git push
  -> GitHub Actions
  -> build/test
  -> docker build
  -> push Artifact Registry
  -> actualizar Deployment en GKE
  -> verificar rollout
```

Para frontends:

```text
git push
  -> GitHub Actions
  -> leer Secret Manager
  -> npm ci
  -> npm run build
  -> publicar dist en VM/Nginx
```

## Aclaracion importante

Subir una imagen a Artifact Registry por si solo no actualiza Kubernetes.

Kubernetes solo cambia cuando se ejecuta una accion de despliegue, por ejemplo:

```powershell
kubectl set image deployment/<deployment> <container>=<image>:<tag> -n <namespace>
```

o:

```powershell
kubectl rollout restart deployment/<deployment> -n <namespace>
```

Por eso el pipeline debe hacer dos cosas:

```text
1. Publicar la imagen.
2. Ordenar a GKE usar esa nueva imagen.
```

## Estrategia seleccionada

Para las aplicaciones BanQuito se recomienda:

```text
Pipeline de despliegue por repositorio de aplicacion:
  build
  docker build
  docker push
  kubectl set image
  kubectl rollout status

Pipeline CI:
  compile check
  no despliega

Pipeline SonarCloud:
  pruebas
  analisis de calidad
  cobertura

Pipeline de banquito-infra:
  aplicar manifiestos Kubernetes
  aplicar ConfigMap/Gateway/Deployments/Services
```

Decision de buena practica:

```text
No mezclar despliegue, validacion rapida y cobertura en un solo workflow.
Cada flujo tiene una responsabilidad diferente.
```

Separacion aplicada:

| Workflow | Responsabilidad | Ejecuta pruebas |
| --- | --- | --- |
| `ci.yml` | Validacion rapida de compilacion | Temporalmente no |
| `docker-publish.yml` | Backends: build de imagen, push a Artifact Registry y deploy a GKE | No, para no bloquear despliegue por tests legacy |
| `deploy-vm.yml` | Frontends: build Vite y deploy de `dist` a VM/Nginx | No |
| `sonarcloud.yml` | Calidad, pruebas y cobertura | Si |

## Estado implementado

Se reemplazo el workflow `docker-publish.yml` de los repositorios backend para que ya no sea solo publicacion de imagen.

Ahora cada repositorio ejecuta:

```text
git push a main
  -> compilar si es backend Java
  -> docker build
  -> docker push a Artifact Registry con tag github.sha y latest
  -> obtener credenciales de GKE
  -> kubectl set image
  -> kubectl rollout status
```

Repositorios backend cubiertos:

| Repositorio | Imagen | Deployment | Namespace |
| --- | --- | --- | --- |
| `banquito-account-core-service` | `account-core-service` | `account-core-service` | `banquito-core` |
| `banquito-accounting-service` | `accounting-service` | `accounting-service` | `banquito-core` |
| `banquito-party-service` | `party-service` | `party-service` | `banquito-core` |
| `banquito-file-reception-service` | `file-reception-service` | `file-reception-service` | `banquito-switch` |
| `banquito-tariff-service` | `tariff-service` | `tariff-service` | `banquito-switch` |
| `banquito-clearinghouse-service` | `clearinghouse-service` | `clearinghouse-service` | `banquito-switch` |
| `banquito-report-service` | `report-service` | `report-service` | `banquito-switch` |
| `banquito-notification-service` | `notification-service` | `notification-service` | `banquito-switch` |

Repositorios frontend cubiertos:

| Repositorio | Workflow | Destino |
| --- | --- | --- |
| `banquito-teller-frontend` | `deploy-vm.yml` | VM/Nginx |
| `banquito-web-personas-frontend` | `deploy-vm.yml` | VM/Nginx |
| `banquito-web-empresas-frontend` | `deploy-vm.yml` | VM/Nginx |
| `banquito-frontend-web-operador` | `deploy-vm.yml` | VM/Nginx |

## Registro de imagenes

```text
Artifact Registry:
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito
```

Ejemplo de tag trazable:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:<github-sha>
```

Para demo se puede seguir usando:

```text
latest
```

Pero para CI/CD real es mejor usar:

```text
${{ github.sha }}
```

## Autenticacion GitHub Actions con Google Cloud

Inicialmente se considero usar un secret `GCP_SA_KEY` con un JSON de Service Account.

Esa opcion fue descartada porque el proyecto tiene bloqueada la creacion de claves descargables:

```text
constraints/iam.disableServiceAccountKeyCreation
```

La solucion implementada es Workload Identity Federation.

Los workflows ya no necesitan el secret:

```text
GCP_SA_KEY
```

El detalle tecnico, comandos y evidencia estan en:

```text
anexo-f-workload-identity-github-actions.md
```

Los demas valores quedaron definidos directamente en los workflows:

| Valor | Configuracion |
| --- | --- |
| Proyecto GCP | `project-47695a8e-7cb2-4352-af2` |
| Cluster GKE | `banquito-cluster-east` |
| Region GKE | `us-east1` |
| Region Artifact Registry | `us-central1` |
| Repositorio Artifact Registry | `banquito` |

Permisos minimos de la Service Account:

```text
roles/artifactregistry.writer
roles/container.developer
roles/container.clusterViewer
```

## Plantilla de pipeline para backend Java

Ejemplo para `account-core-service`.

Archivo:

```text
.github/workflows/deploy-gke.yml
```

```yaml
name: Build and Deploy to GKE

on:
  push:
    branches:
      - main
  workflow_dispatch:

env:
  PROJECT_ID: project-47695a8e-7cb2-4352-af2
  AR_LOCATION: us-central1
  AR_REPOSITORY: banquito
  GKE_CLUSTER: banquito-cluster-east
  GKE_REGION: us-east1
  IMAGE_NAME: account-core-service
  DEPLOYMENT_NAME: account-core-service
  CONTAINER_NAME: account-core-service
  NAMESPACE: banquito-core

jobs:
  deploy:
    runs-on: ubuntu-latest

    permissions:
      contents: read
      id-token: write

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: "21"

      - name: Build Maven
        run: ./mvnw -q -Dmaven.test.skip=true package

      - name: Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          workload_identity_provider: projects/69503932816/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider
          service_account: github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com

      - name: Set up gcloud
        uses: google-github-actions/setup-gcloud@v2

      - name: Configure Docker for Artifact Registry
        run: gcloud auth configure-docker $AR_LOCATION-docker.pkg.dev --quiet

      - name: Build Docker image
        run: |
          docker build \
            -t $AR_LOCATION-docker.pkg.dev/$PROJECT_ID/$AR_REPOSITORY/$IMAGE_NAME:${{ github.sha }} \
            -t $AR_LOCATION-docker.pkg.dev/$PROJECT_ID/$AR_REPOSITORY/$IMAGE_NAME:latest \
            .

      - name: Push Docker image
        run: |
          docker push $AR_LOCATION-docker.pkg.dev/$PROJECT_ID/$AR_REPOSITORY/$IMAGE_NAME:${{ github.sha }}
          docker push $AR_LOCATION-docker.pkg.dev/$PROJECT_ID/$AR_REPOSITORY/$IMAGE_NAME:latest

      - name: Get GKE credentials
        uses: google-github-actions/get-gke-credentials@v2
        with:
          cluster_name: ${{ env.GKE_CLUSTER }}
          location: ${{ env.GKE_REGION }}
          project_id: ${{ env.PROJECT_ID }}

      - name: Deploy image to GKE
        run: |
          kubectl set image deployment/$DEPLOYMENT_NAME \
            $CONTAINER_NAME=$AR_LOCATION-docker.pkg.dev/$PROJECT_ID/$AR_REPOSITORY/$IMAGE_NAME:${{ github.sha }} \
            -n $NAMESPACE

      - name: Verify rollout
        run: kubectl rollout status deployment/$DEPLOYMENT_NAME -n $NAMESPACE --timeout=180s
```

Regla aplicada:

```text
Si `kubectl rollout status` falla, el workflow de despliegue debe fallar.
No se oculta el error como warning, porque un deploy que no queda disponible no debe marcarse como exitoso.
```

## Plantilla de CI rapido

El workflow `ci.yml` queda solo para validar que el proyecto compila.

```yaml
name: CI Compile Check

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  compile:
    name: Compile package
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Java 21
        uses: actions/setup-java@v4
        with:
          java-version: "21"
          distribution: temurin
          cache: maven

      - name: Build package
        run: mvn -q -Dmaven.test.skip=true package
```

Nota:

```text
`maven.test.skip=true` es temporal mientras se estabilizan pruebas unitarias.
Cuando las pruebas esten corregidas, este flujo puede cambiar a `mvn test` o `mvn verify`.
```

## Plantilla de SonarCloud

SonarCloud debe ejecutar pruebas porque es el flujo responsable de calidad y cobertura.

```yaml
- name: Build and analyze
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
  run: >
    mvn -B verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar
    -DskipTests=false
    -Dsonar.projectKey=<project-key>
    -Dsonar.organization=banco-banquito
    -Dsonar.host.url=https://sonarcloud.io
```

Si los tests estan rotos, Sonar debe fallar. Ese fallo corresponde a calidad/cobertura, no al despliegue operativo.

## Variables por microservicio

| Repositorio | IMAGE_NAME | DEPLOYMENT_NAME | CONTAINER_NAME | NAMESPACE |
| --- | --- | --- | --- | --- |
| `banquito-account-core-service` | `account-core-service` | `account-core-service` | `account-core-service` | `banquito-core` |
| `banquito-accounting-service` | `accounting-service` | `accounting-service` | `accounting-service` | `banquito-core` |
| `banquito-party-service` | `party-service` | `party-service` | `party-service` | `banquito-core` |
| `banquito-file-reception-service` | `file-reception-service` | `file-reception-service` | `file-reception-service` | `banquito-switch` |
| `banquito-tariff-service` | `tariff-service` | `tariff-service` | `tariff-service` | `banquito-switch` |
| `banquito-clearinghouse-service` | `clearinghouse-service` | `clearinghouse-service` | `clearinghouse-service` | `banquito-switch` |
| `banquito-report-service` | `report-service` | `report-service` | `report-service` | `banquito-switch` |
| `banquito-notification-service` | `notification-service` | `notification-service` | `notification-service` | `banquito-switch` |

## Plantilla de pipeline para frontend

Los frontends ya no construyen imagen Docker ni ejecutan `kubectl`. El pipeline genera el build estatico y lo publica en la VM.

Ejemplo logico:

```text
Checkout
  -> Authenticate to Google Cloud
  -> Leer identity-platform-api-key desde Secret Manager
  -> Leer API Key Apigee del frontend desde Secret Manager
  -> npm ci
  -> npm run build
  -> tar dist
  -> scp dist.tar.gz a la VM
  -> descomprimir en /var/www/banquito/<frontend>
```

## Variables por frontend

| Repositorio | Workflow | Ruta VM | Secret Apigee |
| --- | --- | --- | --- |
| `banquito-teller-frontend` | `deploy-vm.yml` | `/var/www/banquito/teller` | `app-teller` |
| `banquito-web-personas-frontend` | `deploy-vm.yml` | `/var/www/banquito/personas` | `app-web-personas` |
| `banquito-web-empresas-frontend` | `deploy-vm.yml` | `/var/www/banquito/empresas` | `app-web-empresas` |
| `banquito-frontend-web-operador` | `deploy-vm.yml` | `/var/www/banquito/operador` | `app-operador` |

## Pipeline de infraestructura

El repositorio `banquito-infra` no construye imagenes. Su pipeline aplica manifiestos:

```text
namespace.yaml
configmap.yaml
gateway/
deployments
services
```

Debe evitar sobrescribir Secrets reales con placeholders.

Flujo recomendado:

```text
git push en banquito-infra
  -> validar YAML
  -> autenticar GCP
  -> obtener credenciales GKE
  -> kubectl apply de manifiestos no sensibles
```

## Requisito de API Key por aplicacion

Cada aplicacion frontend que consuma APIs por Apigee debe tener su propia API Key:

| Aplicacion | API Key Apigee |
| --- | --- |
| Teller Frontend | API Key propia |
| Web Personas Frontend | API Key propia |
| Web Empresas Frontend | API Key propia |
| Operador Frontend | API Key propia |

La API Key no reemplaza OAuth/JWT. Se usa para identificar la aplicacion cliente ante Apigee.

El flujo de seguridad queda:

```text
Frontend
  -> API Key de aplicacion
  -> Token OAuth/JWT del usuario
  -> Apigee valida API Key y JWT
  -> GKE Gateway
  -> Microservicio
```

## Entregable

El requisito queda cumplido cuando:

```text
1. Las aplicaciones estan desplegadas en GKE.
2. Las imagenes se publican en Artifact Registry.
3. Cada repo tiene GitHub Actions.
4. El workflow ejecuta kubectl set image o kubectl apply.
5. Un git push actualiza automaticamente el Deployment en GKE.
6. Cada frontend tiene su propia API Key configurada en Apigee.
```
