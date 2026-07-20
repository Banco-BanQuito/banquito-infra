# Frontends apuntando a API Manager Apigee

## Objetivo

Configurar los frontends para que no llamen directamente a microservicios internos ni a IPs antiguas.

El flujo objetivo es:

```text
Frontend
  -> Apigee
  -> Ingress/Gateway/LoadBalancer GKE
  -> Service Kubernetes
  -> Pod backend
```

Endpoint publico de Apigee:

```text
https://136.68.89.25.nip.io
```

## Cambios aplicados

Se actualizaron variables de produccion y defaults de Docker en:

```text
banquito-teller-frontend/.env.production
banquito-web-personas-frontend/.env.production
banquito-web-empresas-frontend/.env.production
banquito-frontend-web-operador/.env.example

banquito-teller-frontend/Dockerfile
banquito-web-personas-frontend/Dockerfile
banquito-web-empresas-frontend/Dockerfile
banquito-frontend-web-operador/Dockerfile

banquito-infra/k8s/configmap.yaml
```

## Variables objetivo

Core y Switch pasan por Apigee:

```text
VITE_ACCOUNT_API_BASE_URL=https://136.68.89.25.nip.io/api/v2
VITE_PARTY_API_BASE_URL=https://136.68.89.25.nip.io
VITE_ACCOUNTING_API_BASE_URL=https://136.68.89.25.nip.io/api/v2
VITE_SWITCH_API_BASE_URL=https://136.68.89.25.nip.io/api/v2
VITE_CLEARING_API_BASE_URL=https://136.68.89.25.nip.io/api/v2
```

Nota:

```text
Algunos frontends agregan /api/v2 desde el codigo.
Por eso VITE_PARTY_API_BASE_URL queda como https://136.68.89.25.nip.io en teller/personas/empresas.
```

## ConfigMap Kubernetes

Se actualizo:

```yaml
API_MANAGER_URL: https://136.68.89.25.nip.io
CORE_GATEWAY_URL: https://136.68.89.25.nip.io/api/v2
SWITCH_GATEWAY_URL: https://136.68.89.25.nip.io/api/v2
OAUTH_URL: https://securetoken.google.com/project-47695a8e-7cb2-4352-af2
OAUTH_ISSUER_URI: https://securetoken.google.com/project-47695a8e-7cb2-4352-af2
OAUTH_JWKS_URI: https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
```

Aplicar ConfigMap:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply -f configmap.yaml
```

## Importante sobre Vite

Los frontends usan variables `VITE_*`.

En Vite, estas variables se resuelven durante:

```text
npm run build
docker build
```

Por eso no basta con cambiar el ConfigMap si la imagen ya estaba construida.

Para que el navegador use Apigee, hay que reconstruir y subir las imagenes frontend.

## Reconstruir y subir teller-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-teller-frontend

docker build `
  --build-arg VITE_ACCOUNT_API_BASE_URL=https://136.68.89.25.nip.io/api/v2 `
  --build-arg VITE_PARTY_API_BASE_URL=https://136.68.89.25.nip.io `
  --build-arg VITE_ACCOUNTING_API_BASE_URL=https://136.68.89.25.nip.io/api/v2 `
  --build-arg VITE_SWITCH_API_BASE_URL=https://136.68.89.25.nip.io/api/v2 `
  -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/teller-frontend:latest .

docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/teller-frontend:latest
kubectl rollout restart deployment/teller-frontend -n banquito-frontend
kubectl rollout status deployment/teller-frontend -n banquito-frontend
```

## Reconstruir y subir web-personas-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-web-personas-frontend

docker build `
  --build-arg VITE_PARTY_API_BASE_URL=https://136.68.89.25.nip.io `
  --build-arg VITE_ACCOUNT_API_BASE_URL=https://136.68.89.25.nip.io/api/v2 `
  --build-arg VITE_SWITCH_API_BASE_URL=https://136.68.89.25.nip.io/api/v2 `
  -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest .

docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest
kubectl rollout restart deployment/web-personas-frontend -n banquito-frontend
kubectl rollout status deployment/web-personas-frontend -n banquito-frontend
```

## Reconstruir y subir web-empresas-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-web-empresas-frontend

docker build `
  --build-arg VITE_PARTY_API_BASE_URL=https://136.68.89.25.nip.io `
  --build-arg VITE_API_BASE_URL=https://136.68.89.25.nip.io `
  -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-empresas-frontend:latest .

docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-empresas-frontend:latest
kubectl rollout restart deployment/web-empresas-frontend -n banquito-frontend
kubectl rollout status deployment/web-empresas-frontend -n banquito-frontend
```

## Reconstruir y subir operador-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-frontend-web-operador

docker build `
  --build-arg VITE_ACCOUNT_API_BASE_URL=https://136.68.89.25.nip.io/api/v2 `
  --build-arg VITE_PARTY_API_BASE_URL=https://136.68.89.25.nip.io/api/v2 `
  --build-arg VITE_ACCOUNTING_API_BASE_URL=https://136.68.89.25.nip.io/api/v2 `
  --build-arg VITE_CLEARING_API_BASE_URL=https://136.68.89.25.nip.io/api/v2 `
  -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/operador-frontend:latest .

docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/operador-frontend:latest
kubectl rollout restart deployment/operador-frontend -n banquito-frontend
kubectl rollout status deployment/operador-frontend -n banquito-frontend
```

## Verificacion

Ver Pods frontend:

```powershell
kubectl get pods -n banquito-frontend
```

Ver Services frontend:

```powershell
kubectl get svc -n banquito-frontend
```

Ver rollout:

```powershell
kubectl get deployments -n banquito-frontend
```

## Pendiente de API Manager

Para que esto funcione completamente, Apigee debe tener proxies para las rutas consumidas por los frontends.

Actualmente se informo:

```text
Proxy: account-core-api
Base Path: /api/v2/accounts
Dominio: https://136.68.89.25.nip.io
```

Faltan confirmar o crear proxies/rutas para:

```text
/api/v2/auth/**
/api/v2/customers/**
/api/v2/customer-subtypes/**
/api/v2/branches/**
/api/v2/holidays/**
/api/v2/accounting/**
/api/v2/payments/**
/api/v2/reports/**
/api/v2/notifications/**
```

Sin esas rutas en Apigee, el frontend ya apuntara al API Manager, pero algunas llamadas devolveran `404` o error de proxy.
