# Anexo H - Secrets de bases de datos

## Objetivo

Configurar las credenciales reales de PostgreSQL, MySQL y MongoDB Atlas en Kubernetes sin guardar passwords dentro del repositorio.

Este anexo documenta la forma operativa rapida con `Kubernetes Secret`. Para cumplir formalmente el requisito de baul de secretos de nube, la fuente oficial debe ser Google Secret Manager, descrito en `anexo-i-secret-manager-key-vault.md`.

Los datos no sensibles, como hosts, puertos y nombres de base, se mantienen en `ConfigMap`. Los usuarios, passwords y cadenas completas de conexion se aplican como `Secret` dentro del cluster o se sincronizan desde Secret Manager.

## Servicios externos usados

| Servicio | Host | Puerto | Base |
| --- | --- | ---: | --- |
| PostgreSQL | `136.112.87.173` | `5432` | `banquito` |
| MySQL | `136.111.132.119` | `3306` | `partydb`, `filedb`, `tariffdb` |
| MongoDB Atlas | `banquito-cluster.ffdlgoy.mongodb.net` | n/a | `banquito` |

## Importante

No aplicar `k8s/secret.yaml` con placeholders despues de cargar los secretos reales, porque puede sobrescribir los valores correctos.

Archivo que no se debe usar para credenciales reales:

```powershell
kubectl apply -f .\secret.yaml
```

Ese archivo debe quedar solo como plantilla o evidencia de estructura.

## Crear o actualizar Secret en Core

Ejecutar desde PowerShell:

```powershell
$PG_PASS = Read-Host "Password PostgreSQL"
$MYSQL_PASS = Read-Host "Password MySQL"
$MONGO_PASS = Read-Host "Password MongoDB Atlas"

$PG_URL = "jdbc:postgresql://136.112.87.173:5432/banquito"
$PARTY_URL = "jdbc:mysql://136.111.132.119:3306/partydb"
$MONGO_URI = "mongodb+srv://banquito:$MONGO_PASS@banquito-cluster.ffdlgoy.mongodb.net/banquito?retryWrites=true&w=majority"

kubectl create secret generic banquito-secrets `
  --namespace banquito-core `
  --from-literal=DB_URL=$PG_URL `
  --from-literal=DB_USER=postgres `
  --from-literal=DB_PASS=$PG_PASS `
  --from-literal=POSTGRES_URL=$PG_URL `
  --from-literal=POSTGRES_USER=postgres `
  --from-literal=POSTGRES_PASSWORD=$PG_PASS `
  --from-literal=MYSQL_PARTY_URL=$PARTY_URL `
  --from-literal=MYSQL_USER=root `
  --from-literal=MYSQL_PASSWORD=$MYSQL_PASS `
  --from-literal=MONGO_URI=$MONGO_URI `
  --from-literal=MONGODB_URI=$MONGO_URI `
  --from-literal=SPRING_DATA_MONGODB_URI=$MONGO_URI `
  --dry-run=client -o yaml | kubectl apply -f -
```

## Crear o actualizar Secret en Switch

Ejecutar desde PowerShell:

```powershell
$PG_PASS = Read-Host "Password PostgreSQL"
$MYSQL_PASS = Read-Host "Password MySQL"
$MONGO_PASS = Read-Host "Password MongoDB Atlas"

$PG_URL = "jdbc:postgresql://136.112.87.173:5432/banquito"
$FILE_URL = "jdbc:mysql://136.111.132.119:3306/filedb"
$TARIFF_URL = "jdbc:mysql://136.111.132.119:3306/tariffdb"
$MONGO_URI = "mongodb+srv://banquito:$MONGO_PASS@banquito-cluster.ffdlgoy.mongodb.net/banquito?retryWrites=true&w=majority"

kubectl create secret generic banquito-secrets `
  --namespace banquito-switch `
  --from-literal=DB_URL=$FILE_URL `
  --from-literal=DB_USER=root `
  --from-literal=DB_PASS=$MYSQL_PASS `
  --from-literal=POSTGRES_URL=$TARIFF_URL `
  --from-literal=POSTGRES_USER=root `
  --from-literal=POSTGRES_PASSWORD=$MYSQL_PASS `
  --from-literal=MYSQL_FILE_URL=$FILE_URL `
  --from-literal=MYSQL_TARIFF_URL=$TARIFF_URL `
  --from-literal=MYSQL_USER=root `
  --from-literal=MYSQL_PASSWORD=$MYSQL_PASS `
  --from-literal=MONGO_URI=$MONGO_URI `
  --from-literal=MONGODB_URI=$MONGO_URI `
  --from-literal=SPRING_DATA_MONGODB_URI=$MONGO_URI `
  --dry-run=client -o yaml | kubectl apply -f -
```

## Crear Secret minimo en Frontend

Los frontends no deberian consumir bases de datos directamente. Se mantiene el Secret solo porque los manifiestos actuales usan `envFrom` de forma comun.

```powershell
kubectl create secret generic banquito-secrets `
  --namespace banquito-frontend `
  --from-literal=PLACEHOLDER=not-used `
  --dry-run=client -o yaml | kubectl apply -f -
```

## Reiniciar Pods para tomar los nuevos Secrets

Los Pods no leen automaticamente los cambios de variables de entorno. Despues de actualizar Secrets, reiniciar los deployments activos:

```powershell
kubectl rollout restart deployment account-core-service -n banquito-core
kubectl rollout restart deployment accounting-service -n banquito-core
kubectl rollout restart deployment party-service -n banquito-core

kubectl rollout restart deployment file-reception-service -n banquito-switch
kubectl rollout restart deployment tariff-service -n banquito-switch
kubectl rollout restart deployment clearinghouse-service -n banquito-switch
kubectl rollout restart deployment report-service -n banquito-switch
kubectl rollout restart deployment notification-service -n banquito-switch
```

Si los deployments estan en `0/0`, primero se puede actualizar el Secret y luego escalar por bloques.

## Encender por bloques para validar

Core:

```powershell
kubectl scale deployment account-core-service --replicas=1 -n banquito-core
kubectl scale deployment accounting-service --replicas=1 -n banquito-core
kubectl scale deployment party-service --replicas=1 -n banquito-core
kubectl get pods -n banquito-core
```

Switch:

```powershell
kubectl scale deployment file-reception-service --replicas=1 -n banquito-switch
kubectl scale deployment tariff-service --replicas=1 -n banquito-switch
kubectl scale deployment notification-service --replicas=1 -n banquito-switch
kubectl scale deployment clearinghouse-service --replicas=1 -n banquito-switch
kubectl scale deployment report-service --replicas=1 -n banquito-switch
kubectl get pods -n banquito-switch
```

## Validar errores comunes

Ver logs:

```powershell
kubectl logs -n banquito-core deployment/account-core-service
kubectl logs -n banquito-core deployment/accounting-service
kubectl logs -n banquito-core deployment/party-service

kubectl logs -n banquito-switch deployment/file-reception-service
kubectl logs -n banquito-switch deployment/tariff-service
kubectl logs -n banquito-switch deployment/clearinghouse-service
kubectl logs -n banquito-switch deployment/report-service
kubectl logs -n banquito-switch deployment/notification-service
```

Errores esperados si el Secret esta mal:

| Error | Causa probable |
| --- | --- |
| `Access denied for user` | Usuario/password MySQL incorrecto o IP no autorizada |
| `Unable to determine Dialect` | PostgreSQL no conecta o credenciales incorrectas |
| `The connection string is invalid` | `MONGO_URI` no empieza con `mongodb+srv://` |
| `CrashLoopBackOff` | La aplicacion arranca, falla por dependencia externa y Kubernetes la reinicia |

## Estado aplicado

Se crearon Kubernetes Secrets por microservicio a partir de los valores ya existentes en Google Secret Manager:

```text
account-core-secrets
accounting-secrets
party-secrets
file-reception-secrets
tariff-secrets
mongo-services-secrets
```

Tambien se actualizaron los Deployments backend para usar esos Secrets especificos:

```text
account-core-service      -> account-core-secrets
accounting-service        -> accounting-secrets
party-service             -> party-secrets
file-reception-service    -> file-reception-secrets
tariff-service            -> tariff-secrets
clearinghouse-service     -> mongo-services-secrets
report-service            -> mongo-services-secrets
notification-service      -> mongo-services-secrets
```
