# Anexo A - Rutas backend para Apigee

## Objetivo

Inventariar las rutas HTTP reales de los backends para configurar proxies en Apigee.

## Backends

| Microservicio | Namespace | Service | HTTP |
| --- | --- | --- | ---: |
| Account Core | `banquito-core` | `account-core-service` | 8081 |
| Accounting | `banquito-core` | `accounting-service` | 8082 |
| Party | `banquito-core` | `party-service` | 8083 |
| File Reception | `banquito-switch` | `file-reception-service` | 8084 |
| Tariff | `banquito-switch` | `tariff-service` | 8086 |
| Clearinghouse | `banquito-switch` | `clearinghouse-service` | 8087 |
| Report | `banquito-switch` | `report-service` | 8088 |
| Notification | `banquito-switch` | `notification-service` | 8089 |

## Account Core

Backend: `account-core-service:8081`

```text
POST  /api/v2/auth/login/staff
GET   /api/v2/accounts/{accountIdOrNumber}
PATCH /api/v2/accounts/{accountNumber}/activate
PATCH /api/v2/accounts/{accountNumber}/inactivate
PATCH /api/v2/accounts/{accountNumber}/block
PATCH /api/v2/accounts/{accountNumber}/suspend
GET   /api/v2/accounts/subtypes
GET   /api/v2/accounts/customer/{customerId}
GET   /api/v2/accounts/customer/{customerId}/favorite
GET   /api/v2/accounts/{accountIdOrNumber}/balance
GET   /api/v2/accounts/{accountIdOrNumber}/transactions
POST  /api/v2/accounts/open
POST  /api/v2/accounts/teller/deposit
POST  /api/v2/accounts/teller/withdrawal
POST  /api/v2/accounts/transfer/p2p
POST  /api/v2/accounts/transfer/external
GET   /api/v2/accounts/health
GET   /api/v2/calendar/accounting-date
GET   /api/v2/calendar/holidays/check
GET   /api/v2/eod/daily-transactions-file
POST  /api/v2/payments/batch-credit
POST  /api/v2/payments/corporate-debit
POST  /api/v2/payments/corporate-refund
POST  /api/v2/payments/offus-settlement
```

## Accounting

Backend: `accounting-service:8082`

```text
GET  /api/v2/accounting/health
POST /api/v2/accounting/entries
POST /api/v2/accounting/eod
GET  /api/v2/accounting/trial-balance
POST /api/v2/accounting/auto-balance
GET  /api/v2/accounting/reports/csv
GET  /api/v2/accounting/reports/pdf
```

## Party

Backend: `party-service:8083`

```text
POST  /api/v2/auth/login
PUT   /api/v2/auth/change-password
GET   /api/v2/customers/by-account/{accountNumber}
GET   /api/v2/customers/{id}
POST  /api/v2/customers
PATCH /api/v2/customers/{id}/status/{status}
GET   /api/v2/customer-subtypes
GET   /api/v2/core-parameters
GET   /api/v2/branches
POST  /api/v2/branches
GET   /api/v2/holidays
```

## File Reception

Backend: `file-reception-service:8084`

```text
POST   /api/v2/payments/batches
GET    /api/v2/payments/batches/{batchId}/status
GET    /api/v2/payments/routing-codes
GET    /api/v2/payments/routing-codes/{code}/classify
POST   /api/v2/payments/routing-codes
DELETE /api/v2/payments/routing-codes/{code}
```

## Tariff

Backend: `tariff-service:8086`

```text
GET /api/v2/tariff/calculate
GET /api/v2/tariff/ranges
GET /api/v2/tariff/health
```

## Clearinghouse

Backend: `clearinghouse-service:8087`

```text
POST /api/v2/clearing/files/consolidate
GET  /api/v2/clearing/batches/{batchId}/file
GET  /api/v2/clearing/files
GET  /api/v2/clearing/files/{id}/csv
GET  /api/v2/clearing/files/{id}/txt
GET  /api/v2/clearing/files/{id}/pdf
```

## Report

Backend: `report-service:8088`

```text
GET /api/v2/payments/batches/{batchId}/report
GET /api/v2/payments/receipts/{batchId}
GET /api/v2/payments/receipts/{batchId}/pdf
GET /api/v2/reports/health
```

## Notification

Backend: `notification-service:8089`

```text
POST /api/v2/notifications/send
GET  /api/v2/notifications/health
```

## Rutas minimas para frontends

```text
/api/v2/auth/**
/api/v2/accounts/**
/api/v2/customers/**
/api/v2/customer-subtypes
/api/v2/branches/**
/api/v2/holidays/**
/api/v2/core-parameters
/api/v2/accounting/**
/api/v2/payments/**
/api/v2/clearing/**
/api/v2/reports/**
/api/v2/notifications/**
```

