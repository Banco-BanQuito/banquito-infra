# FASE 4 - Construccion y publicacion de imagenes

## Objetivo

Publicar todas las imagenes de backend y frontend en Artifact Registry.

## Registry

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito
```

## Preparar Docker

```powershell
gcloud auth configure-docker us-central1-docker.pkg.dev
```

## Imagenes publicadas

| Servicio | Imagen |
| --- | --- |
| Account Core | `account-core-service:latest` |
| Accounting | `accounting-service:latest` |
| Party | `party-service:latest` |
| File Reception | `file-reception-service:latest` |
| Tariff | `tariff-service:latest` |
| Clearinghouse | `clearinghouse-service:latest` |
| Report | `report-service:latest` |
| Notification | `notification-service:latest` |
| Teller | `teller-frontend:latest` |
| Web Personas | `web-personas-frontend:latest` |
| Web Empresas | `web-empresas-frontend:latest` |
| Operador | `operador-frontend:latest` |

## Patron backend Java

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\<repo-backend>
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
```

## Patron frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\<repo-frontend>
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
```

## Validar imagenes

```powershell
gcloud artifacts docker images list `
  us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito
```

## Entregable

Las 12 imagenes estan disponibles en Artifact Registry.
