# FASE 1 - Preparacion del entorno de desarrollo

## Objetivo

Dejar Windows 11 listo para construir imagenes, interactuar con Google Cloud y administrar Kubernetes.

## Herramientas requeridas

| Herramienta | Uso |
| --- | --- |
| Docker Desktop | Construccion y publicacion de imagenes |
| Google Cloud CLI | Autenticacion y administracion de GCP |
| kubectl | Administracion de Kubernetes |
| Java 21 | Build de microservicios Spring Boot |
| Maven / Maven Wrapper | Compilacion Java |
| Git | Control de versiones |
| Visual Studio Code | Edicion de repositorios |

## Comandos de validacion

```powershell
docker --version
gcloud --version
kubectl version --client
java -version
mvn -version
git --version
```

## Autenticacion en Google Cloud

```powershell
gcloud auth login
gcloud config set project project-47695a8e-7cb2-4352-af2
gcloud auth configure-docker us-central1-docker.pkg.dev
```

## Obtener credenciales del cluster

```powershell
gcloud container clusters get-credentials banquito-cluster-east `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2
```

Validar contexto:

```powershell
kubectl config current-context
```

Resultado esperado:

```text
gke_project-47695a8e-7cb2-4352-af2_us-east1_banquito-cluster-east
```

## Entregable

Todos los comandos anteriores responden correctamente desde PowerShell.
