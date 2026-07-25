# Anexo S - Frontends en VM con CI/CD

## Objetivo

Documentar el cambio de despliegue de frontends: las aplicaciones web ya no se ejecutan como Pods en Kubernetes, sino como archivos estaticos servidos desde una VM con Nginx.

## Arquitectura final

```text
Usuario
  -> VM/Nginx
  -> Frontend BanQuito
  -> Apigee
  -> GKE Gateway
  -> Microservicios backend en GKE
  -> Servicios administrados de nube
```

## Por que no van en Kubernetes

Los frontends Vite generan contenido estatico (`dist`). Ese contenido no necesita service discovery, gRPC, HPA ni comunicacion interna entre Pods. Servirlo desde Nginx en una VM es suficiente para la demo y reduce consumo dentro del cluster.

El requisito de orquestador sigue cubierto porque las dos aplicaciones principales del backend, Core Bancario y Switch de Pagos Masivos, se ejecutan en Google Kubernetes Engine.

## CI/CD de frontends

Los cuatro repositorios usan el workflow:

```text
.github/workflows/deploy-vm.yml
```

Flujo:

```text
push a main
  -> GitHub Actions
  -> autenticacion con Google Cloud por Workload Identity
  -> lectura de Secret Manager
  -> npm ci
  -> npm run build
  -> empaquetado de dist
  -> despliegue por SSH/SCP a la VM
```

## Secretos usados

| Secreto | Ubicacion | Uso |
| --- | --- | --- |
| `identity-platform-api-key` | Google Secret Manager | Login contra Google Identity Platform. |
| `app-web-personas` | Google Secret Manager | API Key Apigee para Web Personas. |
| `app-web-empresas` | Google Secret Manager | API Key Apigee para Web Empresas. |
| `app-teller` | Google Secret Manager | API Key Apigee para Teller. |
| `app-operador` | Google Secret Manager | API Key Apigee para Operador. |
| `VM_HOST` | GitHub Secrets | Host/IP de la VM frontend. |
| `VM_USER` | GitHub Secrets | Usuario SSH para desplegar. |
| `VM_SSH_KEY` | GitHub Secrets | Llave privada SSH. |
| `VM_PORT` | GitHub Secrets opcional | Puerto SSH, por defecto `22`. |

## Rutas de despliegue en VM

| Frontend | Ruta en VM |
| --- | --- |
| Web Personas | `/var/www/banquito/personas` |
| Web Empresas | `/var/www/banquito/empresas` |
| Teller | `/var/www/banquito/teller` |
| Operador | `/var/www/banquito/operador` |

## URLs de APIs

Los frontends deben apuntar a Apigee:

```text
https://136.68.89.25.nip.io
```

No deben apuntar a:

```text
*.svc.cluster.local
ClusterIP
Pods
Servicios internos de Kubernetes
```

## Comandos para verificar que no hay frontends en GKE

```powershell
kubectl get deploy -A
kubectl get svc -A
kubectl get hpa -A
kubectl get namespace banquito-frontend
```

Si aparece el namespace `banquito-frontend`, se puede apagar o eliminar para evitar consumo:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-frontend
kubectl delete namespace banquito-frontend
```

## Comando para aplicar solo backends en GKE

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO
kubectl apply --recursive -f .\banquito-infra\k8s
```

## Sustentacion

La separacion queda asi:

| Capa | Servicio |
| --- | --- |
| Presentacion | VM + Nginx |
| API Management | Apigee |
| Orquestacion backend | GKE Autopilot |
| Mensajeria | Google Cloud Pub/Sub |
| Secretos | Google Secret Manager |
| Bases SQL | Cloud SQL |
| Base NoSQL | MongoDB Atlas |

Esto reduce recursos en GKE, mantiene el cumplimiento del orquestador para las aplicaciones backend y conserva el control de seguridad mediante Apigee, OAuth 2 y API Key por aplicacion.
