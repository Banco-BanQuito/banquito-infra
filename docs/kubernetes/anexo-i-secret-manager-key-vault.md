# Anexo I - Key Vault con Google Secret Manager

## Requisito

Las conexiones a bases de datos y toda variable sensible de entorno deben almacenarse en un baul de secretos provisto por la nube.

En Google Cloud, el servicio equivalente a Key Vault es:

```text
Google Secret Manager
```

## Decision de arquitectura

No se deben guardar passwords reales en:

```text
application.yml
application.properties
Dockerfile
ConfigMap
secret.yaml versionado en Git
GitHub Actions YAML
```

El flujo correcto es:

```text
Google Secret Manager
  -> GKE Secret Manager add-on / CSI Driver
      -> Pod
          -> variable o archivo montado
```

Para este proyecto se acepta usar `Kubernetes Secret` solo como mecanismo de consumo dentro del cluster, pero la fuente oficial debe ser Secret Manager.

## Secretos que deben ir en Secret Manager

| Secreto | Uso |
| --- | --- |
| `banquito-postgres-url` | URL JDBC PostgreSQL |
| `banquito-postgres-user` | Usuario PostgreSQL |
| `banquito-postgres-password` | Password PostgreSQL |
| `banquito-mysql-party-url` | URL JDBC MySQL partydb |
| `banquito-mysql-file-url` | URL JDBC MySQL filedb |
| `banquito-mysql-tariff-url` | URL JDBC MySQL tariffdb |
| `banquito-mysql-user` | Usuario MySQL |
| `banquito-mysql-password` | Password MySQL |
| `banquito-mongo-uri` | URI completa MongoDB Atlas |
| `banquito-rabbit-user` | Usuario RabbitMQ |
| `banquito-rabbit-password` | Password RabbitMQ |
| `banquito-jwt-secret` | Secreto JWT si aplica |
| `banquito-smtp-user` | Usuario SMTP |
| `banquito-smtp-password` | Password SMTP |

## Habilitar Secret Manager y el add-on de GKE

PowerShell:

```powershell
gcloud services enable secretmanager.googleapis.com

gcloud container clusters update banquito-cluster-east `
  --region us-east1 `
  --enable-secret-manager `
  --project project-47695a8e-7cb2-4352-af2
```

Verificar:

```powershell
gcloud container clusters describe banquito-cluster-east `
  --region us-east1 `
  --project project-47695a8e-7cb2-4352-af2 `
  --format="yaml(secretManagerConfig)"
```

## Crear secretos en Secret Manager

No escribir passwords directamente en el comando. Usar `Read-Host`.

```powershell
$PG_PASS = Read-Host "Password PostgreSQL"
$MYSQL_PASS = Read-Host "Password MySQL"
$MONGO_PASS = Read-Host "Password MongoDB Atlas"

$PG_URL = "jdbc:postgresql://136.112.87.173:5432/banquito"
$PARTY_URL = "jdbc:mysql://136.111.132.119:3306/partydb"
$FILE_URL = "jdbc:mysql://136.111.132.119:3306/filedb"
$TARIFF_URL = "jdbc:mysql://136.111.132.119:3306/tariffdb"
$MONGO_URI = "mongodb+srv://banquito:$MONGO_PASS@banquito-cluster.ffdlgoy.mongodb.net/banquito?retryWrites=true&w=majority"
```

Crear cada secreto si no existe:

```powershell
gcloud secrets create banquito-postgres-url --replication-policy=automatic
gcloud secrets create banquito-postgres-user --replication-policy=automatic
gcloud secrets create banquito-postgres-password --replication-policy=automatic
gcloud secrets create banquito-mysql-party-url --replication-policy=automatic
gcloud secrets create banquito-mysql-file-url --replication-policy=automatic
gcloud secrets create banquito-mysql-tariff-url --replication-policy=automatic
gcloud secrets create banquito-mysql-user --replication-policy=automatic
gcloud secrets create banquito-mysql-password --replication-policy=automatic
gcloud secrets create banquito-mongo-uri --replication-policy=automatic
```

Agregar versiones:

```powershell
$PG_URL | gcloud secrets versions add banquito-postgres-url --data-file=-
"postgres" | gcloud secrets versions add banquito-postgres-user --data-file=-
$PG_PASS | gcloud secrets versions add banquito-postgres-password --data-file=-

$PARTY_URL | gcloud secrets versions add banquito-mysql-party-url --data-file=-
$FILE_URL | gcloud secrets versions add banquito-mysql-file-url --data-file=-
$TARIFF_URL | gcloud secrets versions add banquito-mysql-tariff-url --data-file=-
"root" | gcloud secrets versions add banquito-mysql-user --data-file=-
$MYSQL_PASS | gcloud secrets versions add banquito-mysql-password --data-file=-

$MONGO_URI | gcloud secrets versions add banquito-mongo-uri --data-file=-
```

## Acceso desde GKE

El acceso se debe dar por namespace y ServiceAccount, no con JSON keys.

Ejemplo para `banquito-core`:

```powershell
kubectl create serviceaccount banquito-runtime -n banquito-core

gcloud secrets add-iam-policy-binding banquito-postgres-password `
  --role=roles/secretmanager.secretAccessor `
  --member="principal://iam.googleapis.com/projects/69503932816/locations/global/workloadIdentityPools/project-47695a8e-7cb2-4352-af2.svc.id.goog/subject/ns/banquito-core/sa/banquito-runtime"
```

Se debe repetir el binding para cada secreto que necesite cada namespace.

## Opcion recomendada para las aplicaciones actuales

Como los microservicios ya leen variables de entorno como `DB_URL`, `DB_USER`, `DB_PASS`, `MONGO_URI`, etc., hay dos caminos:

| Opcion | Descripcion | Recomendacion |
| --- | --- | --- |
| Montar secretos como archivos con Secret Manager add-on | Mas seguro, requiere adaptar entrypoint o app para leer archivos | Mejor para produccion |
| Sincronizar Secret Manager hacia Kubernetes Secret | Mantiene compatibilidad con variables de entorno existentes | Mejor para este proyecto universitario |

Para el proyecto BanQuito, la opcion practica es:

```text
Secret Manager como baul oficial
  -> sincronizacion hacia Kubernetes Secret
      -> envFrom en Deployment
```

Asi se cumple el requisito del baul de secretos de nube sin reescribir toda la aplicacion.

## Evidencia para el documento final

Debe quedar evidenciado:

```text
1. Los passwords no estan en Git.
2. Los secretos existen en Google Secret Manager.
3. GKE accede a Secret Manager con Workload Identity.
4. Los Pods consumen los valores como variables de entorno.
5. Kubernetes Secret no es la fuente maestra, solo el mecanismo de inyeccion.
```

Comandos de evidencia:

```powershell
gcloud secrets list

gcloud secrets versions list banquito-postgres-password
gcloud secrets versions list banquito-mysql-password
gcloud secrets versions list banquito-mongo-uri

kubectl get serviceaccount -A
kubectl get secret -n banquito-core
kubectl get secret -n banquito-switch
```

## Estado aplicado

Fecha de aplicacion: `2026-07-17`.

Se verifico que los secretos existen en Google Secret Manager y tienen version activa:

```text
banquito-postgres-url
banquito-postgres-user
banquito-postgres-password
banquito-mysql-party-url
banquito-mysql-file-url
banquito-mysql-tariff-url
banquito-mysql-user
banquito-mysql-password
banquito-mongo-uri
```

Se sincronizaron hacia Kubernetes Secrets separados por microservicio:

| Namespace | Kubernetes Secret | Uso |
| --- | --- | --- |
| `banquito-core` | `account-core-secrets` | PostgreSQL Core |
| `banquito-core` | `accounting-secrets` | PostgreSQL Accounting |
| `banquito-core` | `party-secrets` | MySQL Party |
| `banquito-switch` | `file-reception-secrets` | MySQL File + MongoDB |
| `banquito-switch` | `tariff-secrets` | MySQL Tariff |
| `banquito-switch` | `mongo-services-secrets` | MongoDB para Clearinghouse, Report y Notification |

Los Deployments fueron actualizados para dejar de depender del `banquito-secrets` generico en backends y usar el Secret especifico correspondiente.

Despues de la prueba, los Deployments quedaron nuevamente en `0/0` para evitar consumo innecesario:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-switch
```

## Referencia oficial

Google Cloud documenta la integracion de Secret Manager con GKE mediante el Secret Manager add-on, compatible con Autopilot y Standard.

Fuente:

```text
https://docs.cloud.google.com/secret-manager/docs/secret-manager-managed-csi-component
```
