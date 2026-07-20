# Comandos correctos para actualizar micros

## 1. Artifact Registry

```powershell
gcloud artifacts repositories create banquito --repository-format=docker --location=us-central1 --description="Imagenes Docker BanQuito"
```

```powershell
gcloud auth configure-docker us-central1-docker.pkg.dev
```

## 2. account-core-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-account-core-service
```

```powershell
.\mvnw.cmd -q -DskipTests package
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest
```

## 3. accounting-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-accounting-service
```

```powershell
.\mvnw.cmd -q -DskipTests package
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest
```

## 4. party-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-party-service
```

```powershell
.\mvnw.cmd -q -DskipTests package
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest
```

## 5. Aplicar Kubernetes

## 5. file-reception-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-file-reception-service
```

```powershell
.\mvnw.cmd -q -DskipTests package
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/file-reception-service:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/file-reception-service:latest
```

## 6. tariff-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-tariff-service\banquito-tariff-service
```

```powershell
.\mvnw.cmd -q -DskipTests package
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/tariff-service:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/tariff-service:latest
```

## 7. clearinghouse-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-clearinghouse-service\banquito-clearinghouse-service
```

```powershell
.\mvnw.cmd -q -DskipTests package
```

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-clearinghouse-service
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/clearinghouse-service:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/clearinghouse-service:latest
```

## 8. report-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-report-service
```

```powershell
mvn -q -DskipTests package
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/report-service:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/report-service:latest
```

## 9. notification-service

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-notification-service
```

```powershell
mvn -q -DskipTests package
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/notification-service:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/notification-service:latest
```

## 10. teller-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-teller-frontend
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/teller-frontend:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/teller-frontend:latest
```

## 11. web-personas-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-web-personas-frontend
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest
```

## 12. web-empresas-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-web-empresas-frontend
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-empresas-frontend:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-empresas-frontend:latest
```

## 13. operador-frontend

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-frontend-web-operador
```

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/operador-frontend:latest .
```

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/operador-frontend:latest
```

## 14. Aplicar Kubernetes

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
```

```powershell
kubectl create --dry-run=client --validate=false --recursive -f .
```

```powershell
kubectl apply --recursive -f .
```

```powershell
kubectl rollout restart deployment --all -n banquito
```

## 15. Verificar

```powershell
kubectl get pods -n banquito
```

```powershell
kubectl get svc -n banquito
```

```powershell
kubectl describe pod -n banquito <nombre-del-pod>
```

```powershell
kubectl logs -n banquito <nombre-del-pod>
```

## 16. Imagenes de los micros

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/file-reception-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/tariff-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/clearinghouse-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/report-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/notification-service:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/teller-frontend:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-empresas-frontend:latest
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/operador-frontend:latest
```

## 17. Errores comunes

Si estas dentro de `banquito-infra\k8s`, usar:

```powershell
kubectl create --dry-run=client --validate=false --recursive -f .
```

No usar:

```powershell
kubectl create --dry-run=client --validate=false --recursive -f banquito-infra\k8s
```

El comando `docker build` debe ir completo:

```powershell
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest .
```

Si `docker build` falla diciendo que `target/*.jar` esta excluido por `.dockerignore`, quitar `target/` del `.dockerignore` del microservicio.

Para `report-service` y `notification-service`, si `mvn` no existe localmente, instalar Maven o usar el pipeline de GitHub Actions.

Si `docker push` falla con:

```text
gcloud.auth.docker-helper
There was a problem refreshing your current auth tokens
SSLCertVerificationError
Please run: gcloud auth login
```

ejecutar:

```powershell
gcloud auth login
gcloud config set project project-47695a8e-7cb2-4352-af2
gcloud auth configure-docker us-central1-docker.pkg.dev
```

Luego repetir:

```powershell
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest
```

## 18. Permiso GKE para descargar imagenes

Si los Pods quedan en `ErrImagePull` y el `describe pod` muestra:

```text
failed to fetch oauth token: 403 Forbidden
```

dar permiso de lectura al service account del cluster:

```powershell
gcloud artifacts repositories add-iam-policy-binding banquito `
  --location=us-central1 `
  --project=project-47695a8e-7cb2-4352-af2 `
  --member=serviceAccount:69503932816-compute@developer.gserviceaccount.com `
  --role=roles/artifactregistry.reader
```

Recrear Pods:

```powershell
kubectl --insecure-skip-tls-verify=true delete pod --all -n banquito
```

## 19. Aplicar completo con workaround TLS local

En esta maquina fue necesario usar:

```powershell
kubectl --insecure-skip-tls-verify=true apply --validate=false --recursive -f .
```

Verificar:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito
kubectl --insecure-skip-tls-verify=true get svc -n banquito
kubectl --insecure-skip-tls-verify=true get deployments -n banquito
```

## 20. Apagar Pods para no seguir consumiendo

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito
```

## 21. Apagar todo de forma segura por nombres

Si `--all` falla por conexion local, usar los nombres explicitos:

```powershell
$deployments = 'account-core-service','accounting-service','clearinghouse-service','file-reception-service','notification-service','operador-frontend','party-service','report-service','tariff-service','teller-frontend','web-empresas-frontend','web-personas-frontend'
kubectl --insecure-skip-tls-verify=true scale deployment $deployments --replicas=0 -n banquito
```

Verificar:

```powershell
kubectl --insecure-skip-tls-verify=true get deployments -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

## 22. Probar por bloques

### Frontends

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment operador-frontend teller-frontend web-empresas-frontend web-personas-frontend --replicas=1 -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

### Core Bancario

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment operador-frontend teller-frontend web-empresas-frontend web-personas-frontend --replicas=0 -n banquito
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

### Switch de Pagos Masivos

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment account-core-service accounting-service party-service --replicas=0 -n banquito
kubectl --insecure-skip-tls-verify=true scale deployment file-reception-service tariff-service clearinghouse-service report-service notification-service --replicas=1 -n banquito
kubectl --insecure-skip-tls-verify=true get pods -n banquito
```

## 23. Flujo manual para subir una nueva implementacion

Ejemplo para cualquier microservicio backend:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\<repo-del-microservicio>
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/<deployment> -n banquito
kubectl --insecure-skip-tls-verify=true rollout status deployment/<deployment> -n banquito
```

Ejemplo para frontend:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\<repo-frontend>
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
kubectl --insecure-skip-tls-verify=true rollout restart deployment/<deployment> -n banquito
```

## 24. Equivalencia con pipeline automatizado

El flujo manual anterior es lo mismo que debe hacer GitHub Actions:

```text
checkout -> build/test -> docker build -> docker push Artifact Registry -> kubectl apply/set image -> rollout status
```

Por eso, para cumplir el requisito de pipelines:

```text
Cada microservicio debe tener un workflow que publique su imagen.
banquito-infra debe tener un workflow que aplique manifiestos Kubernetes.
```
