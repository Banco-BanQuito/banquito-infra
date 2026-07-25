# FASE 7 - Despliegue de frontends

## Objetivo

Publicar las cuatro aplicaciones web fuera del cluster Kubernetes, usando una VM con Nginx como servidor de archivos estaticos.

Esta fase se ajusto porque los frontends no necesitan ejecutarse como Pods. El requisito de orquestador de contenedores se cumple con las dos aplicaciones backend principales: Core Bancario y Switch de Pagos Masivos, que si se ejecutan en GKE.

## Decision arquitectonica

| Componente | Ubicacion final | Motivo |
| --- | --- | --- |
| Core Bancario | GKE Autopilot | Microservicios backend, comunicacion interna y escalamiento. |
| Switch de Pagos Masivos | GKE Autopilot | Microservicios backend, Pub/Sub, procesamiento asincrono. |
| Frontends | VM + Nginx | Son archivos estaticos generados por Vite; no requieren orquestacion. |
| Apigee | Servicio cloud externo | API Manager, OAuth 2, API Keys, CORS y enrutamiento. |

## Flujo de comunicacion

```text
Usuario
  -> Frontend en VM/Nginx
  -> Apigee API Manager
  -> GKE Gateway
  -> Service ClusterIP
  -> Pod backend
```

Los frontends no llaman directamente a los Services internos de Kubernetes. Toda llamada a APIs protegidas debe pasar por Apigee.

## Aplicaciones web

| Frontend | Ruta recomendada en VM | API Key en Secret Manager |
| --- | --- | --- |
| Web Personas | `/var/www/banquito/personas` | `app-web-personas` |
| Web Empresas | `/var/www/banquito/empresas` | `app-web-empresas` |
| Teller | `/var/www/banquito/teller` | `app-teller` |
| Operador | `/var/www/banquito/operador` | `app-operador` |

## Variables usadas en build

Los frontends son Vite, por lo que las variables `VITE_*` se resuelven durante el build.

```text
VITE_API_BASE_URL=https://136.68.89.25.nip.io
VITE_ACCOUNT_API_BASE_URL=https://136.68.89.25.nip.io/api/v2
VITE_PARTY_API_BASE_URL=https://136.68.89.25.nip.io
VITE_ACCOUNTING_API_BASE_URL=https://136.68.89.25.nip.io/api/v2
VITE_SWITCH_API_BASE_URL=https://136.68.89.25.nip.io/api/v2
VITE_IDENTITY_PLATFORM_API_KEY=<Secret Manager: identity-platform-api-key>
VITE_APIGEE_API_KEY=<Secret Manager segun frontend>
```

## CI/CD aplicado

Cada frontend tiene un workflow `deploy-vm.yml` que ejecuta:

```text
git push main
  -> GitHub Actions
  -> leer secretos desde Google Secret Manager
  -> npm ci
  -> npm run build
  -> empaquetar dist
  -> copiar dist a la VM por SSH/SCP
  -> publicar con Nginx
```

Secretos requeridos en GitHub:

```text
VM_HOST
VM_USER
VM_SSH_KEY
VM_PORT opcional
```

La cuenta `github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com` debe tener permiso `roles/secretmanager.secretAccessor` sobre los secretos de frontend.

## Estado en Kubernetes

Los manifiestos de frontend fueron retirados de la carpeta activa:

```text
banquito-infra/k8s
```

Quedaron archivados solo como evidencia historica:

```text
banquito-infra/k8s-archive/frontends-gke
```

Por tanto, al ejecutar:

```powershell
kubectl apply --recursive -f .\banquito-infra\k8s
```

Kubernetes ya no recrea Deployments, Services, HPA ni rutas de frontends.

## Comandos de verificacion

```powershell
kubectl get deploy -A
kubectl get svc -A
kubectl get httproute -A
kubectl get namespace banquito-frontend
```

Si `banquito-frontend` ya no existe, el frontend quedo fuera de GKE.

## Entregable

Los cuatro frontends se publican desde VM/Nginx y consumen APIs mediante Apigee. El cluster GKE queda reservado para Core Bancario, Switch de Pagos Masivos y el Gateway backend hacia Apigee.
