# ANEXO F - Autenticacion CI/CD con Workload Identity Federation

## Objetivo

Permitir que GitHub Actions despliegue en Google Kubernetes Engine y publique imagenes en Artifact Registry sin usar archivos JSON de Service Account.

## Problema encontrado

Se intento crear una clave JSON para la Service Account:

```text
github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com
```

Google Cloud rechazo la operacion por una politica de seguridad del proyecto:

```text
constraints/iam.disableServiceAccountKeyCreation
```

Esto significa que el proyecto no permite crear claves descargables de Service Account.

## Decision tecnica

Usar Workload Identity Federation.

Con este modelo:

```text
GitHub Actions
  -> emite token OIDC
  -> Google Cloud valida el token
  -> GitHub impersona la Service Account
  -> el workflow publica imagenes y actualiza GKE
```

No se guarda ningun JSON en GitHub.

No se necesita el secret:

```text
GCP_SA_KEY
```

## Recursos creados en Google Cloud

| Recurso | Valor |
| --- | --- |
| Proyecto | `project-47695a8e-7cb2-4352-af2` |
| Project number | `69503932816` |
| Service Account | `github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com` |
| Workload Identity Pool | `github-actions-pool` |
| Workload Identity Provider | `github-actions-provider` |
| Organizacion GitHub autorizada | `Banco-BanQuito` |

## Roles asignados a la Service Account

```text
roles/artifactregistry.writer
roles/container.developer
roles/container.clusterViewer
```

Estos permisos permiten:

```text
Artifact Registry Writer:
  publicar imagenes Docker.

Kubernetes Engine Developer:
  actualizar Deployments, ejecutar kubectl set image y rollout status.

Kubernetes Engine Cluster Viewer:
  obtener credenciales y consultar el cluster.
```

## Comandos ejecutados

Crear Service Account:

```powershell
gcloud iam service-accounts create github-actions-gke `
  --project project-47695a8e-7cb2-4352-af2 `
  --display-name="GitHub Actions GKE"
```

Asignar permisos:

```powershell
gcloud projects add-iam-policy-binding project-47695a8e-7cb2-4352-af2 `
  --member="serviceAccount:github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com" `
  --role="roles/artifactregistry.writer" `
  --quiet
```

```powershell
gcloud projects add-iam-policy-binding project-47695a8e-7cb2-4352-af2 `
  --member="serviceAccount:github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com" `
  --role="roles/container.developer" `
  --quiet
```

```powershell
gcloud projects add-iam-policy-binding project-47695a8e-7cb2-4352-af2 `
  --member="serviceAccount:github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com" `
  --role="roles/container.clusterViewer" `
  --quiet
```

Crear Workload Identity Pool:

```powershell
gcloud iam workload-identity-pools create github-actions-pool `
  --project project-47695a8e-7cb2-4352-af2 `
  --location=global `
  --display-name="GitHub Actions Pool" `
  --description="OIDC federation for Banco-BanQuito GitHub Actions"
```

Crear Provider OIDC para GitHub Actions:

```powershell
gcloud iam workload-identity-pools providers create-oidc github-actions-provider `
  --project project-47695a8e-7cb2-4352-af2 `
  --location=global `
  --workload-identity-pool=github-actions-pool `
  --display-name="GitHub Actions Provider" `
  --issuer-uri="https://token.actions.githubusercontent.com" `
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" `
  --attribute-condition="assertion.repository_owner == 'Banco-BanQuito'"
```

Permitir que los repositorios de la organizacion impersonen la Service Account:

```powershell
gcloud iam service-accounts add-iam-policy-binding `
  github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com `
  --project project-47695a8e-7cb2-4352-af2 `
  --role="roles/iam.workloadIdentityUser" `
  --member="principalSet://iam.googleapis.com/projects/69503932816/locations/global/workloadIdentityPools/github-actions-pool/attribute.repository_owner/Banco-BanQuito"
```

## Bloque usado en GitHub Actions

Los workflows usan:

```yaml
- name: Authenticate to Google Cloud
  uses: google-github-actions/auth@v2
  with:
    workload_identity_provider: projects/69503932816/locations/global/workloadIdentityPools/github-actions-pool/providers/github-actions-provider
    service_account: github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com
```

El job debe tener permisos OIDC:

```yaml
permissions:
  contents: read
  id-token: write
```

## Repositorios actualizados

Se actualizaron los workflows `docker-publish.yml` de los 12 repositorios de aplicacion:

| Repositorio | Commit |
| --- | --- |
| `banquito-account-core-service` | `7c9ce3d` |
| `banquito-accounting-service` | `c9628a5` |
| `banquito-party-service` | `12d3c81` |
| `banquito-file-reception-service` | `aeff266` |
| `banquito-tariff-service` | `b4383ec` |
| `banquito-clearinghouse-service` | `932effc` |
| `banquito-report-service` | `1804037` |
| `banquito-notification-service` | `d81baf2` |
| `banquito-teller-frontend` | `8d1caed` |
| `banquito-web-personas-frontend` | `bfa8398` |
| `banquito-web-empresas-frontend` | `db2c380` |
| `banquito-frontend-web-operador` | `89945d9` |

## Prueba realizada

Se hizo una prueba real en:

```text
banquito-web-personas-frontend
```

Cambio aplicado:

```text
Ingreso de cliente
```

se cambio a:

```text
Ingreso de cliente - prueba CI/CD
```

Resultado del workflow:

```text
Build, Push and Deploy to GKE: success
```

Imagen publicada:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:bfa8398a323ebcca2a909513b724f9aa0355808c
```

Tambien quedo actualizada la etiqueta:

```text
latest
```

## Resultado

El CI/CD ya no depende de claves JSON ni del secret `GCP_SA_KEY`.

El despliegue automatizado queda alineado con una practica recomendada de Google Cloud:

```text
Autenticacion federada OIDC
  -> sin claves descargables
  -> menor riesgo de fuga de credenciales
  -> GitHub Actions puede publicar imagenes y actualizar GKE
```
