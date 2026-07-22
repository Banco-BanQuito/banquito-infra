# ANEXO M - Secrets pendientes para Identity Platform y Apigee

## Objetivo

Definir los secretos que faltan para completar la integracion de los frontends con:

- Google Identity Platform.
- Google Apigee/API Manager.
- GitHub Actions para build y despliegue en GKE.

## Secrets que debe crear el equipo en Google Secret Manager

### Identity Platform

| Secret | Valor | Uso |
| --- | --- | --- |
| `identity-platform-api-key` | Guardado en Secret Manager | Web API Key de Identity Platform. La usan los 4 frontends para login. |
| `identity-platform-switch-service-password` | Guardado en Secret Manager | Password del usuario tecnico `switch-service@banquito.internal` para integraciones Switch -> Core. |
| `identity-platform-clients-temp-password` | Guardado en Secret Manager | Password temporal para pruebas con clientes migrados a Identity Platform. |

## API Keys que debe generar Apigee

Cada frontend que llama APIs expuestas en Apigee debe tener su propia API Key.

No se debe reutilizar una sola API Key para todos los frontends.

| Secret en Secret Manager | Valor | Aplicacion |
| --- | --- | --- |
| `app-teller` | API Key generada en Apigee para Teller | `banquito-teller-frontend` |
| `app-operador` | API Key generada en Apigee para Operador | `banquito-frontend-web-operador` |
| `app-web-personas` | API Key generada en Apigee para Web Personas | `banquito-web-personas-frontend` |
| `app-web-empresas` | API Key generada en Apigee para Web Empresas | `banquito-web-empresas-frontend` |

Estas claves deben ser entregadas por el responsable de Apigee/API Manager.

## Mapping hacia GitHub Actions

Los frontends reciben estos valores en tiempo de build mediante `docker build --build-arg`.

La fuente oficial NO es GitHub Secrets. La fuente oficial es Google Secret Manager.

GitHub Actions lee los secretos desde Secret Manager usando Workload Identity y los pasa como `build-arg`.

| Repositorio | Variable temporal en GitHub Actions | Valor fuente |
| --- | --- | --- |
| `banquito-teller-frontend` | `IDENTITY_PLATFORM_API_KEY` | Secret Manager: `identity-platform-api-key` |
| `banquito-teller-frontend` | `APIGEE_API_KEY` | Secret Manager: `app-teller` |
| `banquito-frontend-web-operador` | `IDENTITY_PLATFORM_API_KEY` | Secret Manager: `identity-platform-api-key` |
| `banquito-frontend-web-operador` | `APIGEE_API_KEY` | Secret Manager: `app-operador` |
| `banquito-web-personas-frontend` | `IDENTITY_PLATFORM_API_KEY` | Secret Manager: `identity-platform-api-key` |
| `banquito-web-personas-frontend` | `APIGEE_API_KEY` | Secret Manager: `app-web-personas` |
| `banquito-web-empresas-frontend` | `IDENTITY_PLATFORM_API_KEY` | Secret Manager: `identity-platform-api-key` |
| `banquito-web-empresas-frontend` | `APIGEE_API_KEY` | Secret Manager: `app-web-empresas` |

## Permiso necesario para GitHub Actions

La Service Account usada por GitHub Actions debe poder leer los secretos:

```text
github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com
```

Rol requerido:

```text
roles/secretmanager.secretAccessor
```

Comando:

```bash
gcloud projects add-iam-policy-binding project-47695a8e-7cb2-4352-af2 \
  --member="serviceAccount:github-actions-gke@project-47695a8e-7cb2-4352-af2.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

## Lectura desde GitHub Actions

Cada workflow frontend usa este patron:

```yaml
- name: Read frontend secrets from Secret Manager
  run: |
    echo "::add-mask::$(gcloud secrets versions access latest --secret=identity-platform-api-key --project "$PROJECT_ID")"
    echo "::add-mask::$(gcloud secrets versions access latest --secret=app-teller --project "$PROJECT_ID")"
    echo "IDENTITY_PLATFORM_API_KEY=$(gcloud secrets versions access latest --secret=identity-platform-api-key --project "$PROJECT_ID")" >> "$GITHUB_ENV"
    echo "APIGEE_API_KEY=$(gcloud secrets versions access latest --secret=app-teller --project "$PROJECT_ID")" >> "$GITHUB_ENV"
```

Luego el build recibe:

```yaml
--build-arg VITE_IDENTITY_PLATFORM_API_KEY="$IDENTITY_PLATFORM_API_KEY"
--build-arg VITE_APIGEE_API_KEY="$APIGEE_API_KEY"
```

## Comandos para crear los secrets en Secret Manager

Ejecutar en Cloud Shell o en una terminal con `gcloud` autenticado:

```bash
PROJECT_ID="project-47695a8e-7cb2-4352-af2"
```

### Identity Platform

```bash
printf '<IDENTITY_PLATFORM_API_KEY>' | gcloud secrets create identity-platform-api-key \
  --project "$PROJECT_ID" \
  --replication-policy automatic \
  --data-file=-
```

```bash
printf '<SWITCH_SERVICE_PASSWORD>' | gcloud secrets create identity-platform-switch-service-password \
  --project "$PROJECT_ID" \
  --replication-policy automatic \
  --data-file=-
```

```bash
printf '<CLIENTS_TEMP_PASSWORD>' | gcloud secrets create identity-platform-clients-temp-password \
  --project "$PROJECT_ID" \
  --replication-policy automatic \
  --data-file=-
```

### Apigee API Keys

Reemplazar cada placeholder por la API Key real generada en Apigee:

```bash
printf '<API_KEY_GENERADA_EN_APIGEE_PARA_TELLER>' | gcloud secrets create apigee-api-key-teller \
  --project "$PROJECT_ID" \
  --replication-policy automatic \
  --data-file=-
```

```bash
printf '<API_KEY_GENERADA_EN_APIGEE_PARA_OPERADOR>' | gcloud secrets create apigee-api-key-operador \
  --project "$PROJECT_ID" \
  --replication-policy automatic \
  --data-file=-
```

```bash
printf '<API_KEY_GENERADA_EN_APIGEE_PARA_WEB_PERSONAS>' | gcloud secrets create apigee-api-key-web-personas \
  --project "$PROJECT_ID" \
  --replication-policy automatic \
  --data-file=-
```

```bash
printf '<API_KEY_GENERADA_EN_APIGEE_PARA_WEB_EMPRESAS>' | gcloud secrets create apigee-api-key-web-empresas \
  --project "$PROJECT_ID" \
  --replication-policy automatic \
  --data-file=-
```

## Nota importante

Los valores `VITE_*` de los frontends se compilan dentro del build de Vite.

Por eso no basta con tener los secretos en Kubernetes. GitHub Actions debe leerlos desde Secret Manager para construir la imagen Docker final.

Flujo esperado:

```text
Google Secret Manager
  -> GitHub Actions con Workload Identity
  -> docker build --build-arg
  -> Artifact Registry
  -> GKE
  -> Frontend llama Apigee con x-api-key/apikey
```

## Validacion esperada

Cuando las API Keys correctas esten configuradas, Apigee ya no debe responder:

```text
Method doesn't allow unregistered callers
```

Si aparece ese error, significa que el frontend no esta enviando API Key o esta enviando una API Key no registrada en Apigee.
