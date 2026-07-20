# Fase 4 - Revision de microservicios para Kubernetes

## Objetivo

Revisar los proyectos antes de desplegar. En esta fase no se crean recursos en GKE ni se ejecuta despliegue.

Se verificaron:

- `Dockerfile`
- `pom.xml`
- `application.yml`
- `application.properties`
- `server.port`
- puertos gRPC
- variables de entorno
- base de datos
- RabbitMQ
- URLs entre servicios

## Resultado general

Los microservicios ya tienen Dockerfile y configuracion Maven. La mayoria ya usaba variables de entorno, pero varios valores tenian fallback local como `localhost`, `127.0.0.1`, `root`, `guest` o `banquito123`.

Para Kubernetes esos defaults no son recomendables porque pueden ocultar errores de configuracion. Se actualizaron los archivos principales de runtime para que las dependencias externas sean obligatorias por variable de entorno.

No se modificaron archivos de `src/test`, porque los tests pueden seguir usando H2 o configuracion local.

## Cambios aplicados

### banquito-account-core-service

Archivo:

- `src/main/resources/application.properties`

Cambios:

- `spring.datasource.url` ahora usa `${DB_URL}`.
- `spring.datasource.username` ahora usa `${DB_USER}`.
- `spring.datasource.password` ahora usa `${DB_PASS}`.
- Hosts gRPC de accounting, party y notification ahora vienen de variables obligatorias.
- RabbitMQ host, user, password y vhost ahora vienen de variables obligatorias.

Variables clave:

- `DB_URL`
- `DB_USER`
- `DB_PASS`
- `ACCOUNTING_GRPC_HOST`
- `ACCOUNTING_GRPC_PORT`
- `PARTY_GRPC_HOST`
- `PARTY_GRPC_PORT`
- `NOTIFICATION_GRPC_HOST`
- `NOTIFICATION_GRPC_PORT`
- `RABBITMQ_HOST`
- `RABBITMQ_PORT`
- `RABBITMQ_USERNAME`
- `RABBITMQ_PASSWORD`
- `RABBITMQ_VHOST`

### banquito-accounting-service

Archivo:

- `src/main/resources/application.properties`

Cambios:

- Base de datos PostgreSQL ahora depende de `DB_URL`, `DB_USER` y `DB_PASS`.

Variables clave:

- `DB_URL`
- `DB_USER`
- `DB_PASS`
- `DB_SCHEMA`
- `ACCOUNTING_GRPC_PORT`

### banquito-party-service

Archivo:

- `src/main/resources/application.properties`

Cambios:

- MySQL ya no tiene fallback a `127.0.0.1`, `root` o password local.
- Host gRPC de account-core ahora depende de `ACCOUNT_CORE_GRPC_HOST`.

Variables clave:

- `DB_URL`
- `DB_USER`
- `DB_PASS`
- `PARTY_GRPC_PORT`
- `ACCOUNT_CORE_GRPC_HOST`
- `ACCOUNT_CORE_GRPC_PORT`

### banquito-file-reception-service

Archivo:

- `src/main/resources/application.properties`

Cambios:

- Hosts gRPC de tariff y notification ahora son variables obligatorias.
- URL base hacia Core/API Manager ahora depende de `CORE_GATEWAY_URL`.
- MySQL ahora depende de `DB_URL`, `DB_USER` y `DB_PASS`.
- MongoDB ahora depende de `MONGO_URI`.
- RabbitMQ host, user, password y vhost ahora dependen de variables obligatorias.

Variables clave:

- `DB_URL`
- `DB_USER`
- `DB_PASS`
- `MONGO_URI`
- `RABBITMQ_HOST`
- `RABBITMQ_PORT`
- `RABBITMQ_USERNAME`
- `RABBITMQ_PASSWORD`
- `RABBITMQ_VHOST`
- `CORE_GATEWAY_URL`
- `TARIFF_SERVICE_GRPC_HOST`
- `TARIFF_SERVICE_GRPC_PORT`
- `NOTIFICATION_SERVICE_GRPC_HOST`
- `NOTIFICATION_SERVICE_GRPC_PORT`

### banquito-tariff-service

Archivo:

- `banquito-tariff-service/src/main/resources/application.properties`

Cambios:

- `server.port` ahora usa `${SERVER_PORT:8086}`.
- Base de datos ahora depende de `POSTGRES_URL`, `POSTGRES_USER` y `POSTGRES_PASSWORD`.

Nota:

Aunque las variables se llaman `POSTGRES_*`, el driver configurado es MySQL. En Kubernetes se puede mantener por compatibilidad, pero conviene renombrarlas a `DB_URL`, `DB_USER` y `DB_PASS` en una refactorizacion posterior.

Variables clave:

- `SERVER_PORT`
- `GRPC_SERVER_PORT`
- `POSTGRES_URL`
- `POSTGRES_USER`
- `POSTGRES_PASSWORD`

### banquito-clearinghouse-service

Archivo:

- `banquito-clearinghouse-service/src/main/resources/application.properties`

Cambios:

- MongoDB ahora depende de `SPRING_DATA_MONGODB_URI`.
- Configuracion de Mongo host/database queda por variable.
- RabbitMQ host, user, password y vhost ahora dependen de variables obligatorias.
- URL de Core/API Manager ahora depende de `CORE_GATEWAY_URL`.

Variables clave:

- `SPRING_DATA_MONGODB_URI`
- `MONGODB_HOST`
- `MONGODB_PORT`
- `MONGODB_DATABASE`
- `SPRING_RABBITMQ_HOST`
- `SPRING_RABBITMQ_PORT`
- `SPRING_RABBITMQ_USERNAME`
- `SPRING_RABBITMQ_PASSWORD`
- `SPRING_RABBITMQ_VIRTUAL_HOST`
- `CORE_GATEWAY_URL`

### banquito-report-service

Archivo:

- `src/main/resources/application.yml`

Cambios:

- MongoDB ahora depende de `MONGODB_URI`.
- CORS ahora depende de `CORS_ALLOWED_ORIGINS`.
- Host gRPC de notification ahora depende de `NOTIFICATION_GRPC_HOST`.

Variables clave:

- `MONGODB_URI`
- `CORS_ALLOWED_ORIGINS`
- `NOTIFICATION_GRPC_HOST`
- `NOTIFICATION_GRPC_PORT`

### banquito-notification-service

Archivo:

- `src/main/resources/application.yml`

Cambios:

- MongoDB ahora depende de `MONGODB_URI`.
- SMTP host y port ahora dependen de `SMTP_HOST` y `SMTP_PORT`.
- CORS ahora depende de `CORS_ALLOWED_ORIGINS`.

Variables clave:

- `MONGODB_URI`
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASS`
- `CORS_ALLOWED_ORIGINS`
- `GRPC_PORT`

## Pendientes detectados

1. Crear los `ConfigMap` y `Secret` de Kubernetes con todas estas variables.
2. Decidir valores por ambiente: `dev`, `demo`, `prod`.
3. Definir endpoints administrados para Cloud SQL PostgreSQL, Cloud SQL MySQL, MongoDB Atlas, RabbitMQ administrado, API Manager y OAuth.
4. Revisar si las variables `POSTGRES_*` de `tariff-service` deben renombrarse para no confundir con MySQL.
5. Revisar los Dockerfiles que dependen de `target/*.jar`, porque sus pipelines deben compilar antes de construir la imagen.

## Validacion

Despues de los cambios, se busco en archivos principales de runtime:

- `localhost`
- `127.0.0.1`
- `guest`
- `root`
- `banquito123`
- `jdbc:`
- `mongodb://`
- `amqp://`
- URLs HTTP fijas

Excluyendo `src/test`, `target` y plantillas antiguas, no quedaron valores locales relevantes en los archivos `application.*` principales.

## Comandos utilizados

### Inventariar archivos revisados

Se uso este comando para localizar `Dockerfile`, `pom.xml`, `application.yml`, `application.yaml` y `application.properties` en todos los repositorios:

```powershell
Get-ChildItem -Directory | ForEach-Object {
  $repo=$_.Name
  Get-ChildItem -Path $_.FullName -Recurse -File -Include Dockerfile,pom.xml,application.yml,application.yaml,application.properties |
    ForEach-Object {
      [PSCustomObject]@{
        Repo=$repo
        Path=$_.FullName.Substring((Get-Location).Path.Length + 1)
      }
    }
} | Format-Table -AutoSize
```

### Buscar configuracion local o sensible

Se uso `rg` para buscar valores que no deben quedar fijos para Kubernetes:

```powershell
rg -n "localhost|127\.0\.0\.1|guest|root|banquito123|jdbc:|mongodb://|amqp://|http://|https://|server\.port|grpc.*port|rabbit|datasource|MONGODB|DB_URL" -S -g "application*.yml" -g "application*.yaml" -g "application*.properties" .
```

### Validar despues de modificar

Despues de actualizar los `application.*`, se ejecuto una busqueda excluyendo pruebas, artefactos compilados y plantillas antiguas:

```powershell
rg -n "localhost|127\.0\.0\.1|guest|root|banquito123|jdbc:|mongodb://|amqp://|http://|https://" -S -g "application*.yml" -g "application*.yaml" -g "application*.properties" -g "!**/src/test/**" -g "!**/target/**" -g "!banquito-infra/templates/**" .
```

Resultado:

```text
Solo quedo una coincidencia no relevante: logging.level.root=INFO.
```

### Revisar cambios por repositorio

Se uso este comando para ver que repositorios quedaron modificados:

```powershell
foreach ($repo in @(
  'banquito-account-core-service',
  'banquito-accounting-service',
  'banquito-party-service',
  'banquito-file-reception-service',
  'banquito-tariff-service',
  'banquito-clearinghouse-service',
  'banquito-report-service',
  'banquito-notification-service',
  'banquito-infra'
)) {
  Write-Output "### $repo"
  git -C $repo status --short
}
```
