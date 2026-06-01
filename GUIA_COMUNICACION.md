# Banco BanQuito V2 — Guía de Comunicación entre Microservicios

> **Grupo 1 · Mayo 2026**
> Anahy · Oscar · Bryan · Santiago · Alan · Paul · Johan · Anthony

Este documento es la referencia oficial de cómo se comunican todos los microservicios del proyecto. Cada compañero debe leer completa la sección general y luego su sección individual.

---

## Índice

1. [Arquitectura General](#1-arquitectura-general)
2. [Dónde está el API Gateway (Kong)](#2-dónde-está-el-api-gateway-kong)
3. [Repositorios y Responsables](#3-repositorios-y-responsables)
4. [Reglas de Comunicación](#4-reglas-de-comunicación)
5. [Flujo Completo de un Pago Masivo](#5-flujo-completo-de-un-pago-masivo)
6. [Sección por Persona](#6-sección-por-persona)
   - [Anahy — DevOps / Infra](#anahy--devops--infra)
   - [Oscar — account-core-service](#oscar--account-core-service)
   - [Bryan — accounting-service](#bryan--accounting-service)
   - [Santiago — party-service + Frontends Core](#santiago--party-service--frontends-core)
   - [Alan — file-reception-service](#alan--file-reception-service)
   - [Paul — routing-service](#paul--routing-service)
   - [Johan — tariff-service + clearinghouse-adapter](#johan--tariff-service--clearinghouse-adapter)
   - [Anthony — report-service + notification-service + Frontend Empresas](#anthony--report-service--notification-service--frontend-empresas)
7. [Catálogo Completo de Endpoints](#7-catálogo-completo-de-endpoints)
8. [Matriz de Comunicación](#8-matriz-de-comunicación)

---

## 1. Arquitectura General

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                         BANCO BANQUITO V2 — ECOSISTEMA COMPLETO                 │
└─────────────────────────────────────────────────────────────────────────────────┘

USUARIOS EXTERNOS
┌───────────────────┐  ┌────────────────────────┐  ┌──────────────────────────┐
│  Cajero Sucursal  │  │  Cliente Persona Física │  │  Tesorero / CFO Empresa  │
└────────┬──────────┘  └───────────┬────────────┘  └────────────┬─────────────┘
         │                         │                             │
         ▼                         ▼                             ▼
┌─────────────────┐  ┌─────────────────────────┐  ┌────────────────────────────┐
│    Ventanilla   │  │   Banca Web Personas    │  │    Banca Web Empresas      │
│ (teller-front.) │  │ (web-personas-frontend) │  │ (web-empresas-frontend)    │
│  Santiago :3001 │  │    Santiago :3002        │  │    Anthony :3003           │
└────────┬────────┘  └───────────┬─────────────┘  └────────────┬───────────────┘
         │                       │                              │
         │    HTTP al browser    │                              │
         ▼                       ▼                              ▼
┌─────────────────────────────────────────┐  ┌─────────────────────────────────┐
│         KONG CORE  (API Gateway)        │  │    KONG SWITCH  (API Gateway)   │
│         Anahy · localhost:8000          │  │    Anahy · localhost:8010        │
│  Enruta peticiones al Core de Cuentas  │  │  Enruta peticiones al Switch    │
└──────────────┬──────────────────────────┘  └─────────────┬───────────────────┘
               │                                            │
       ┌───────┴──────────────┐                   ┌────────┴──────────────────┐
       │                      │                   │                           │
       ▼                      ▼                   ▼                           ▼
┌─────────────┐  ┌───────────────────┐  ┌──────────────────┐  ┌─────────────────────┐
│ account-    │  │ accounting-       │  │ file-reception-  │  │ routing-service     │
│ core-service│  │ service           │  │ service          │  │ Paul :8085          │
│ Oscar :8081 │  │ Bryan :8082       │  │ Alan :8084       │  │ MongoDB             │
│ PostgreSQL  │  │ PostgreSQL        │  │ PostgreSQL +     │  │                     │
└──────┬──────┘  └───────────────────┘  │ MongoDB          │  └──────┬──────────────┘
       │                  ▲             └────────┬─────────┘         │
       │ llama directo    │ llama directo        │ publica            │ On-Us → Kong Core
       ▼                  │                      ▼ RabbitMQ           │ Off-Us → RabbitMQ
┌─────────────┐           │              ┌──────────────────┐         │
│ party-      │           │              │   RabbitMQ       │◄────────┘
│ service     │           │              │ payment.lines.   │
│ Santiago    │           │              │ queue            │──► routing-service
│ :8083       │           └──────────────┤                  │
│ PostgreSQL  │    clearinghouse-adapter │ clearing.        │
└─────────────┘    Johan :8087  ─────────► outbound.queue   │
                                         └──────────────────┘
                 ┌──────────────┐
                 │tariff-service│◄── routing-service llama directo
                 │ Johan :8086  │
                 │ PostgreSQL   │
                 └──────────────┘
                 ┌─────────────────┐
                 │ report-service  │◄── lee MongoDB de routing
                 │ Anthony :8088   │
                 └─────────────────┘
                 ┌──────────────────────┐
                 │ notification-service │◄── llamado directo desde routing/report
                 │ Anthony :8089        │
                 │ SMTP (sin BD)        │
                 └──────────────────────┘
```

---

## 2. Dónde está el API Gateway (Kong)

Kong es el **portero** del sistema. Ningún frontend ni sistema externo llama directamente a los microservicios. Todo pasa primero por Kong.

### Hay dos instancias de Kong

| Instancia | Puerto local | Para qué sirve |
|---|---|---|
| **Kong Core** | `localhost:8000` (proxy) / `localhost:8001` (admin) | Recibe peticiones de Ventanilla, Banca Web Personas, y del Switch cuando cruza sistemas |
| **Kong Switch** | `localhost:8010` (proxy) / `localhost:8011` (admin) | Recibe peticiones de la Banca Web Empresas |

### Kong en Docker (comunicación interna)

Dentro de Docker, los microservicios se hablan por **nombre de contenedor**. Kong no es diferente:

```
Desde cualquier contenedor del Switch que quiera llamar al Core:
  http://kong-core:8000/api/v2/...
                 ▲
                 └── nombre del contenedor Docker, puerto 8000 interno
```

Esto funciona porque en el [docker-compose.yml](docker-compose.yml) `kong-core` está en **dos redes**: `core-net` y `switch-net`. Por eso los servicios del Switch pueden alcanzarlo.

### ¿Por qué el Switch pasa por Kong para llegar al Core?

Por seguridad y trazabilidad. Kong registra cada petición, aplica rate limiting y permite que Anahy controle qué rutas están permitidas. Si el Switch llamara directamente a Oscar, se saltaría ese control.

---

## 3. Repositorios y Responsables

| # | Repositorio | Responsable | Puerto | Tipo |
|---|---|---|---|---|
| 1 | [banquito-infra](https://github.com/Banco-BanQuito/banquito-infra) | **Anahy** | — | Infra |
| 2 | [banquito-account-core-service](https://github.com/Banco-BanQuito/banquito-account-core-service) | **Oscar** | 8081 | Micro Core |
| 3 | [banquito-accounting-service](https://github.com/Banco-BanQuito/banquito-accounting-service) | **Bryan** | 8082 | Micro Core |
| 4 | [banquito-party-service](https://github.com/Banco-BanQuito/banquito-party-service) | **Santiago** | 8083 | Micro Core |
| 5 | [banquito-teller-frontend](https://github.com/Banco-BanQuito/banquito-teller-frontend) | **Santiago** | 3001 | Frontend |
| 6 | [banquito-web-personas-frontend](https://github.com/Banco-BanQuito/banquito-web-personas-frontend) | **Santiago** | 3002 | Frontend |
| 7 | [banquito-file-reception-service](https://github.com/Banco-BanQuito/banquito-file-reception-service) | **Alan** | 8084 | Micro Switch |
| 8 | [banquito-routing-service](https://github.com/Banco-BanQuito/banquito-routing-service) | **Paul** | 8085 | Micro Switch |
| 9 | [banquito-tariff-service](https://github.com/Banco-BanQuito/banquito-tariff-service) | **Johan** | 8086 | Micro Switch |
| 10 | [banquito-clearinghouse-adapter](https://github.com/Banco-BanQuito/banquito-clearinghouse-adapter) | **Johan** | 8087 | Micro Switch |
| 11 | [banquito-report-service](https://github.com/Banco-BanQuito/banquito-report-service) | **Anthony** | 8088 | Micro Switch |
| 12 | [banquito-notification-service](https://github.com/Banco-BanQuito/banquito-notification-service) | **Anthony** | 8089 | Micro Switch |
| 13 | [banquito-web-empresas-frontend](https://github.com/Banco-BanQuito/banquito-web-empresas-frontend) | **Anthony** | 3003 | Frontend |

---

## 4. Reglas de Comunicación

Estas son las 4 reglas que **todos deben memorizar** antes de escribir cualquier llamada HTTP.

### Regla 1 — Dentro del Core: llamada directa por nombre de contenedor

Los microservicios del Core se hablan **directo**, sin pasar por Kong.

```
account-core-service  →  accounting-service
URL: http://accounting-service:8082/api/v2/accounting/entries

account-core-service  →  party-service
URL: http://party-service:8083/api/v2/customers/{id}
```

### Regla 2 — Dentro del Switch: llamada directa o por RabbitMQ

```
routing-service  →  tariff-service      (HTTP directo)
URL: http://tariff-service:8086/api/v2/tariff/calculate

routing-service  →  clearinghouse       (RabbitMQ asíncrono)
Cola: clearing.outbound.queue

routing-service  →  notification-service (HTTP directo)
URL: http://notification-service:8089/api/v2/notifications/send

report-service   →  MongoDB de routing   (conexión directa MongoDB, solo lectura)
URI: mongodb://mongo-routing:27018/routingdb
```

### Regla 3 — Switch → Core: SIEMPRE pasa por Kong Core ⚠️

Cuando cualquier servicio del Switch necesita llamar al Core, **obligatoriamente** pasa por Kong Core.

```
routing-service (Switch)  →  Kong Core  →  account-core-service (Core)
URL desde Docker: http://kong-core:8000/api/v2/payments/batch-credit
URL desde Docker: http://kong-core:8000/api/v2/payments/corporate-debit

clearinghouse-adapter (Switch)  →  Kong Core  →  accounting-service (Core)
URL desde Docker: http://kong-core:8000/api/v2/accounting/entries
```

### Regla 4 — Frontends: siempre pasan por Kong (desde el browser)

Los frontends son apps React/Angular que corren en el **browser del usuario**, no en Docker. Por eso usan `localhost`.

```
Ventanilla y Banca Web Personas (Santiago)  →  http://localhost:8000/api/v2/...
Banca Web Empresas (Anthony)                →  http://localhost:8010/api/v2/...
```

---

## 5. Flujo Completo de un Pago Masivo

Este es el escenario principal del proyecto: una empresa paga su nómina.

```
PASO 1 — El tesorero sube el archivo CSV de nómina
═══════════════════════════════════════════════════

  [Browser Tesorero]
       │ POST http://localhost:8010/api/v2/payments/batches
       │ (archivo CSV multipart)
       ▼
  [Kong Switch :8010]
       │ enruta a →
       ▼
  [file-reception-service Alan :8084]
       │ valida estructura + hash SHA-256 (anti-duplicado)
       │ responde HTTP 202 INMEDIATO al browser
       │ fragmenta el archivo línea por línea
       │ publica cada línea en RabbitMQ →
       ▼
  [RabbitMQ cola: payment.lines.queue]


PASO 2 — El routing-service consume la cola y enruta
══════════════════════════════════════════════════════

  [RabbitMQ cola: payment.lines.queue]
       │ consumido por múltiples workers en paralelo
       ▼
  [routing-service Paul :8085]
       │
       ├─► Si ROUTING_CODE = BanQuito (On-Us)
       │       │ POST http://kong-core:8000/api/v2/payments/batch-credit
       │       │                    ▼
       │       │          [Kong Core :8000]
       │       │                    │ enruta a →
       │       │                    ▼
       │       │          [account-core-service Oscar :8081]
       │       │                    │ acredita cuenta beneficiario
       │       │                    │ llama síncronamente a →
       │       │                    ▼
       │       │          [accounting-service Bryan :8082]
       │       │                    │ genera asiento contable
       │       │                    └─► HTTP 200 OK
       │       │          [account-core-service]
       │       │                    └─► HTTP 200 OK a routing
       │       │
       │       └─► (exitoso) POST http://notification-service:8089/api/v2/notifications/send
       │                     Anthony envía email al beneficiario
       │
       └─► Si ROUTING_CODE = otro banco (Off-Us)
               │ publica en RabbitMQ cola: clearing.outbound.queue
               ▼
       [clearinghouse-adapter Johan :8087]
               │ genera archivo TXT COMPENSACION_YYYYMMDD_BATCHID.txt
               │ POST http://kong-core:8000/api/v2/accounting/entries
               │             ▼
               │   [accounting-service Bryan :8082]
               │             │ asiento: Débito 2.1.0.02 Corrientes + Crédito 1.1.0.01 Banco Central
               └─► archivo guardado en /compensacion/outbound/


PASO 3 — Al completar el lote, se cobra la comisión
═════════════════════════════════════════════════════

  [routing-service Paul]
       │ detecta: exitosas + rechazadas == total declarado
       │
       │ GET http://tariff-service:8086/api/v2/tariff/calculate?successful_tx=97
       ▼
  [tariff-service Johan :8086]
       │ calcula: commission = 97 * $0.80 = $77.60
       │          IVA = $77.60 * 0.15 = $11.64
       │          total_charge = $89.24
       └─► responde JSON con desglose
       ▼
  [routing-service Paul]
       │ POST http://kong-core:8000/api/v2/payments/corporate-debit
       │ body: { accountId: cuenta_empresa, totalAmount: 82450.00, commissionAmount: 89.24 }
       ▼
  [Kong Core :8000]  →  [account-core-service Oscar :8081]
       │ débita la cuenta de la empresa
       │ calcula IVA internamente (confirma el valor de Johan)
       │ llama a Bryan: asiento crédito 4.1.0.01 Ingresos + crédito 2.2.0.01 IVA Retenido
       └─► HTTP 200 OK


PASO 4 — El tesorero consulta el resultado
═══════════════════════════════════════════

  [Browser Tesorero] — polling cada 10 segundos
       │ GET http://localhost:8010/api/v2/payments/batches/{batchId}/status
       ▼
  [Kong Switch]  →  [routing-service Paul :8085]
       └─► retorna contadores: exitosas=97, rechazadas=3, en_proceso=0

  [Browser Tesorero] — cuando status=COMPLETED
       │ GET http://localhost:8010/api/v2/payments/batches/{batchId}/report
       ▼
  [Kong Switch]  →  [report-service Anthony :8088]
       │ lee MongoDB de Paul (solo lectura)
       └─► retorna CSV con detalle línea por línea

       │ GET http://localhost:8010/api/v2/payments/receipts/{batchId}
       ▼
  [Kong Switch]  →  [report-service Anthony :8088]
       └─► retorna comprobante con totales y comisión cobrada
```

---

## 6. Sección por Persona

---

### Anahy — DevOps / Infra

**Repositorio:** [banquito-infra](https://github.com/Banco-BanQuito/banquito-infra)

**Tu rol:** Eres quien mantiene toda la infraestructura corriendo. Nadie expone un endpoint sin coordinarte.

**Lo que ya hiciste:**
- Organización GitHub `Banco-BanQuito` con 13 repos
- Branch protection en todos los repos (PR obligatorio)
- `docker-compose.yml` completo con todos los servicios
- `kong/core/kong.yml` y `kong/switch/kong.yml` (rutas del API Gateway)
- Templates de Dockerfile para Spring Boot y Nginx
- `.github/workflows/ci-template.yml` para CI/CD

**Variables de entorno que cada compañero necesita de ti:**
- `GCP_SA_KEY` — JSON del Service Account de GCP
- `GCP_PROJECT_ID` — ID del proyecto GCP

**Cómo levantar todo localmente:**
```bash
cd banquito-infra
docker-compose up -d
```

---

### Oscar — account-core-service

**Repositorio:** [banquito-account-core-service](https://github.com/Banco-BanQuito/banquito-account-core-service)
**Puerto:** `:8081` · **BD:** PostgreSQL `postgres-core:5433/accountdb`

#### Endpoints que Oscar implementa

| Método | URL | Quién lo llama | Via |
|---|---|---|---|
| `GET` | `/api/v2/accounts/{accountId}/balance` | Ventanilla, Banca Web Personas | Kong Core |
| `GET` | `/api/v2/accounts/{accountId}/transactions` | Banca Web Personas | Kong Core |
| `POST` | `/api/v2/accounts/teller/deposit` | Ventanilla | Kong Core |
| `POST` | `/api/v2/accounts/teller/withdrawal` | Ventanilla | Kong Core |
| `POST` | `/api/v2/accounts/transfer/p2p` | Banca Web Personas | Kong Core |
| `POST` | `/api/v2/payments/batch-credit` | routing-service (Paul) | Kong Core |
| `POST` | `/api/v2/payments/corporate-debit` | routing-service (Paul) | Kong Core |
| `GET` | `/api/v2/accounts/health` | K8s probes | Directo |

#### A quién llama Oscar

```
Después de CADA transacción exitosa:
  POST http://accounting-service:8082/api/v2/accounting/entries
  (Bryan)  ← llamada SÍNCRONA, si falla → ejecutar REVERSO

Para validar titular en P2P:
  GET http://party-service:8083/api/v2/customers/by-account/{accountNumber}
  (Santiago)
```

#### Regla crítica — Reverso compensatorio

```java
// Pseudocódigo obligatorio en account-core-service
try {
    afectarSaldo(cuenta, monto);  // paso 1
    accountingService.postEntries(asiento);  // paso 2 — síncrono
} catch (AccountingException | TimeoutException e) {
    // SI FALLA EL CONTABLE → REVERTIR EL SALDO INMEDIATAMENTE
    revertirSaldo(cuenta, monto);
    throw new ServiceUnavailableException("HTTP 503");
}
```

#### Variables de entorno en application.properties

```properties
spring.datasource.url=${DB_URL:jdbc:postgresql://postgres-core:5433/accountdb}
spring.datasource.username=${DB_USER:banquito}
spring.datasource.password=${DB_PASS:banquito123}
accounting.service.url=${ACCOUNTING_SERVICE_URL:http://accounting-service:8082}
party.service.url=${PARTY_SERVICE_URL:http://party-service:8083}
cut.off.time=${CUT_OFF_TIME:20:00}
server.port=${SERVER_PORT:8081}
```

---

### Bryan — accounting-service

**Repositorio:** [banquito-accounting-service](https://github.com/Banco-BanQuito/banquito-accounting-service)
**Puerto:** `:8082` · **BD:** PostgreSQL `postgres-accounting:5434/accountingdb`

#### Endpoints que Bryan implementa

| Método | URL | Quién lo llama | Via |
|---|---|---|---|
| `POST` | `/api/v2/accounting/entries` | Oscar, clearinghouse-adapter (Johan) | Directo K8s |
| `POST` | `/api/v2/accounting/eod` | Job programado / admin | Directo K8s |
| `GET` | `/api/v2/accounting/trial-balance` | Consulta interna | Directo K8s |
| `GET` | `/api/v2/accounting/health` | K8s probes | Directo |

> ⚠️ Bryan no tiene endpoints externos. **Nadie llega a él desde Kong.** Solo lo llaman Oscar y Johan directamente por red interna de Docker.

#### Formato del payload que recibe de Oscar

```json
{
  "entryUuid": "uuid-único-de-la-transacción",
  "description": "Depósito ventanilla cliente 5",
  "entryDate": "2026-05-30",
  "lines": [
    { "accountCode": "2.1.0.01", "movementType": "CREDITO", "amount": 500.00, "reference": "DEP-001" },
    { "accountCode": "1.1.0.02", "movementType": "DEBITO",  "amount": 500.00, "reference": "DEP-001" }
  ]
}
```

#### Regla de validación suma cero

```
Si suma(DEBITOS) != suma(CREDITOS) → responder HTTP 422
Si alguna cuenta es ESTRUCTURAL     → responder HTTP 422
Si todo OK                          → responder HTTP 200
```

#### Tipos de asiento por origen (lo que Bryan debe esperar)

| Canal | Cuenta débito | Cuenta crédito |
|---|---|---|
| Ventanilla depósito | `1.1.0.02` Bóveda (DEBITO) | `2.1.0.01` Ahorros cliente (CREDITO) |
| Ventanilla retiro | `2.1.0.01` Ahorros cliente (DEBITO) | `1.1.0.02` Bóveda (CREDITO) |
| P2P | Cuenta origen cliente (DEBITO) | Cuenta destino cliente (CREDITO) |
| Switch On-Us comisión | `2.1.0.02` Corriente empresa (DEBITO) | `4.1.0.01` Ingresos (CREDITO) + `2.2.0.01` IVA (CREDITO) |
| Switch Off-Us | `2.1.0.02` Corriente cliente (DEBITO) | `1.1.0.01` Banco Central (CREDITO) |

#### Variables de entorno

```properties
spring.datasource.url=${DB_URL:jdbc:postgresql://postgres-accounting:5434/accountingdb}
spring.datasource.username=${DB_USER:banquito}
spring.datasource.password=${DB_PASS:banquito123}
server.port=${SERVER_PORT:8082}
```

---

### Santiago — party-service + Frontends Core

**Repositorios:**
- [banquito-party-service](https://github.com/Banco-BanQuito/banquito-party-service) — Puerto `:8083`
- [banquito-teller-frontend](https://github.com/Banco-BanQuito/banquito-teller-frontend) — Puerto `:3001`
- [banquito-web-personas-frontend](https://github.com/Banco-BanQuito/banquito-web-personas-frontend) — Puerto `:3002`

#### Endpoints que Santiago implementa (party-service)

| Método | URL | Quién lo llama | Via |
|---|---|---|---|
| `GET` | `/api/v2/customers/{customerId}` | Ventanilla (frontend), Oscar | Kong Core |
| `GET` | `/api/v2/customers/by-account/{accountNumber}` | Banca Web Personas (frontend) | Kong Core |
| `GET` | `/api/v2/customers/health` | K8s probes | Directo |

#### Qué URLs usa cada frontend de Santiago

**Ventanilla (teller-frontend):**
```javascript
const KONG_CORE = "http://localhost:8000";  // variable de entorno VITE_API_BASE_URL

// Buscar cliente antes de operar
GET  `${KONG_CORE}/api/v2/customers/{cedulaOrId}`

// Operaciones de caja
POST `${KONG_CORE}/api/v2/accounts/teller/deposit`
POST `${KONG_CORE}/api/v2/accounts/teller/withdrawal`
```

**Banca Web Personas (web-personas-frontend):**
```javascript
const KONG_CORE = "http://localhost:8000";

// Dashboard al iniciar sesión
GET  `${KONG_CORE}/api/v2/accounts/{accountId}/balance`
GET  `${KONG_CORE}/api/v2/accounts/{accountId}/transactions?page=0&size=20`

// Transferencia P2P
GET  `${KONG_CORE}/api/v2/customers/by-account/{destAccountNumber}` // validar destinatario
POST `${KONG_CORE}/api/v2/accounts/transfer/p2p`
```

#### Variables de entorno (party-service)

```properties
spring.datasource.url=${DB_URL:jdbc:postgresql://postgres-party:5435/partydb}
spring.datasource.username=${DB_USER:banquito}
spring.datasource.password=${DB_PASS:banquito123}
server.port=${SERVER_PORT:8083}
```

---

### Alan — file-reception-service

**Repositorio:** [banquito-file-reception-service](https://github.com/Banco-BanQuito/banquito-file-reception-service)
**Puerto:** `:8084` · **BD:** PostgreSQL `postgres-file:5436/filedb` + MongoDB `mongo-file:27019/filedb`

#### Endpoints que Alan implementa

| Método | URL | Quién lo llama | Via |
|---|---|---|---|
| `POST` | `/api/v2/payments/batches` | Banca Web Empresas (Anthony) | Kong Switch |
| `GET` | `/api/v2/payments/health` | K8s probes | Directo |

#### Flujo interno de Alan

```
Recibe archivo CSV → Valida estructura + cabecera + suma montos
       │
       ├─► Detecta lote duplicado (SHA-256 en los últimos 30 días) → HTTP 409
       │
       ├─► Si después de 18:00 → scheduled_process_at = siguiente día hábil
       │
       └─► Responde HTTP 202 INMEDIATO
           Luego fragmenta el archivo línea por línea y publica en RabbitMQ:

           Formato del mensaje en RabbitMQ:
           {
             "batchId": "uuid-lote",
             "lineNumber": 1,
             "routingCode": "001",
             "accountDestination": "220045",
             "amount": 1000.00,
             "reference": "Nómina mayo",
             "beneficiaryName": "Juan Pérez",
             "beneficiaryEmail": "juan@email.com"
           }
```

#### Catálogo de routing codes (tabla switch_parameter)

```
"001" → BanQuito → On-Us  (routing-service lo procesa vía Core)
"002" → Banco Pichincha → Off-Us  (va a clearing)
"030" → Produbanco → Off-Us
"034" → Banco Guayaquil → Off-Us
código desconocido → rechazar esa línea (no el lote completo)
```

#### Variables de entorno

```properties
spring.datasource.url=${DB_URL:jdbc:postgresql://postgres-file:5436/filedb}
spring.datasource.username=${DB_USER:banquito}
spring.datasource.password=${DB_PASS:banquito123}
spring.data.mongodb.uri=${MONGODB_URI:mongodb://mongo-file:27019/filedb}
rabbitmq.url=${RABBITMQ_URL:amqp://banquito:banquito123@rabbitmq:5672/banquito}
routing.queue=${ROUTING_QUEUE:payment.lines.queue}
cut.off.time=${CUT_OFF_TIME:18:00}
server.port=${SERVER_PORT:8084}
```

---

### Paul — routing-service

**Repositorio:** [banquito-routing-service](https://github.com/Banco-BanQuito/banquito-routing-service)
**Puerto:** `:8085` · **BD:** MongoDB `mongo-routing:27018/routingdb`

#### Endpoints que Paul implementa

| Método | URL | Quién lo llama | Via |
|---|---|---|---|
| `GET` | `/api/v2/payments/batches/{batchId}/status` | Banca Web Empresas (Anthony) | Kong Switch |
| `GET` | `/api/v2/payments/routing/health` | K8s probes | Directo |

#### A quién llama Paul y cómo

```
1. Consume cola RabbitMQ: payment.lines.queue
   (múltiples workers en paralelo)

2. Para cada mensaje:

   Si routingCode = "001" (On-Us):
     POST http://kong-core:8000/api/v2/payments/batch-credit
     Body: {
       "batchId": "uuid-lote",
       "credits": [
         { "accountId": 5, "amount": 1000.00, "reference": "Nómina mayo", "transactionUuid": "uuid-linea" }
       ]
     }
     Si HTTP 200 → registrar payment_detail.status = "EXITOSA"
     Si error    → registrar payment_detail.status = "RECHAZADA"

     (opcional, si exitosa) POST http://notification-service:8089/api/v2/notifications/send

   Si routingCode = otro banco (Off-Us):
     Publicar en RabbitMQ cola: clearing.outbound.queue
     Registrar payment_detail.status = "ENVIADO_CLEARING"

3. Cuando lote completo (exitosas + rechazadas == total_declarado):
     GET http://tariff-service:8086/api/v2/tariff/calculate?successful_tx=97&batchId=uuid
     → Recibe: { totalCharge: 89.24 }

     POST http://kong-core:8000/api/v2/payments/corporate-debit
     Body: { accountId: cuenta_empresa, totalAmount: 82450.00, commissionAmount: 89.24, batchId: "uuid" }
```

#### Variables de entorno

```properties
spring.data.mongodb.uri=${MONGODB_URI:mongodb://mongo-routing:27018/routingdb}
rabbitmq.url=${RABBITMQ_URL:amqp://banquito:banquito123@rabbitmq:5672/banquito}
input.queue=${INPUT_QUEUE:payment.lines.queue}
clearing.queue=${CLEARING_QUEUE:clearing.outbound.queue}
core.gateway.url=${CORE_GATEWAY_URL:http://kong-core:8000/api/v2}
tariff.service.url=${TARIFF_SERVICE_URL:http://tariff-service:8086}
notification.service.url=${NOTIFICATION_SERVICE_URL:http://notification-service:8089}
server.port=${SERVER_PORT:8085}
```

---

### Johan — tariff-service + clearinghouse-adapter

**Repositorios:**
- [banquito-tariff-service](https://github.com/Banco-BanQuito/banquito-tariff-service) — Puerto `:8086`
- [banquito-clearinghouse-adapter](https://github.com/Banco-BanQuito/banquito-clearinghouse-adapter) — Puerto `:8087`

#### Endpoints — tariff-service

| Método | URL | Quién lo llama | Via |
|---|---|---|---|
| `GET` | `/api/v2/tariff/calculate?successful_tx={N}&batchId={id}` | routing-service (Paul) | Directo K8s |
| `GET` | `/api/v2/tariff/health` | K8s probes | Directo |

**Respuesta esperada:**
```json
{
  "successfulTx": 97,
  "unitFee": 0.80,
  "commissionSubtotal": 77.60,
  "ivaRate": 0.15,
  "ivaAmount": 11.64,
  "totalCharge": 89.24,
  "tariffRangeApplied": "50-100 tx"
}
```

#### Flujo — clearinghouse-adapter

```
1. Consume RabbitMQ cola: clearing.outbound.queue
   (mensajes Off-Us publicados por Paul)

2. Por cada lote Off-Us completo:
   Genera archivo TXT: COMPENSACION_YYYYMMDD_BATCHID.txt
   Formato por línea (pipe separado):
   BATCH_ID|TX_ID|ROUTING_CODE|CTA_ORIGEN|CTA_DESTINO|MONTO|MONEDA|CONCEPTO|FECHA_VALOR|ESTADO

3. Solicita asiento contable a Bryan:
   POST http://kong-core:8000/api/v2/accounting/entries
   Asiento:
   - DEBITO:  2.1.0.02 Corrientes del cliente
   - CREDITO: 1.1.0.01 Banco Central/Cámara de Compensación

4. Guarda TXT en: /compensacion/outbound/COMPENSACION_YYYYMMDD_BATCHID.txt
```

#### Variables de entorno (tariff-service)

```properties
spring.datasource.url=${DB_URL:jdbc:postgresql://postgres-tariff:5437/tariffdb}
spring.datasource.username=${DB_USER:banquito}
spring.datasource.password=${DB_PASS:banquito123}
server.port=${SERVER_PORT:8086}
```

#### Variables de entorno (clearinghouse-adapter)

```properties
spring.data.mongodb.uri=${MONGODB_URI:mongodb://mongo-clearing:27020/clearingdb}
rabbitmq.url=${RABBITMQ_URL:amqp://banquito:banquito123@rabbitmq:5672/banquito}
clearing.queue=${CLEARING_QUEUE:clearing.outbound.queue}
core.gateway.url=${CORE_GATEWAY_URL:http://kong-core:8000/api/v2}
output.path=${OUTPUT_PATH:/compensacion/outbound/}
server.port=${SERVER_PORT:8087}
```

---

### Anthony — report-service + notification-service + Frontend Empresas

**Repositorios:**
- [banquito-report-service](https://github.com/Banco-BanQuito/banquito-report-service) — Puerto `:8088`
- [banquito-notification-service](https://github.com/Banco-BanQuito/banquito-notification-service) — Puerto `:8089`
- [banquito-web-empresas-frontend](https://github.com/Banco-BanQuito/banquito-web-empresas-frontend) — Puerto `:3003`

#### Endpoints — report-service

| Método | URL | Quién lo llama | Via |
|---|---|---|---|
| `GET` | `/api/v2/payments/batches/{batchId}/report` | Banca Web Empresas | Kong Switch |
| `GET` | `/api/v2/payments/receipts/{batchId}` | Banca Web Empresas | Kong Switch |
| `GET` | `/api/v2/reports/health` | K8s probes | Directo |

> **Importante:** report-service **lee directamente la MongoDB de Paul** (`mongo-routing:27018`). No hace llamadas HTTP a Paul. Son bases de datos independientes compartidas solo en lectura.

```properties
# Variables en report-service
spring.data.mongodb.uri=${MONGODB_URI:mongodb://mongo-routing:27018/routingdb}
notification.service.url=${NOTIFICATION_SERVICE_URL:http://notification-service:8089}
server.port=${SERVER_PORT:8088}
```

#### Endpoint — notification-service

| Método | URL | Quién lo llama | Via |
|---|---|---|---|
| `POST` | `/api/v2/notifications/send` | routing-service (Paul), report-service (Anthony) | Directo K8s — **NUNCA expuesto en Kong** |
| `GET` | `/api/v2/notifications/health` | K8s probes | Directo |

```json
// Payload que recibe notification-service:
{
  "paymentDetailId": 123,
  "emailTo": "empleado@empresa.com",
  "subject": "Pago recibido - BanQuito",
  "bodyTemplate": "BENEFICIARY_PAYMENT",
  "variables": {
    "amount": "1000.00",
    "companyName": "Empresa ABC",
    "concept": "Nómina Mayo 2026",
    "date": "2026-05-30"
  }
}
```

```properties
# Variables en notification-service
smtp.host=${SMTP_HOST:smtp.gmail.com}
smtp.port=${SMTP_PORT:587}
smtp.user=${SMTP_USER:banquito.notificaciones@gmail.com}
smtp.pass=${SMTP_PASS:cambiar-por-app-password}
server.port=${SERVER_PORT:8089}
```

#### Qué URLs usa el Frontend Banca Web Empresas

```javascript
const KONG_SWITCH = "http://localhost:8010";  // VITE_API_BASE_URL

// Subir archivo
POST `${KONG_SWITCH}/api/v2/payments/batches`       // → Alan

// Seguimiento (polling cada 10s)
GET  `${KONG_SWITCH}/api/v2/payments/batches/{batchId}/status`  // → Paul

// Descargar reporte cuando status=COMPLETED
GET  `${KONG_SWITCH}/api/v2/payments/batches/{batchId}/report`  // → Anthony
GET  `${KONG_SWITCH}/api/v2/payments/receipts/{batchId}`        // → Anthony
```

---

## 7. Catálogo Completo de Endpoints

> **Versión de API:** `/api/v2/` en todos los endpoints.
> Ningún equipo puede crear endpoints nuevos sin coordinar con Anahy para registrarlos en Kong.

### CORE — account-core-service (Oscar)

| # | Método | Endpoint | Acceso | HTTP OK |
|---|---|---|---|---|
| 1 | `GET` | `/api/v2/accounts/{accountId}/balance` | Externo (Kong Core) | 200 |
| 2 | `GET` | `/api/v2/accounts/{accountId}/transactions?page=0&size=20&from=&to=` | Externo (Kong Core) | 200 |
| 3 | `POST` | `/api/v2/accounts/teller/deposit` | Externo (Kong Core) | 200 |
| 4 | `POST` | `/api/v2/accounts/teller/withdrawal` | Externo (Kong Core) | 200 |
| 5 | `POST` | `/api/v2/accounts/transfer/p2p` | Externo (Kong Core) | 200 |
| 6 | `POST` | `/api/v2/payments/batch-credit` | Interno Switch→Kong Core | 200 |
| 7 | `POST` | `/api/v2/payments/corporate-debit` | Interno Switch→Kong Core | 200 |
| 8 | `GET` | `/api/v2/accounts/health` | Interno K8s | 200 |

### CORE — accounting-service (Bryan)

| # | Método | Endpoint | Acceso | HTTP OK |
|---|---|---|---|---|
| 9 | `POST` | `/api/v2/accounting/entries` | Interno directo K8s | 200 |
| 10 | `POST` | `/api/v2/accounting/eod` | Interno job | 200 |
| 11 | `GET` | `/api/v2/accounting/trial-balance?date=YYYY-MM-DD` | Interno consulta | 200 |
| 12 | `GET` | `/api/v2/accounting/health` | Interno K8s | 200 |

### CORE — party-service (Santiago)

| # | Método | Endpoint | Acceso | HTTP OK |
|---|---|---|---|---|
| 13 | `GET` | `/api/v2/customers/{customerId}` | Externo (Kong Core) | 200 |
| 14 | `GET` | `/api/v2/customers/by-account/{accountNumber}` | Externo (Kong Core) | 200 |
| 15 | `GET` | `/api/v2/customers/health` | Interno K8s | 200 |

### SWITCH — file-reception-service (Alan)

| # | Método | Endpoint | Acceso | HTTP OK |
|---|---|---|---|---|
| 16 | `POST` | `/api/v2/payments/batches` | Externo (Kong Switch) | **202** |
| 17 | `GET` | `/api/v2/payments/health` | Interno K8s | 200 |

### SWITCH — routing-service (Paul)

| # | Método | Endpoint | Acceso | HTTP OK |
|---|---|---|---|---|
| 18 | `GET` | `/api/v2/payments/batches/{batchId}/status` | Externo (Kong Switch) | 200 |
| 19 | `GET` | `/api/v2/payments/routing/health` | Interno K8s | 200 |

### SWITCH — tariff-service (Johan)

| # | Método | Endpoint | Acceso | HTTP OK |
|---|---|---|---|---|
| 20 | `GET` | `/api/v2/tariff/calculate?successful_tx={N}&batchId={id}` | Interno directo K8s | 200 |
| 21 | `GET` | `/api/v2/tariff/health` | Interno K8s | 200 |

### SWITCH — clearinghouse-adapter (Johan)

| # | Método | Endpoint | Acceso | HTTP OK |
|---|---|---|---|---|
| 22 | `GET` | `/api/v2/clearing/batches/{batchId}/file` | Interno consulta | 200 |
| 23 | `GET` | `/api/v2/clearing/health` | Interno K8s | 200 |

### SWITCH — report-service (Anthony)

| # | Método | Endpoint | Acceso | HTTP OK |
|---|---|---|---|---|
| 24 | `GET` | `/api/v2/payments/batches/{batchId}/report` | Externo (Kong Switch) | 200 |
| 25 | `GET` | `/api/v2/payments/receipts/{batchId}` | Externo (Kong Switch) | 200 |
| 26 | `GET` | `/api/v2/reports/health` | Interno K8s | 200 |

### SWITCH — notification-service (Anthony)

| # | Método | Endpoint | Acceso | HTTP OK |
|---|---|---|---|---|
| 27 | `POST` | `/api/v2/notifications/send` | **Interno ÚNICAMENTE** | 200 |
| 28 | `GET` | `/api/v2/notifications/health` | Interno K8s | 200 |

---

## 8. Matriz de Comunicación

```
QUIEN LLAMA           QUIEN RECIBE              URL / MECANISMO                        VIA
─────────────────────────────────────────────────────────────────────────────────────────────
Oscar                 Bryan                     http://accounting-service:8082/...     Directo K8s
Oscar                 Santiago                  http://party-service:8083/...          Directo K8s
Paul                  Johan (tariff)            http://tariff-service:8086/...         Directo K8s
Paul                  Johan (clearing)          RabbitMQ: clearing.outbound.queue      RabbitMQ
Paul                  Anthony (notification)    http://notification-service:8089/...   Directo K8s
Anthony (report)      Paul (MongoDB)            mongodb://mongo-routing:27018/...      MongoDB lectura
─────────────────────────────────────────────────────────────────────────────────────────────
Paul                  Oscar (batch-credit)      http://kong-core:8000/api/v2/...       Kong Core ⚠️
Paul                  Oscar (corporate-debit)   http://kong-core:8000/api/v2/...       Kong Core ⚠️
Johan (clearing)      Bryan (entries)           http://kong-core:8000/api/v2/...       Kong Core ⚠️
─────────────────────────────────────────────────────────────────────────────────────────────
Ventanilla            Oscar                     http://localhost:8000/api/v2/...       Kong Core (browser)
Banca Web Personas    Oscar, Santiago           http://localhost:8000/api/v2/...       Kong Core (browser)
Banca Web Empresas    Alan, Paul, Anthony       http://localhost:8010/api/v2/...       Kong Switch (browser)
─────────────────────────────────────────────────────────────────────────────────────────────

⚠️ = CRUZA DE SWITCH A CORE — siempre pasa por Kong Core, nunca directo
```

---

## Preguntas Frecuentes

**¿Puedo usar RestTemplate o WebClient para llamar a otros micros?**
Sí, ambos funcionan. Spring WebClient es recomendado para llamadas con timeout configurado.

**¿Cómo configuro el timeout para la llamada síncrona de Oscar a Bryan?**
Configura un timeout de ~5 segundos. Si se vence, ejecuta el reverso compensatorio.

**¿Cómo sé qué puerto usar dentro de Docker?**
Siempre el puerto interno del contenedor, NO el puerto del host. Ejemplo: `accounting-service:8082`, no `localhost:8082`.

**¿Qué pasa si agrego un endpoint nuevo?**
Habla con Anahy primero. Ella lo agrega al `kong/core/kong.yml` o `kong/switch/kong.yml` y hace push a `banquito-infra`.

**¿Cómo conecto mi app Spring Boot al Swagger/OpenAPI?**
Agrega `springdoc-openapi-starter-webmvc-ui` y accede a `http://localhost:TUERTO/swagger-ui/index.html`.

---

*Banco BanQuito V2 · Grupo 1 · Mayo 2026*
*Mantenido por: Anahy (DevOps) — cualquier corrección enviar PR a banquito-infra*
