# Anexo J - Informacion para crear secretos en Google Secret Manager

## Objetivo

Entregar al responsable de Google Cloud la lista exacta de secretos que debe crear en Google Secret Manager para que GKE consuma las credenciales de bases de datos y servicios externos.

## Proyecto Google Cloud

| Campo | Valor |
| --- | --- |
| Proyecto GKE | `project-47695a8e-7cb2-4352-af2` |
| Cluster GKE | `banquito-cluster-east` |
| Region GKE | `us-east1` |
| Modo | `Autopilot` |
| Baul de secretos | `Google Secret Manager` |

## Regla importante

Los secretos reales no deben guardarse en Git, ConfigMaps, YAML versionado ni capturas publicas.

Los passwords deben cargarse directamente en Secret Manager.

## Secretos obligatorios

### PostgreSQL

| Secret name | Valor |
| --- | --- |
| `banquito-postgres-url` | `jdbc:postgresql://136.112.87.173:5432/banquito` |
| `banquito-postgres-user` | `postgres` |
| `banquito-postgres-password` | password real de PostgreSQL |

### MySQL

| Secret name | Valor |
| --- | --- |
| `banquito-mysql-party-url` | `jdbc:mysql://136.111.132.119:3306/partydb` |
| `banquito-mysql-file-url` | `jdbc:mysql://136.111.132.119:3306/filedb` |
| `banquito-mysql-tariff-url` | `jdbc:mysql://136.111.132.119:3306/tariffdb` |
| `banquito-mysql-user` | `root` |
| `banquito-mysql-password` | password real de MySQL |

### MongoDB Atlas

| Secret name | Valor |
| --- | --- |
| `banquito-mongo-uri` | `mongodb+srv://banquito:<PASSWORD_MONGO>@banquito-cluster.ffdlgoy.mongodb.net/banquito?retryWrites=true&w=majority` |

Reemplazar `<PASSWORD_MONGO>` por el password real de MongoDB Atlas.

## Secretos opcionales

Crear tambien si esos servicios ya estan definidos:

| Secret name | Valor esperado |
| --- | --- |
| `banquito-rabbit-user` | usuario real RabbitMQ |
| `banquito-rabbit-password` | password real RabbitMQ |
| `banquito-smtp-user` | usuario SMTP |
| `banquito-smtp-password` | password SMTP |
| `banquito-jwt-secret` | secreto JWT si la aplicacion lo requiere |

## Crear secretos desde consola web

Para cada secreto:

```text
Google Cloud Console
  -> Security
  -> Secret Manager
  -> Create secret
```

Configurar:

```text
Name: nombre exacto del secreto
Secret value: valor correspondiente
Replication: Automatic
```

## Crear secretos desde PowerShell

Habilitar API si falta:

```powershell
gcloud services enable secretmanager.googleapis.com --project project-47695a8e-7cb2-4352-af2
```

Crear los secretos:

```powershell
gcloud secrets create banquito-postgres-url --replication-policy=automatic --project project-47695a8e-7cb2-4352-af2
gcloud secrets create banquito-postgres-user --replication-policy=automatic --project project-47695a8e-7cb2-4352-af2
gcloud secrets create banquito-postgres-password --replication-policy=automatic --project project-47695a8e-7cb2-4352-af2

gcloud secrets create banquito-mysql-party-url --replication-policy=automatic --project project-47695a8e-7cb2-4352-af2
gcloud secrets create banquito-mysql-file-url --replication-policy=automatic --project project-47695a8e-7cb2-4352-af2
gcloud secrets create banquito-mysql-tariff-url --replication-policy=automatic --project project-47695a8e-7cb2-4352-af2
gcloud secrets create banquito-mysql-user --replication-policy=automatic --project project-47695a8e-7cb2-4352-af2
gcloud secrets create banquito-mysql-password --replication-policy=automatic --project project-47695a8e-7cb2-4352-af2

gcloud secrets create banquito-mongo-uri --replication-policy=automatic --project project-47695a8e-7cb2-4352-af2
```

Agregar versiones sin escribir passwords en texto plano:

```powershell
$PG_PASS = Read-Host "Password PostgreSQL"
$MYSQL_PASS = Read-Host "Password MySQL"
$MONGO_PASS = Read-Host "Password MongoDB Atlas"

"jdbc:postgresql://136.112.87.173:5432/banquito" | gcloud secrets versions add banquito-postgres-url --data-file=- --project project-47695a8e-7cb2-4352-af2
"postgres" | gcloud secrets versions add banquito-postgres-user --data-file=- --project project-47695a8e-7cb2-4352-af2
$PG_PASS | gcloud secrets versions add banquito-postgres-password --data-file=- --project project-47695a8e-7cb2-4352-af2

"jdbc:mysql://136.111.132.119:3306/partydb" | gcloud secrets versions add banquito-mysql-party-url --data-file=- --project project-47695a8e-7cb2-4352-af2
"jdbc:mysql://136.111.132.119:3306/filedb" | gcloud secrets versions add banquito-mysql-file-url --data-file=- --project project-47695a8e-7cb2-4352-af2
"jdbc:mysql://136.111.132.119:3306/tariffdb" | gcloud secrets versions add banquito-mysql-tariff-url --data-file=- --project project-47695a8e-7cb2-4352-af2
"root" | gcloud secrets versions add banquito-mysql-user --data-file=- --project project-47695a8e-7cb2-4352-af2
$MYSQL_PASS | gcloud secrets versions add banquito-mysql-password --data-file=- --project project-47695a8e-7cb2-4352-af2

"mongodb+srv://banquito:$MONGO_PASS@banquito-cluster.ffdlgoy.mongodb.net/banquito?retryWrites=true&w=majority" | gcloud secrets versions add banquito-mongo-uri --data-file=- --project project-47695a8e-7cb2-4352-af2
```

## Verificacion

Listar secretos:

```powershell
gcloud secrets list --project project-47695a8e-7cb2-4352-af2
```

Validar que cada secreto tenga al menos una version:

```powershell
gcloud secrets versions list banquito-postgres-password --project project-47695a8e-7cb2-4352-af2
gcloud secrets versions list banquito-mysql-password --project project-47695a8e-7cb2-4352-af2
gcloud secrets versions list banquito-mongo-uri --project project-47695a8e-7cb2-4352-af2
```

## Texto para documentacion

Las credenciales de PostgreSQL, MySQL y MongoDB Atlas se almacenan en Google Secret Manager. Los manifiestos de Kubernetes no contienen passwords reales. Los Pods consumen las credenciales mediante integracion con GKE y Secret Manager o mediante sincronizacion controlada hacia Kubernetes Secrets.

