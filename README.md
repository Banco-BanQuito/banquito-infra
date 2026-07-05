# banquito-infra

Repositorio de infraestructura local del proyecto BanQuito V2.
Levanta todo el ecosistema con un solo comando usando Docker Compose.

---

## Requisitos

- Docker Desktop instalado y corriendo
- Git (para clonar los repos de cada compañero si se necesita)

---

## Cómo levantar todo

```bash
# Clonar este repo
git clone https://github.com/Banco-BanQuito/banquito-infra.git
cd banquito-infra

# Levantar solo la infraestructura (BD, Kafka, Kong) — para desarrollo inicial
docker-compose up -d \
  postgres-core postgres-accounting postgres-party \
  postgres-file postgres-tariff \
  mongo-routing mongo-file mongo-clearing \
  rabbitmq kong-core kong-switch

# Levantar TODO (incluye microservicios y frontends)
docker-compose up -d

# Ver logs en tiempo real
docker-compose logs -f

# Ver estado de todos los contenedores
docker-compose ps

# Apagar todo (preserva los datos en volumes)
docker-compose down

# Apagar y borrar todos los datos
docker-compose down -v
```

---

## Cómo cada compañero conecta su imagen

Cada microservicio tiene una variable de entorno que apunta a su imagen en GHCR.
Para usar tu imagen en lugar del placeholder, define la variable antes del comando:

```bash
# Ejemplo: Oscar levanta su account-core-service
ACCOUNT_CORE_IMAGE=ghcr.io/banco-banquito/account-core-service:latest \
docker-compose up -d account-core-service

# Ejemplo: Bryan levanta su accounting-service
ACCOUNTING_IMAGE=ghcr.io/banco-banquito/accounting-service:latest \
docker-compose up -d accounting-service
```

### Variables por servicio

| Variable de entorno       | Servicio                  | Responsable |
|---------------------------|---------------------------|-------------|
| `ACCOUNT_CORE_IMAGE`      | account-core-service      | Oscar       |
| `ACCOUNTING_IMAGE`        | accounting-service        | Bryan       |
| `PARTY_IMAGE`             | party-service             | Santiago    |
| `FILE_RECEPTION_IMAGE`    | file-reception-service    | Alan        |
| `TARIFF_IMAGE`            | tariff-service            | Johan       |
| `CLEARINGHOUSE_IMAGE`     | clearinghouse-service     | Johan       |
| `REPORT_IMAGE`            | report-service            | Anthony     |
| `NOTIFICATION_IMAGE`      | notification-service      | Anthony     |
| `TELLER_FRONTEND_IMAGE`   | teller-frontend           | Santiago    |
| `WEB_PERSONAS_IMAGE`      | web-personas-frontend     | Santiago    |
| `WEB_EMPRESAS_IMAGE`      | web-empresas-frontend     | Anthony     |

También puedes crear un archivo `.env` en la raíz del repo (no lo subas a Git):

```env
ACCOUNT_CORE_IMAGE=ghcr.io/banco-banquito/account-core-service:latest
SMTP_PASS=tu-app-password-de-gmail
```

---

## URLs de cada servicio (cuando están corriendo)

### API Gateway
| Gateway         | Proxy (llamadas API)      | Admin UI           |
|-----------------|---------------------------|--------------------|
| Kong Core       | http://localhost:8000     | http://localhost:8001 |
| Kong Switch     | http://localhost:8010     | http://localhost:8011 |

### Rutas del Core (via Kong Core — http://localhost:8000)
```
GET  /api/v2/accounts/{id}/balance
GET  /api/v2/accounts/{id}/transactions
POST /api/v2/accounts/teller/deposit
POST /api/v2/accounts/teller/withdrawal
POST /api/v2/accounts/transfer/p2p
POST /api/v2/payments/batch-credit
POST /api/v2/payments/corporate-debit
POST /api/v2/accounting/entries
POST /api/v2/accounting/eod
GET  /api/v2/accounting/trial-balance
GET  /api/v2/customers/{id}
GET  /api/v2/customers/by-account/{accountNumber}
```

### Rutas del Switch (via Kong Switch — http://localhost:8010)
```
POST /api/v2/payments/batches
GET  /api/v2/payments/batches/{id}/status
GET  /api/v2/payments/batches/{id}/report
GET  /api/v2/payments/receipts/{id}
```

### Frontends
| Frontend                | URL                    |
|-------------------------|------------------------|
| Ventanilla (Teller)     | http://localhost:3001  |
| Banca Web Personas      | http://localhost:3002  |
| Banca Web Empresas      | http://localhost:3003  |

### Bases de datos (para conectar con un cliente como DBeaver o Compass)
| Servicio          | Host         | Puerto | DB           | User     | Pass        |
|-------------------|--------------|--------|--------------|----------|-------------|
| postgres-core     | localhost    | 5433   | accountdb    | banquito | banquito123 |
| postgres-accounting | localhost  | 5434   | accountingdb | banquito | banquito123 |
| postgres-party    | localhost    | 5435   | partydb      | banquito | banquito123 |
| postgres-file     | localhost    | 5436   | filedb       | banquito | banquito123 |
| postgres-tariff   | localhost    | 5437   | tariffdb     | banquito | banquito123 |
| mongo-routing     | localhost    | 27018  | routingdb    | —        | —           |
| mongo-file        | localhost    | 27019  | filedb       | —        | —           |
| mongo-clearing    | localhost    | 27020  | clearingdb   | —        | —           |

### RabbitMQ Management UI
http://localhost:15672 — usuario: `banquito` / contraseña: `banquito123`

---

## Reglas de comunicación entre microservicios

> **Importante:** Estas reglas son las URLs que cada compañero debe configurar
> en su `application.properties`. No es necesario recordarlas de memoria —
> ya están configuradas como variables de entorno en el `docker-compose.yml`.

### Regla 1 — Dentro del Core (comunicación directa)
```
account-core  →  accounting-service:8082
account-core  →  party-service:8083
```

### Regla 2 — Dentro del Switch (comunicación directa o por RabbitMQ)
```
routing  →  tariff-service:8086         (HTTP directo)
routing  →  clearinghouse               (RabbitMQ: clearing.outbound.queue)
routing  →  notification-service:8089   (HTTP directo)
report   →  mongodb mongo-routing       (misma BD que routing, lectura directa)
```

### Regla 3 — Switch → Core (CRUZA sistemas, siempre por Kong Core)
```
routing        →  http://kong-core:8000/api/v2/payments/batch-credit
routing        →  http://kong-core:8000/api/v2/payments/corporate-debit
clearinghouse  →  http://kong-core:8000/api/v2/accounting/entries
```

### Regla 4 — Frontends → Kong (siempre, desde el browser)
```
teller-frontend y web-personas  →  http://localhost:8000  (Kong Core)
web-empresas-frontend           →  http://localhost:8010  (Kong Switch)
```

---

## Estructura del repositorio

```
banquito-infra/
├── docker-compose.yml          ← levanta TODO el ecosistema
├── kong/
│   ├── core/kong.yml           ← rutas del Core (cuentas, contabilidad, clientes)
│   └── switch/kong.yml         ← rutas del Switch (pagos masivos, reportes)
├── templates/
│   ├── Dockerfile-springboot   ← plantilla para microservicios Java (copia a tu repo)
│   └── Dockerfile-nginx        ← plantilla para frontends React (copia a tu repo)
└── .github/workflows/
    └── ci-template.yml         ← plantilla CI/CD (copia a tu repo como ci.yml)
```

---

## Cómo usar las plantillas (para cada compañero)

### Si tu servicio es Spring Boot

```bash
# Desde la raíz de TU repo (ej: banquito-account-core-service)
curl -O https://raw.githubusercontent.com/Banco-BanQuito/banquito-infra/main/templates/Dockerfile-springboot
mv Dockerfile-springboot Dockerfile
# Edita el EXPOSE al puerto de tu servicio
```

### Si tu servicio es un frontend React

```bash
# Desde la raíz de TU repo (ej: banquito-teller-frontend)
curl -O https://raw.githubusercontent.com/Banco-BanQuito/banquito-infra/main/templates/Dockerfile-nginx
mv Dockerfile-nginx Dockerfile
```

### Para el CI/CD

```bash
mkdir -p .github/workflows
curl -o .github/workflows/ci.yml \
  https://raw.githubusercontent.com/Banco-BanQuito/banquito-infra/main/.github/workflows/ci-template.yml
# Edita SERVICE_NAME y SERVICE_TYPE en las primeras líneas del archivo
```
