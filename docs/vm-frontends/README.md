# Frontends en maquina virtual con CI/CD

## Objetivo

Los frontends de BanQuito no se ejecutan como Pods dentro de GKE. Se publican como archivos estaticos en una maquina virtual de Google Cloud usando Nginx.

El flujo final queda asi:

```text
Usuario
  -> Frontend en VM / Nginx
  -> Apigee API Manager
  -> GKE Gateway
  -> Microservicios backend en GKE
```

Los backends siguen desplegados en Kubernetes. Los frontends solo consumen las APIs expuestas por Apigee.

## VM utilizada

| Campo | Valor |
| --- | --- |
| Proyecto GCP | `project-47695a8e-7cb2-4352-af2` |
| VM | `banquito` |
| Zona | `us-central1-a` |
| IP publica | `34.63.127.239` |
| Usuario SSH | `User` |
| Servidor web | `Nginx` |
| Puerto HTTP | `80` |

## Rutas publicas

| Frontend | URL |
| --- | --- |
| Web Personas | `http://personas.34.63.127.239.nip.io` |
| Web Empresas | `http://empresas.34.63.127.239.nip.io` |
| Teller / Ventanilla | `http://teller.34.63.127.239.nip.io` |
| Operador | `http://operador.34.63.127.239.nip.io` |

Tambien se dejaron preparados los dominios DuckDNS en Nginx:

```text
banquito-personas.duckdns.org
banquito-empresas.duckdns.org
banquito-teller.duckdns.org
banquito-operador.duckdns.org
```

## Directorios de despliegue en la VM

```text
/var/www/banquito/personas
/var/www/banquito/empresas
/var/www/banquito/teller
/var/www/banquito/operador
```

## Archivo Nginx versionado

La configuracion de Nginx esta en:

```text
banquito-infra/vm/nginx-banquito-frontends.conf
```

En la VM se copia a:

```text
/etc/nginx/sites-available/nginx-banquito-frontends.conf
/etc/nginx/sites-enabled/nginx-banquito-frontends.conf
```

## Comandos ejecutados

### 1. Verificar VM existente

```powershell
gcloud compute instances list `
  --project project-47695a8e-7cb2-4352-af2 `
  --format="table(name,zone,machineType.basename(),status,networkInterfaces[0].accessConfigs[0].natIP)"
```

### 2. Verificar Nginx en la VM

```powershell
gcloud compute ssh banquito `
  --zone=us-central1-a `
  --project=project-47695a8e-7cb2-4352-af2 `
  --command="hostname; whoami; sudo ss -tulpn | grep ':80 ' || true; nginx -v || true"
```

### 3. Crear carpetas de despliegue

```powershell
gcloud compute ssh banquito `
  --zone=us-central1-a `
  --project=project-47695a8e-7cb2-4352-af2 `
  --command="sudo mkdir -p /var/www/banquito/personas /var/www/banquito/empresas /var/www/banquito/teller /var/www/banquito/operador && sudo chown -R User:www-data /var/www/banquito && sudo chmod -R 775 /var/www/banquito"
```

### 4. Copiar configuracion de Nginx

```powershell
gcloud compute scp banquito-infra\vm\nginx-banquito-frontends.conf `
  banquito:/tmp/nginx-banquito-frontends.conf `
  --zone=us-central1-a `
  --project=project-47695a8e-7cb2-4352-af2
```

### 5. Activar configuracion Nginx

```powershell
gcloud compute ssh banquito `
  --zone=us-central1-a `
  --project=project-47695a8e-7cb2-4352-af2 `
  --command="sudo mv /tmp/nginx-banquito-frontends.conf /etc/nginx/sites-available/nginx-banquito-frontends.conf && sudo ln -sf /etc/nginx/sites-available/nginx-banquito-frontends.conf /etc/nginx/sites-enabled/nginx-banquito-frontends.conf && sudo nginx -t && sudo systemctl reload nginx"
```

### 6. Habilitar arranque automatico de Nginx

```powershell
gcloud compute ssh banquito `
  --zone=us-central1-a `
  --project=project-47695a8e-7cb2-4352-af2 `
  --command="sudo systemctl enable nginx && sudo systemctl start nginx"
```

### 7. Verificar arranque automatico

```powershell
gcloud compute ssh banquito `
  --zone=us-central1-a `
  --project=project-47695a8e-7cb2-4352-af2 `
  --command="systemctl is-enabled nginx; systemctl is-active nginx; nginx -v"
```

Resultado esperado:

```text
enabled
active
nginx version: nginx/1.24.0 (Ubuntu)
```

### 8. Probar URLs publicas

```powershell
curl.exe -s http://personas.34.63.127.239.nip.io
curl.exe -s http://empresas.34.63.127.239.nip.io
curl.exe -s http://teller.34.63.127.239.nip.io
curl.exe -s http://operador.34.63.127.239.nip.io
```

## Conexion de frontends hacia Apigee

Los frontends no deben llamar directamente a los Services de Kubernetes ni al Gateway interno de GKE. Deben llamar a Apigee:

```text
https://136.68.89.25.nip.io
```

Las variables de build usadas en los workflows apuntan a Apigee:

| Variable | Valor por defecto |
| --- | --- |
| `VITE_ACCOUNT_API_BASE_URL` | `https://136.68.89.25.nip.io/api/v2` |
| `VITE_PARTY_API_BASE_URL` | `https://136.68.89.25.nip.io` o `https://136.68.89.25.nip.io/api/v2` segun frontend |
| `VITE_SWITCH_API_BASE_URL` | `https://136.68.89.25.nip.io/api/v2` |
| `VITE_ACCOUNTING_API_BASE_URL` | `https://136.68.89.25.nip.io/api/v2` |
| `VITE_CLEARING_API_BASE_URL` | `https://136.68.89.25.nip.io/api/v2` |

Cada frontend tambien inyecta:

```text
VITE_IDENTITY_PLATFORM_API_KEY
VITE_APIGEE_API_KEY
```

Estos valores no se escriben en el repositorio. El workflow los lee desde Google Secret Manager.

## Secretos de despliegue en Google Secret Manager

La informacion de despliegue hacia la VM tambien se guarda en Google Secret Manager, no en archivos del repositorio.

```text
frontend-vm-host
frontend-vm-user
frontend-vm-port
frontend-vm-ssh-private-key
```

Valores actuales:

```text
frontend-vm-host=34.63.127.239
frontend-vm-user=User
frontend-vm-port=22
frontend-vm-ssh-private-key=<llave privada autorizada en la VM>
```

Comandos utilizados para crear o actualizar estos secretos:

```powershell
$PROJECT_ID = "project-47695a8e-7cb2-4352-af2"
$KEY_FILE = "C:\Users\User\Desktop\KUBERNETS-PROYECTO\.deploy-secrets\banquito_frontend_vm_key_github_actions"

"34.63.127.239" | gcloud secrets create frontend-vm-host `
  --project $PROJECT_ID `
  --data-file=-

"User" | gcloud secrets create frontend-vm-user `
  --project $PROJECT_ID `
  --data-file=-

"22" | gcloud secrets create frontend-vm-port `
  --project $PROJECT_ID `
  --data-file=-

gcloud secrets create frontend-vm-ssh-private-key `
  --project $PROJECT_ID `
  --data-file=$KEY_FILE
```

Si el secreto ya existe, se agrega una nueva version:

```powershell
"34.63.127.239" | gcloud secrets versions add frontend-vm-host `
  --project $PROJECT_ID `
  --data-file=-

"User" | gcloud secrets versions add frontend-vm-user `
  --project $PROJECT_ID `
  --data-file=-

"22" | gcloud secrets versions add frontend-vm-port `
  --project $PROJECT_ID `
  --data-file=-

gcloud secrets versions add frontend-vm-ssh-private-key `
  --project $PROJECT_ID `
  --data-file=$KEY_FILE
```

Permisos otorgados a la cuenta de servicio usada por GitHub Actions:

```powershell
$PROJECT_ID = "project-47695a8e-7cb2-4352-af2"
$SA = "github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com"

gcloud secrets add-iam-policy-binding frontend-vm-host `
  --project $PROJECT_ID `
  --member="serviceAccount:$SA" `
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding frontend-vm-user `
  --project $PROJECT_ID `
  --member="serviceAccount:$SA" `
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding frontend-vm-port `
  --project $PROJECT_ID `
  --member="serviceAccount:$SA" `
  --role="roles/secretmanager.secretAccessor"

gcloud secrets add-iam-policy-binding frontend-vm-ssh-private-key `
  --project $PROJECT_ID `
  --member="serviceAccount:$SA" `
  --role="roles/secretmanager.secretAccessor"
```

## GitHub Actions

Los repositorios frontend ya no necesitan estos secrets:

```text
VM_HOST
VM_USER
VM_PORT
VM_SSH_KEY
```

El workflow se autentica en Google Cloud mediante Workload Identity y luego lee estos secretos desde Secret Manager:

```bash
gcloud secrets versions access latest --secret=frontend-vm-host
gcloud secrets versions access latest --secret=frontend-vm-user
gcloud secrets versions access latest --secret=frontend-vm-port
gcloud secrets versions access latest --secret=frontend-vm-ssh-private-key
```

Repositorios que usan este flujo:

```text
banquito-web-personas-frontend
banquito-web-empresas-frontend
banquito-teller-frontend
banquito-frontend-web-operador
```

## Llave privada local de respaldo

La llave privada se dejo localmente fuera de los repositorios:

```text
C:\Users\User\Desktop\KUBERNETS-PROYECTO\.deploy-secrets\banquito_frontend_vm_key_github_actions
```

Comando para copiar su contenido:

```powershell
Get-Content C:\Users\User\Desktop\KUBERNETS-PROYECTO\.deploy-secrets\banquito_frontend_vm_key_github_actions -Raw
```

No se debe subir esa llave al repositorio. La fuente usada por CI/CD es Google Secret Manager.

## CI/CD esperado

Cuando se hace `git push` a `main` en un repositorio frontend:

1. GitHub Actions obtiene permisos en Google Cloud mediante Workload Identity.
2. Lee secretos de Identity Platform, Apigee y VM desde Secret Manager.
3. Compila el frontend con Vite.
4. Genera el directorio `dist`.
5. Empaqueta `dist` como `frontend-dist.tgz`.
6. Copia el paquete a la VM por SSH/SCP.
7. Extrae los archivos en `/var/www/banquito/<frontend>`.
8. Nginx sirve la nueva version automaticamente.

No hace falta ejecutar `npm run dev` ni levantar procesos Node en la VM. Nginx sirve archivos estaticos.

## Validaciones importantes

### Comandos dentro de la VM por SSH

Cuando ya estes conectado a la VM por SSH, estos comandos permiten ubicar y revisar los frontends desplegados.

Entrar al directorio base:

```bash
cd /var/www/banquito
ls -la
```

Ver cada frontend:

```bash
ls -la /var/www/banquito/personas
ls -la /var/www/banquito/empresas
ls -la /var/www/banquito/teller
ls -la /var/www/banquito/operador
```

Entrar a un frontend especifico:

```bash
cd /var/www/banquito/personas
ls -la
```

Ver el `index.html` desplegado:

```bash
cat /var/www/banquito/personas/index.html
cat /var/www/banquito/empresas/index.html
cat /var/www/banquito/teller/index.html
cat /var/www/banquito/operador/index.html
```

Ver la configuracion Nginx activa:

```bash
ls -la /etc/nginx/sites-enabled
cat /etc/nginx/sites-enabled/nginx-banquito-frontends.conf
```

Ver si Nginx esta corriendo:

```bash
systemctl status nginx
```

Recargar Nginx si se cambia alguna configuracion:

```bash
sudo nginx -t
sudo systemctl reload nginx
```

Probar las URLs desde la misma VM:

```bash
curl http://personas.34.63.127.239.nip.io
curl http://empresas.34.63.127.239.nip.io
curl http://teller.34.63.127.239.nip.io
curl http://operador.34.63.127.239.nip.io
```

### Verificar que los frontends ya no estan en Kubernetes

```powershell
kubectl --insecure-skip-tls-verify=true get namespaces
kubectl --insecure-skip-tls-verify=true get pods -A
```

No debe existir:

```text
banquito-frontend
```

### Verificar backends en Kubernetes

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core
kubectl --insecure-skip-tls-verify=true get pods -n banquito-switch
```

### Verificar que Nginx arranca al reiniciar la VM

```powershell
gcloud compute ssh banquito `
  --zone=us-central1-a `
  --project=project-47695a8e-7cb2-4352-af2 `
  --command="systemctl is-enabled nginx; systemctl is-active nginx"
```

Resultado correcto:

```text
enabled
active
```

## Nota sobre HTTPS

Actualmente las URLs `nip.io` de la VM estan por HTTP.

Para HTTPS se necesita:

1. Dominio visible publicamente apuntando a `34.63.127.239`.
2. Certificado TLS.
3. Configuracion Nginx en puerto `443`.

Esto se puede hacer con DuckDNS + Certbot/Let's Encrypt si los dominios DuckDNS ya apuntan a la IP de la VM.
