# FASE 7 - Despliegue de frontends

## Objetivo

Desplegar las cuatro aplicaciones web en GKE y configurarlas para consumir Apigee.

## Frontends desplegados

| Frontend | Namespace | Deployment | Service | Puerto |
| --- | --- | --- | --- | ---: |
| Teller | `banquito-frontend` | `teller-frontend` | `teller-frontend` | 8080 |
| Web Personas | `banquito-frontend` | `web-personas-frontend` | `web-personas-frontend` | 8080 |
| Web Empresas | `banquito-frontend` | `web-empresas-frontend` | `web-empresas-frontend` | 8080 |
| Operador | `banquito-frontend` | `operador-frontend` | `operador-frontend` | 8080 |

## API Manager

Dominio Apigee:

```text
https://136.68.89.25.nip.io
```

Variables Vite:

```text
VITE_ACCOUNT_API_BASE_URL=https://136.68.89.25.nip.io/api/v2
VITE_PARTY_API_BASE_URL=https://136.68.89.25.nip.io
VITE_ACCOUNTING_API_BASE_URL=https://136.68.89.25.nip.io/api/v2
VITE_SWITCH_API_BASE_URL=https://136.68.89.25.nip.io/api/v2
```

## Importante

Vite resuelve `VITE_*` durante `docker build`. Si cambia Apigee, hay que reconstruir la imagen del frontend.

## Aplicar frontends

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply -f teller
kubectl apply -f personas
kubectl apply -f empresas
kubectl apply -f operador
```

Levantar:

```powershell
kubectl scale deployment --all --replicas=1 -n banquito-frontend
kubectl get pods -n banquito-frontend
```

## Reconstruir despues de cambiar Apigee

Ejemplo:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-web-personas-frontend
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest
kubectl rollout restart deployment/web-personas-frontend -n banquito-frontend
```

## Validacion completa 2026-07-20

Se levantaron los cuatro frontends en `banquito-frontend` y se validaron por el Gateway publico unico.

Resultado:

```text
operador-frontend        1/1 Running
teller-frontend          1/1 Running
web-empresas-frontend    1/1 Running
web-personas-frontend    1/1 Running
```

URLs validadas:

```text
http://personas.8.233.141.65.nip.io
http://operador.8.233.141.65.nip.io
http://teller.8.233.141.65.nip.io
http://empresas.8.233.141.65.nip.io
```

Detalle completo:

```text
docs/kubernetes/anexo-n-validacion-completa-gke.md
```

## Entregable

Los cuatro frontends tienen Deployment y Service en `banquito-frontend`, y sus builds apuntan al dominio de Apigee.
