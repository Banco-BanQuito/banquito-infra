# Rutas backend para configurar en Apigee

## Objetivo

Este documento lista las rutas HTTP reales encontradas en los controladores Java de los microservicios BanQuito.

Uso esperado:

```text
Frontend
  -> Apigee
  -> Ingress/Gateway/LoadBalancer GKE
  -> Kubernetes Service
  -> Pod backend
```

Dominio publico actual de Apigee:

```text
https://136.68.89.25.nip.io
```

Importante:

```text
Los Services Kubernetes son ClusterIP.
Apigee no debe apuntar directamente a ClusterIP.
Apigee debe apuntar al endpoint publico del Ingress/Gateway/LoadBalancer de GKE.
```

## Backends Kubernetes

| Dominio | Microservicio | Namespace | Service | Puerto HTTP | DNS interno |
| --- | --- | --- | --- | ---: | --- |
| Core | Account Core | `banquito-core` | `account-core-service` | `8081` | `account-core-service.banquito-core.svc.cluster.local` |
| Core | Accounting | `banquito-core` | `accounting-service` | `8082` | `accounting-service.banquito-core.svc.cluster.local` |
| Core | Party | `banquito-core` | `party-service` | `8083` | `party-service.banquito-core.svc.cluster.local` |
| Switch | File Reception | `banquito-switch` | `file-reception-service` | `8084` | `file-reception-service.banquito-switch.svc.cluster.local` |
| Switch | Tariff | `banquito-switch` | `tariff-service` | `8086` | `tariff-service.banquito-switch.svc.cluster.local` |
| Switch | Clearinghouse | `banquito-switch` | `clearinghouse-service` | `8087` | `clearinghouse-service.banquito-switch.svc.cluster.local` |
| Switch | Report | `banquito-switch` | `report-service` | `8088` | `report-service.banquito-switch.svc.cluster.local` |
| Switch | Notification | `banquito-switch` | `notification-service` | `8089` | `notification-service.banquito-switch.svc.cluster.local` |

## Account Core Service

Backend:

```text
account-core-service.banquito-core.svc.cluster.local:8081
```

Rutas:

| Metodo | Ruta publica en Apigee | Backend |
| --- | --- | --- |
| `POST` | `/api/v2/auth/login/staff` | `account-core-service:8081` |
| `GET` | `/api/v2/accounts/{accountIdOrNumber}` | `account-core-service:8081` |
| `PATCH` | `/api/v2/accounts/{accountNumber}/activate` | `account-core-service:8081` |
| `PATCH` | `/api/v2/accounts/{accountNumber}/inactivate` | `account-core-service:8081` |
| `PATCH` | `/api/v2/accounts/{accountNumber}/block` | `account-core-service:8081` |
| `PATCH` | `/api/v2/accounts/{accountNumber}/suspend` | `account-core-service:8081` |
| `GET` | `/api/v2/accounts/subtypes` | `account-core-service:8081` |
| `GET` | `/api/v2/accounts/customer/{customerId}` | `account-core-service:8081` |
| `GET` | `/api/v2/accounts/customer/{customerId}/favorite` | `account-core-service:8081` |
| `GET` | `/api/v2/accounts/{accountIdOrNumber}/balance` | `account-core-service:8081` |
| `GET` | `/api/v2/accounts/{accountIdOrNumber}/transactions` | `account-core-service:8081` |
| `POST` | `/api/v2/accounts/open` | `account-core-service:8081` |
| `POST` | `/api/v2/accounts/teller/deposit` | `account-core-service:8081` |
| `POST` | `/api/v2/accounts/teller/withdrawal` | `account-core-service:8081` |
| `POST` | `/api/v2/accounts/transfer/p2p` | `account-core-service:8081` |
| `POST` | `/api/v2/accounts/transfer/external` | `account-core-service:8081` |
| `GET` | `/api/v2/accounts/health` | `account-core-service:8081` |
| `GET` | `/api/v2/calendar/accounting-date` | `account-core-service:8081` |
| `GET` | `/api/v2/calendar/holidays/check` | `account-core-service:8081` |
| `GET` | `/api/v2/eod/daily-transactions-file` | `account-core-service:8081` |
| `POST` | `/api/v2/payments/batch-credit` | `account-core-service:8081` |
| `POST` | `/api/v2/payments/corporate-debit` | `account-core-service:8081` |
| `POST` | `/api/v2/payments/corporate-refund` | `account-core-service:8081` |
| `POST` | `/api/v2/payments/offus-settlement` | `account-core-service:8081` |

## Accounting Service

Backend:

```text
accounting-service.banquito-core.svc.cluster.local:8082
```

Rutas:

| Metodo | Ruta publica en Apigee | Backend |
| --- | --- | --- |
| `GET` | `/api/v2/accounting/health` | `accounting-service:8082` |
| `POST` | `/api/v2/accounting/entries` | `accounting-service:8082` |
| `POST` | `/api/v2/accounting/eod` | `accounting-service:8082` |
| `GET` | `/api/v2/accounting/trial-balance` | `accounting-service:8082` |
| `POST` | `/api/v2/accounting/auto-balance` | `accounting-service:8082` |
| `GET` | `/api/v2/accounting/reports/csv` | `accounting-service:8082` |
| `GET` | `/api/v2/accounting/reports/pdf` | `accounting-service:8082` |

## Party Service

Backend:

```text
party-service.banquito-core.svc.cluster.local:8083
```

Rutas:

| Metodo | Ruta publica en Apigee | Backend |
| --- | --- | --- |
| `POST` | `/api/v2/auth/login` | `party-service:8083` |
| `PUT` | `/api/v2/auth/change-password` | `party-service:8083` |
| `GET` | `/api/v2/customers/by-account/{accountNumber}` | `party-service:8083` |
| `GET` | `/api/v2/customers/{id}` | `party-service:8083` |
| `POST` | `/api/v2/customers` | `party-service:8083` |
| `PATCH` | `/api/v2/customers/{id}/status/{status}` | `party-service:8083` |
| `GET` | `/api/v2/customer-subtypes` | `party-service:8083` |
| `GET` | `/api/v2/core-parameters` | `party-service:8083` |
| `GET` | `/api/v2/branches` | `party-service:8083` |
| `POST` | `/api/v2/branches` | `party-service:8083` |
| `GET` | `/api/v2/holidays` | `party-service:8083` |

## File Reception Service

Backend:

```text
file-reception-service.banquito-switch.svc.cluster.local:8084
```

Rutas:

| Metodo | Ruta publica en Apigee | Backend |
| --- | --- | --- |
| `POST` | `/api/v2/payments/batches` | `file-reception-service:8084` |
| `GET` | `/api/v2/payments/batches/{batchId}/status` | `file-reception-service:8084` |
| `GET` | `/api/v2/payments/routing-codes` | `file-reception-service:8084` |
| `GET` | `/api/v2/payments/routing-codes/{code}/classify` | `file-reception-service:8084` |
| `POST` | `/api/v2/payments/routing-codes` | `file-reception-service:8084` |
| `DELETE` | `/api/v2/payments/routing-codes/{code}` | `file-reception-service:8084` |

Rutas legacy tambien existentes:

| Metodo | Ruta legacy | Backend |
| --- | --- | --- |
| `POST` | `/api/v1/payments/batches` | `file-reception-service:8084` |
| `GET` | `/api/v1/routing-codes` | `file-reception-service:8084` |
| `GET` | `/api/v1/routing-codes/{code}/classify` | `file-reception-service:8084` |
| `POST` | `/api/v1/routing-codes` | `file-reception-service:8084` |
| `DELETE` | `/api/v1/routing-codes/{code}` | `file-reception-service:8084` |

Recomendacion:

```text
En Apigee publicar solo /api/v2 salvo que se necesite compatibilidad con clientes antiguos.
```

## Tariff Service

Backend:

```text
tariff-service.banquito-switch.svc.cluster.local:8086
```

Rutas:

| Metodo | Ruta publica en Apigee | Backend |
| --- | --- | --- |
| `GET` | `/api/v2/tariff/calculate` | `tariff-service:8086` |
| `GET` | `/api/v2/tariff/ranges` | `tariff-service:8086` |
| `GET` | `/api/v2/tariff/health` | `tariff-service:8086` |

## Clearinghouse Service

Backend:

```text
clearinghouse-service.banquito-switch.svc.cluster.local:8087
```

Rutas:

| Metodo | Ruta publica en Apigee | Backend |
| --- | --- | --- |
| `POST` | `/api/v2/clearing/files/consolidate` | `clearinghouse-service:8087` |
| `GET` | `/api/v2/clearing/batches/{batchId}/file` | `clearinghouse-service:8087` |
| `GET` | `/api/v2/clearing/files` | `clearinghouse-service:8087` |
| `GET` | `/api/v2/clearing/files/{id}/csv` | `clearinghouse-service:8087` |
| `GET` | `/api/v2/clearing/files/{id}/txt` | `clearinghouse-service:8087` |
| `GET` | `/api/v2/clearing/files/{id}/pdf` | `clearinghouse-service:8087` |

## Report Service

Backend:

```text
report-service.banquito-switch.svc.cluster.local:8088
```

Rutas:

| Metodo | Ruta publica en Apigee | Backend |
| --- | --- | --- |
| `GET` | `/api/v2/payments/batches/{batchId}/report` | `report-service:8088` |
| `GET` | `/api/v2/payments/receipts/{batchId}` | `report-service:8088` |
| `GET` | `/api/v2/payments/receipts/{batchId}/pdf` | `report-service:8088` |
| `GET` | `/api/v2/reports/health` | `report-service:8088` |

## Notification Service

Backend:

```text
notification-service.banquito-switch.svc.cluster.local:8089
```

Rutas:

| Metodo | Ruta publica en Apigee | Backend |
| --- | --- | --- |
| `POST` | `/api/v2/notifications/send` | `notification-service:8089` |
| `GET` | `/api/v2/notifications/health` | `notification-service:8089` |

## Agrupacion sugerida de proxies Apigee

### Opcion A: proxy por dominio funcional

```text
core-api
  /api/v2/auth/login/staff
  /api/v2/accounts/**
  /api/v2/calendar/**
  /api/v2/eod/**
  /api/v2/accounting/**
  /api/v2/customers/**
  /api/v2/customer-subtypes
  /api/v2/branches/**
  /api/v2/holidays
  /api/v2/core-parameters

switch-api
  /api/v2/payments/**
  /api/v2/tariff/**
  /api/v2/clearing/**
  /api/v2/reports/**
  /api/v2/notifications/**
```

### Opcion B: proxy por microservicio

```text
account-core-api
accounting-api
party-api
file-reception-api
tariff-api
clearinghouse-api
report-api
notification-api
```

Para el proyecto universitario, la opcion A es mas simple de explicar:

```text
Un proxy para Core Bancario y un proxy para Switch de Pagos Masivos.
```

## Rutas minimas que usan los frontends

Segun las variables y codigo frontend revisado, como minimo Apigee debe cubrir:

```text
/api/v2/auth/login
/api/v2/auth/login/staff
/api/v2/auth/change-password
/api/v2/accounts/**
/api/v2/customers/**
/api/v2/customer-subtypes
/api/v2/branches/**
/api/v2/holidays/**
/api/v2/core-parameters
/api/v2/accounting/**
/api/v2/payments/**
/api/v2/clearing/**
```

## Seguridad recomendada en Apigee

Aplicar validacion JWT en todas las rutas privadas:

```text
Authorization: Bearer <token>
```

Issuer:

```text
https://securetoken.google.com/project-47695a8e-7cb2-4352-af2
```

Audience:

```text
project-47695a8e-7cb2-4352-af2
```

JWKS:

```text
https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com
```

Rutas que podrian ser publicas o semi-publicas segun criterio:

```text
/api/v2/auth/login
/api/v2/auth/login/staff
/api/v2/*/health
```

## Pendiente critico

Antes de que Apigee pueda enrutar realmente a los backends, se necesita exponer GKE con:

```text
Ingress
Gateway API
LoadBalancer
```

Actualmente los Services son:

```text
ClusterIP
```

Por tanto, el Target Endpoint de Apigee debe ser el endpoint publico del Ingress/Gateway/LoadBalancer, no el DNS interno de Kubernetes.
