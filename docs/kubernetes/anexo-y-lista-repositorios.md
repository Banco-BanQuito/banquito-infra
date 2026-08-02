# Anexo Y - Lista de repositorios BanQuito

Este anexo consolida los repositorios utilizados en el proyecto BanQuito para el despliegue en Google Cloud, Kubernetes, Pub/Sub, Apigee, frontends e infraestructura.

## Core Bancario

| Repositorio | Rama | URL | Ultimo commit validado |
| --- | --- | --- | --- |
| `banquito-account-core-service` | `main` | https://github.com/Banco-BanQuito/banquito-account-core-service.git | `56812c4` - test: improve account core coverage |
| `banquito-accounting-service` | `main` | https://github.com/Banco-BanQuito/banquito-accounting-service.git | `ef19fec` - test: configure accounting coverage |
| `banquito-party-service` | `main` | https://github.com/Banco-BanQuito/banquito-party-service.git | `89dd328` - test: improve party service coverage |

## Switch de Pagos Masivos

| Repositorio | Rama | URL | Ultimo commit validado |
| --- | --- | --- | --- |
| `banquito-file-reception-service` | `main` | https://github.com/Banco-BanQuito/banquito-file-reception-service.git | `daffff3` - refactor: keep file reception focused on batch validation |
| `banquito-payment-line-classifier-service` | `main` | https://github.com/Banco-BanQuito/banquito-payment-line-classifier-service.git | `28fd704` - test: configure classifier coverage |
| `banquito-payment-line-publisher-service` | `main` | https://github.com/Banco-BanQuito/banquito-payment-line-publisher-service.git | `f64e541` - test: configure publisher coverage |
| `banquito-payment-line-subscriber-service` | `main` | https://github.com/Banco-BanQuito/banquito-payment-line-subscriber-service.git | `4eebf77` - feat: delegate payment line processing by grpc |
| `banquito-internal-payment-processor-service` | `main` | https://github.com/Banco-BanQuito/banquito-internal-payment-processor-service.git | `1928dc4` - feat: send payment notifications asynchronously |
| `banquito-clearinghouse-service` | `main` | https://github.com/Banco-BanQuito/banquito-clearinghouse-service.git | `562dace` - feat: route off-us payments to external banks |
| `banquito-tariff-service` | `main` | https://github.com/Banco-BanQuito/banquito-tariff-service.git | `a9156c8` - test: configure tariff coverage |
| `banquito-report-service` | `main` | https://github.com/Banco-BanQuito/banquito-report-service.git | `e687849` - test: configure report coverage |
| `banquito-notification-service` | `main` | https://github.com/Banco-BanQuito/banquito-notification-service.git | `250bf0c` - test: configure notification coverage |

## Frontends

| Repositorio | Rama | URL | Ultimo commit validado |
| --- | --- | --- | --- |
| `banquito-teller-frontend` | `main` | https://github.com/Banco-BanQuito/banquito-teller-frontend.git | `0361619` - Read VM deploy secrets from Secret Manager |
| `banquito-web-personas-frontend` | `main` | https://github.com/Banco-BanQuito/banquito-web-personas-frontend.git | `efb9eab` - Read VM deploy secrets from Secret Manager |
| `banquito-web-empresas-frontend` | `main` | https://github.com/Banco-BanQuito/banquito-web-empresas-frontend.git | `5c57d09` - Read VM deploy secrets from Secret Manager |
| `banquito-frontend-web-operador` | `main` | https://github.com/Banco-BanQuito/banquito-frontend-web-operador.git | `6dca9ac` - Read VM deploy secrets from Secret Manager |

## Infraestructura

| Repositorio | Rama | URL | Ultimo commit validado |
| --- | --- | --- | --- |
| `banquito-infra` | `main` | https://github.com/Banco-BanQuito/banquito-infra.git | `7ef188d` - docs: update gke switch and secret manager configuration |

## Estado de sincronizacion

Al momento de registrar este anexo, los repositorios locales quedaron sincronizados con `origin/main`, sin commits locales pendientes.
