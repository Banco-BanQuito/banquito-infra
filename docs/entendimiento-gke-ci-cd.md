# Entendimiento de arquitectura para GKE y CI/CD

## Contexto

El proyecto BanQuito esta compuesto por dos aplicaciones principales:

1. Core Bancario.
2. Switch de Pagos Masivos.

El requisito objetivo es desplegar ambas aplicaciones en un orquestador de contenedores provisto por nube y crear pipelines para despliegue automatizado. La nube seleccionada para este entendimiento es Google Cloud Platform usando Google Kubernetes Engine.

Los servicios de plataforma no se deben operar como contenedores propios dentro del cluster. RabbitMQ, API Manager, OAuth y bases de datos se consumen como servicios administrados de nube.

## Repositorios revisados

### Core Bancario

| Repositorio | Tipo | Puerto HTTP | Puerto gRPC | Persistencia |
| --- | --- | ---: | ---: | --- |
| banquito-account-core-service | Spring Boot / Maven | 8081 | 9091 | PostgreSQL, schema `account_core` |
| banquito-accounting-service | Spring Boot / Maven | 8082 | 9092 | PostgreSQL, schema `accounting` |
| banquito-party-service | Spring Boot / Maven | 8083 | 9093 | MySQL, database `partydb` |

### Switch de Pagos Masivos

| Repositorio | Tipo | Puerto HTTP | Puerto gRPC | Persistencia / mensajeria |
| --- | --- | ---: | ---: | --- |
| banquito-file-reception-service | Spring Boot / Maven | 8084 | cliente gRPC | MySQL `filedb`, MongoDB, RabbitMQ |
| banquito-tariff-service | Spring Boot / Maven anidado | 8086 | 9090 | MySQL `tariffdb` |
| banquito-clearinghouse-service | Spring Boot / Maven anidado | 8087 | n/a | MongoDB, RabbitMQ |
| banquito-report-service | Spring Boot / Maven | 8088 | n/a | MongoDB |
| banquito-notification-service | Spring Boot / Maven | 8089 | 9092 | MongoDB, SMTP |

### Frontends

| Repositorio | Tipo | Puerto contenedor | Uso |
| --- | --- | ---: | --- |
| banquito-teller-frontend | Vite / Nginx | 8080 | Ventanilla |
| banquito-web-personas-frontend | Vite / Nginx | 8080 | Banca Personas |
| banquito-web-empresas-frontend | Vite / Nginx | 8080 | Banca Empresas |
| banquito-frontend-web-operador | Vite / Nginx | 8080 | Operador |

## Estado actual encontrado

Los repositorios ya tienen Dockerfiles y workflows de GitHub para publicar imagenes en GHCR. Las imagenes actuales apuntan a nombres como:

- `ghcr.io/banco-banquito/account-core-service:latest`
- `ghcr.io/banco-banquito/accounting-service:latest`
- `ghcr.io/banco-banquito/party-service:latest`
- `ghcr.io/banco-banquito/file-reception-service:latest`
- `ghcr.io/banco-banquito/tariff-service:latest`
- `ghcr.io/banco-banquito/clearinghouse-service:latest`
- `ghcr.io/banco-banquito/report-service:latest`
- `ghcr.io/banco-banquito/notification-service:latest`
- `ghcr.io/banco-banquito/teller-frontend:latest`
- `ghcr.io/banco-banquito/web-personas-frontend:latest`
- `ghcr.io/banco-banquito/web-empresas-frontend:latest`
- `ghcr.io/banco-banquito/operador-frontend:latest`

El repositorio `banquito-infra` actualmente esta orientado a ejecucion con Docker Compose en una VM. Su pipeline `.github/workflows/deploy.yml` hace despliegue por SSH, actualiza `.env`, aplica scripts SQL y ejecuta `docker compose up -d`.

Ese flujo no cumple todavia el requisito de orquestador de contenedores, porque el destino no es Kubernetes/GKE sino una VM con Docker Compose.

## Servicios de nube esperados

| Necesidad | Servicio actual/local | Servicio administrado recomendado en Google Cloud |
| --- | --- | --- |
| Orquestador | Docker Compose en VM | Google Kubernetes Engine |
| Registro de imagenes | GHCR | Artifact Registry o GHCR integrado con GKE |
| API Manager | Kong en contenedor | Apigee o API Gateway |
| OAuth / identidad | JWT/Kong local o configuracion propia | Identity Platform, proveedor OAuth externo o integracion con Apigee |
| RabbitMQ | RabbitMQ en Compose | RabbitMQ administrado externo o Pub/Sub si se adapta la app |
| PostgreSQL | Postgres en Compose / Cloud SQL host | Cloud SQL PostgreSQL |
| MySQL | MySQL externo por variables | Cloud SQL MySQL |
| MongoDB | Mongo local / Mongo Atlas URL | MongoDB Atlas o servicio Mongo administrado |
| Secrets | `.env` generado en VM | Secret Manager + Kubernetes Secrets |
| Logs y metricas | Loki/Grafana en Compose | Cloud Logging + Cloud Monitoring |

## Comunicacion entre servicios

### Core Bancario

- `account-core-service` llama a `accounting-service` por gRPC en `9092`.
- `account-core-service` llama a `party-service` por gRPC en `9093`.
- `party-service` puede llamar a `account-core-service` por gRPC en `9091`.
- `account-core-service` publica eventos hacia RabbitMQ para clearing.

### Switch de Pagos Masivos

- `file-reception-service` usa MySQL para lotes, MongoDB para datos de procesamiento y RabbitMQ para colas.
- `file-reception-service` llama a `tariff-service` por gRPC en `9090`.
- `file-reception-service` llama a `notification-service` por gRPC en `9092`.
- `clearinghouse-service` consume de RabbitMQ y ejecuta compensacion contra Core.
- `report-service` lee MongoDB y puede usar notificaciones.
- `notification-service` usa MongoDB y SMTP.

### Cruce Switch -> Core

En el Compose actual algunas URLs apuntan directo a servicios internos, por ejemplo `http://account-core-service:8081`. Para nube, la decision recomendada es:

- trafico externo y entre dominios expuesto: pasar por API Manager.
- trafico interno tecnico de baja exposicion: puede ir por `Service` interno de Kubernetes.

Como el requisito menciona API Manager como servicio de nube, las rutas publicas y de integracion entre sistemas deberian formalizarse en Apigee/API Gateway.

## Modelo propuesto en GKE

En GKE se despliegan solamente las aplicaciones propias:

- Deployments para cada backend.
- Services internos tipo `ClusterIP` para backends.
- Services para frontends.
- Ingress o Gateway para entrada HTTP.
- ConfigMaps para configuracion no sensible.
- Secrets referenciando Secret Manager para credenciales.
- HorizontalPodAutoscaler opcional para servicios con carga variable.

No se despliegan en GKE:

- RabbitMQ.
- API Manager.
- OAuth.
- PostgreSQL/MySQL/MongoDB.

## Pipelines requeridos

Cada repositorio de aplicacion debe tener un pipeline con estas etapas:

1. Checkout.
2. Tests/build.
3. Construccion de imagen Docker.
4. Publicacion en Artifact Registry o GHCR.
5. Despliegue a GKE con `kubectl`, Kustomize o Helm.

El repositorio `banquito-infra` debe contener los manifiestos Kubernetes o charts Helm y un pipeline de despliegue de infraestructura aplicativa.

Recomendacion de etiquetado:

- Usar `latest` solo para desarrollo.
- Usar `${{ github.sha }}` o version semantica para despliegues trazables.

## Brechas tecnicas detectadas

1. No existen manifiestos Kubernetes en `banquito-infra`.
2. El pipeline actual despliega a VM por SSH, no a GKE.
3. Se usan imagenes en GHCR, pero para Google Cloud conviene decidir entre mantener GHCR o migrar a Artifact Registry.
4. Algunos Dockerfiles construyen el JAR dentro de Docker; otros esperan `target/*.jar` previamente generado.
5. `banquito-clearinghouse-service` y `banquito-tariff-service` tienen estructura Maven anidada.
6. Hay configuracion local con `localhost` que debe convertirse a nombres DNS internos de Kubernetes o endpoints administrados.
7. RabbitMQ, API Manager, OAuth y bases deben mapearse formalmente a servicios cloud y variables de entorno.
8. Los frontends tienen variables `VITE_*` resueltas en build time; para cambiar endpoints por ambiente se debe reconstruir la imagen o usar configuracion runtime con Nginx.

## Siguiente paso recomendado

Crear en `banquito-infra` una nueva carpeta:

```text
k8s/
  base/
    core/
    switch/
    frontends/
  overlays/
    dev/
    prod/
```

Despues generar manifiestos para:

- namespace `banquito`.
- configmaps por dominio.
- secrets referenciables desde Secret Manager.
- deployments y services por microservicio.
- ingress/gateway para frontends y APIs.
- pipeline GitHub Actions para autenticar contra Google Cloud, publicar imagen y aplicar manifiestos en GKE.
