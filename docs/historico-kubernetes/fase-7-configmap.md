# Fase 7 - ConfigMap Kubernetes

## Objetivo

Centralizar en Kubernetes la configuracion no sensible de todos los microservicios BanQuito.

La idea es que cuando cambien las URLs o hosts de servicios administrados, se actualice el ConfigMap y no el codigo fuente.

## Archivo principal

```text
k8s/configmap.yaml
```

Nombre del recurso:

```text
banquito-config
```

Namespace:

```text
banquito
```

## Que contiene

El ConfigMap contiene unicamente variables no sensibles:

- URLs de API Manager.
- URL de OAuth.
- Hosts y puertos de bases de datos administradas.
- Host y puerto de RabbitMQ administrado.
- Nombres DNS internos de servicios Kubernetes.
- Puertos HTTP y gRPC.
- CORS.
- Flags operativos no sensibles.

## Variables principales agregadas

### API Manager y OAuth

```text
API_MANAGER_URL
CORE_GATEWAY_URL
SWITCH_GATEWAY_URL
OAUTH_URL
OAUTH_ISSUER_URI
OAUTH_JWKS_URI
```

### Bases de datos

```text
DB_HOST
DB_PORT
DB_NAME
DB_SCHEMA
ACCOUNTING_DB_SCHEMA
MYSQL_HOST
MYSQL_PORT
PARTY_DB_NAME
FILE_DB_NAME
TARIFF_DB_NAME
MONGODB_HOST
MONGODB_PORT
MONGODB_DATABASE
```

### RabbitMQ

```text
RABBIT_HOST
RABBIT_PORT
RABBIT_VHOST
RABBITMQ_HOST
RABBITMQ_PORT
RABBITMQ_VHOST
SPRING_RABBITMQ_HOST
SPRING_RABBITMQ_PORT
SPRING_RABBITMQ_VIRTUAL_HOST
```

### Servicios internos

```text
ACCOUNT_HOST
ACCOUNT_CORE_HOST
ACCOUNT_CORE_GRPC_HOST
ACCOUNTING_HOST
ACCOUNTING_GRPC_HOST
PARTY_HOST
PARTY_GRPC_HOST
FILE_RECEPTION_HOST
TARIFF_HOST
TARIFF_SERVICE_GRPC_HOST
CLEARINGHOUSE_HOST
REPORT_HOST
NOTIFICATION_HOST
NOTIFICATION_GRPC_HOST
NOTIFICATION_SERVICE_GRPC_HOST
```

## Que NO contiene

El ConfigMap no debe contener:

- passwords;
- usuarios de base de datos;
- tokens;
- client secrets OAuth;
- URIs con credenciales;
- claves privadas.

Esos valores permanecen en:

```text
k8s/secret.yaml
```

## Ajuste adicional

`DB_SCHEMA` en el ConfigMap queda con valor `account_core`, porque es usado por `account-core-service`.

Para `accounting-service`, el Deployment define un override especifico:

```yaml
env:
  - name: DB_SCHEMA
    value: accounting
```

Asi ambos servicios pueden usar la misma variable esperada por Spring sin tocar codigo fuente.

## Comandos utilizados

### Revisar ConfigMap actual

```powershell
Get-Content banquito-infra\k8s\configmap.yaml
```

### Revisar Secret actual

```powershell
Get-Content banquito-infra\k8s\secret.yaml
```

### Buscar variables relacionadas en Kubernetes

```powershell
rg -n "DB_HOST|ACCOUNT_HOST|PARTY_HOST|RABBIT|API_MANAGER|OAUTH|CORE_GATEWAY|GRPC_HOST|MONGODB_HOST|SMTP_HOST" banquito-infra\k8s -S
```

### Validar manifiestos sin desplegar

```powershell
kubectl create --dry-run=client --validate=false --recursive -f banquito-infra\k8s
```

## Pendientes

1. Reemplazar placeholders como `api.example.com`, `rabbitmq-host.example.com` y `cloud-sql-*.example.com`.
2. Decidir si las URLs reales se manejaran por ambiente con overlays `dev`, `demo` y `prod`.
3. Integrar secretos reales con Google Secret Manager.
4. Revisar si se usara API Gateway o Apigee como API Manager final.
