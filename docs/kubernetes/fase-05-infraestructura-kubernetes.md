# FASE 5 - Creacion de infraestructura Kubernetes

## Objetivo

Crear los recursos base del cluster para organizar las aplicaciones.

## Namespaces

Se usan cuatro namespaces:

| Namespace | Uso |
| --- | --- |
| `banquito-core` | Microservicios Core Bancario |
| `banquito-switch` | Microservicios Switch Pagos Masivos |
| `banquito-frontend` | Frontends |
| `banquito-gateway` | Gateway publico de GKE |

Archivo:

```text
banquito-infra/k8s/namespace.yaml
```

## ConfigMap

Archivo:

```text
banquito-infra/k8s/configmap.yaml
```

Contiene configuracion no sensible:

```text
API_MANAGER_URL
CORE_GATEWAY_URL
SWITCH_GATEWAY_URL
OAUTH_URL
DB_HOST
MYSQL_HOST
MONGODB_HOST
RABBITMQ_HOST
DNS internos Kubernetes
Puertos HTTP/gRPC
```

## Secret

Archivo:

```text
banquito-infra/k8s/secret.yaml
```

Contiene placeholders. No se guardan passwords reales en Git.

Los secretos reales se crean directamente en Kubernetes:

```powershell
kubectl create secret generic banquito-secrets `
  --namespace banquito-core `
  --from-literal=DB_USER="postgres" `
  --from-literal=DB_PASS="<password-real>" `
  --dry-run=client -o yaml | kubectl apply -f -
```

Repetir para:

```text
banquito-core
banquito-switch
banquito-frontend
```

## Estructura actual

```text
k8s/
  namespace.yaml
  configmap.yaml
  secret.yaml
  gateway/
  account-core/
  accounting/
  party/
  file-reception/
  tariff/
  clearinghouse/
  report/
  notification/
  teller/
  personas/
  empresas/
  operador/
```

## Aplicar manifiestos

Aplicar desde la carpeta correcta:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f gateway
```

Advertencia:

```text
Aplicar secret.yaml sobrescribe Secrets reales con placeholders.
```

## Entregable

Namespaces, ConfigMaps, Secrets y carpetas Kubernetes organizadas.
