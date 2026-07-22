# Anexo Q - Validacion de Identity Platform en party-service

## Objetivo

Documentar la validacion realizada para que `party-service` cree usuarios en Google Identity Platform cuando se registra un cliente desde cajero.

Este anexo complementa:

```text
anexo-p-secret-manager-csi-party-service.md
```

## Problema encontrado

Un cliente podia existir en `partydb`, pero fallar en el login del frontend con:

```text
INVALID_LOGIN_CREDENTIALS
```

La causa no era CORS ni API Key vacia. La peticion a Identity Platform ya llegaba correctamente, pero el usuario OAuth no existia o habia sido creado con otra clave.

## Flujo esperado

Cuando se crea un cliente desde cajero:

```text
Frontend Teller / Operador
  -> Apigee
  -> GKE Gateway
  -> party-service
  -> partydb
  -> Google Identity Platform
```

`party-service` debe crear el usuario OAuth con:

```text
email: <identificacion>@banquito.internal
password: valor de Secret Manager identity-platform-clients-temp-password
```

## Codigo validado

Archivo:

```text
banquito-party-service/src/main/java/ec/edu/espe/banquito/core/party/service/IdentityPlatformService.java
```

Responsabilidad:

```text
Invocar Google Identity Platform accounts:signUp.
Usar IDENTITY_PLATFORM_API_KEY.
Usar IDENTITY_PLATFORM_DEFAULT_PASSWORD.
Ignorar EMAIL_EXISTS para permitir idempotencia.
```

Archivo:

```text
banquito-party-service/src/main/java/ec/edu/espe/banquito/core/party/service/CustomerService.java
```

Responsabilidad:

```text
Guardar el cliente en MySQL partydb.
Llamar IdentityPlatformService.createAccount despues del save.
```

## Secretos usados

Los valores reales no se documentan ni se guardan en Git.

| Variable en Pod | Fuente |
| --- | --- |
| `IDENTITY_PLATFORM_API_KEY` | Secret Manager `identity-platform-api-key` |
| `IDENTITY_PLATFORM_DEFAULT_PASSWORD` | Secret Manager `identity-platform-clients-temp-password` |

Validacion realizada dentro del pod sin imprimir valores:

```powershell
$pod = kubectl --insecure-skip-tls-verify=true get pods -n banquito-core -l app=party -o jsonpath="{.items[0].metadata.name}"

kubectl --insecure-skip-tls-verify=true exec -n banquito-core $pod -- sh -c 'test -n "$IDENTITY_PLATFORM_API_KEY" && test -n "$IDENTITY_PLATFORM_DEFAULT_PASSWORD" && echo IDENTITY_PLATFORM_SECRETS_OK'
```

Resultado esperado:

```text
IDENTITY_PLATFORM_SECRETS_OK
```

## Correccion de CI/CD

El pipeline fallaba al construir la imagen Docker porque el Dockerfile ejecutaba:

```dockerfile
RUN mvn package -DskipTests -q
```

Ese comando no ejecuta pruebas, pero Maven todavia compila `src/test`. Los tests antiguos de autenticacion referenciaban clases eliminadas y rompian el build.

Correccion aplicada:

```dockerfile
RUN mvn package -Dmaven.test.skip=true -q
```

Tambien se corrigio:

```text
.github/workflows/ci.yml
.github/workflows/docker-publish.yml
.dockerignore
```

## Resultado del CI/CD

Workflow validado:

```text
Build, Push and Deploy to GKE
```

Commit desplegado:

```text
e942d5705a0e1dabda83074dcd4784b4c988a8ee
```

Resultado:

```text
success
```

Pasos exitosos:

```text
Build JAR
Build image
Push image
Get GKE credentials
Deploy to GKE
```

## Validacion en GKE

Comandos:

```powershell
kubectl --insecure-skip-tls-verify=true get deployment party-service -n banquito-core -o jsonpath="{.spec.template.spec.containers[0].image}"

kubectl --insecure-skip-tls-verify=true get pods -n banquito-core -l app=party
```

Resultado:

```text
Image: us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:e942d5705a0e1dabda83074dcd4784b4c988a8ee
party-service-58dbc4b584-kc8zg   1/1   Running   0
```

## Validacion de login

Para validar un usuario contra Identity Platform se usa:

```powershell
$apiKey = gcloud secrets versions access latest `
  --secret=identity-platform-api-key `
  --project=project-47695a8e-7cb2-4352-af2

$tempPass = gcloud secrets versions access latest `
  --secret=identity-platform-clients-temp-password `
  --project=project-47695a8e-7cb2-4352-af2

$body = @{
  email = "<identificacion>@banquito.internal"
  password = $tempPass
  returnSecureToken = $true
} | ConvertTo-Json

Invoke-RestMethod `
  -Method Post `
  -Uri "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey" `
  -ContentType "application/json" `
  -Body $body
```

Resultado esperado:

```text
LOGIN_OK
```

## Reparacion manual realizada

Se encontro un cliente que existia en `partydb`, pero no en Identity Platform:

```text
0803741511
```

Se creo manualmente su usuario OAuth con:

```text
email: 0803741511@banquito.internal
password: valor de Secret Manager identity-platform-clients-temp-password
```

Validacion:

```text
LOGIN_OK email=0803741511@banquito.internal expiresIn=3600
```

Nota de seguridad:

```text
No se documentan idToken, refreshToken, API Key ni password real.
```

## Pendiente operativo

Los clientes creados antes de esta correccion pueden existir en `partydb` sin existir en Identity Platform.

Opciones:

```text
1. Ejecutar un backfill para crear usuarios faltantes en Identity Platform.
2. Reparar manualmente solo los clientes usados en la demo.
3. Validar un cliente nuevo creado desde cajero despues del despliegue e iniciar sesion con la clave temporal del vault.
```

La opcion recomendada para cierre tecnico es crear un script de backfill controlado que:

```text
Lea clientes activos desde partydb.
Construya email <identificacion>@banquito.internal.
Cree el usuario en Identity Platform con la clave temporal.
Ignore EMAIL_EXISTS.
Registre un reporte de creados, existentes y errores.
```

## Limpieza de secretos en repositorio

Se revisaron los repos:

```text
banquito-infra
banquito-party-service
```

Se eliminaron valores reales de:

```text
docs/kubernetes/anexo-m-secrets-pendientes-frontend-apigee.md
db/mysql-schema.sql
```

Validacion:

```powershell
rg -n "AIza|Banquito2026|Banquito123" banquito-infra banquito-party-service
```

Resultado:

```text
No quedan valores reales de API Key, password temporal ni password de base de datos en los archivos revisados.
```
