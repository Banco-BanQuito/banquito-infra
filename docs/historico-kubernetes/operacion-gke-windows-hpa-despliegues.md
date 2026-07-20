# Operacion GKE desde Windows 11

## Estado actual de escalamiento

Actualmente no hay `HorizontalPodAutoscaler` aplicado.

Lo que si existe en los Deployments:

```text
replicas: 1
resources.requests.cpu
resources.requests.memory
resources.limits.cpu
resources.limits.memory
```

Esto significa:

```text
Kubernetes puede reservar recursos para cada Pod.
GKE Autopilot puede programar Pods segun requests.
Pero no hay escalamiento horizontal automatico por CPU/memoria.
```

Validar si existe HPA:

```powershell
kubectl get hpa -A
```

Si no aparece nada para `banquito-core`, `banquito-switch` o `banquito-frontend`, entonces no hay HPA aplicado.

## Contexto de cluster

Proyecto:

```text
project-47695a8e-7cb2-4352-af2
```

Cluster:

```text
banquito-cluster-east
```

Region:

```text
us-east1
```

Obtener credenciales desde Windows 11:

```powershell
gcloud config set project project-47695a8e-7cb2-4352-af2
gcloud container clusters get-credentials banquito-cluster-east --region us-east1 --project project-47695a8e-7cb2-4352-af2
kubectl config current-context
```

Namespaces:

```text
banquito-core
banquito-switch
banquito-frontend
```

## Ver Pods

Por namespace:

```powershell
kubectl get pods -n banquito-core
kubectl get pods -n banquito-switch
kubectl get pods -n banquito-frontend
```

Con nodo e IP:

```powershell
kubectl get pods -n banquito-core -o wide
kubectl get pods -n banquito-switch -o wide
kubectl get pods -n banquito-frontend -o wide
```

Todos los namespaces:

```powershell
kubectl get pods -A
```

Ver Deployments:

```powershell
kubectl get deployments -n banquito-core
kubectl get deployments -n banquito-switch
kubectl get deployments -n banquito-frontend
```

Ver Services:

```powershell
kubectl get svc -n banquito-core
kubectl get svc -n banquito-switch
kubectl get svc -n banquito-frontend
```

## Ver logs y errores

Logs de un Deployment:

```powershell
kubectl logs -n banquito-core deployment/account-core-service --tail=100
kubectl logs -n banquito-core deployment/accounting-service --tail=100
kubectl logs -n banquito-core deployment/party-service --tail=100
```

Logs de Switch:

```powershell
kubectl logs -n banquito-switch deployment/file-reception-service --tail=100
kubectl logs -n banquito-switch deployment/tariff-service --tail=100
kubectl logs -n banquito-switch deployment/clearinghouse-service --tail=100
kubectl logs -n banquito-switch deployment/report-service --tail=100
kubectl logs -n banquito-switch deployment/notification-service --tail=100
```

Describir un Pod con error:

```powershell
kubectl describe pod -n banquito-core <nombre-del-pod>
```

Eventos ordenados por tiempo:

```powershell
kubectl get events -n banquito-core --sort-by=.lastTimestamp
kubectl get events -n banquito-switch --sort-by=.lastTimestamp
kubectl get events -n banquito-frontend --sort-by=.lastTimestamp
```

## Ver consumo y rendimiento

Consumo de Pods:

```powershell
kubectl top pods -n banquito-core
kubectl top pods -n banquito-switch
kubectl top pods -n banquito-frontend
```

Consumo de nodos:

```powershell
kubectl top nodes
```

Si `kubectl top` falla, revisar que Metrics Server este disponible:

```powershell
kubectl get deployment metrics-server-v1.35.1 -n kube-system
kubectl get pods -n kube-system | Select-String metrics
```

Ver requests y limits configurados:

```powershell
kubectl describe deployment account-core-service -n banquito-core
kubectl describe deployment file-reception-service -n banquito-switch
kubectl describe deployment teller-frontend -n banquito-frontend
```

Ver estado general del cluster:

```powershell
kubectl get nodes
kubectl get nodes -o wide
kubectl describe node <nombre-del-nodo>
```

Ver estado de rollouts:

```powershell
kubectl rollout status deployment/account-core-service -n banquito-core
kubectl rollout status deployment/file-reception-service -n banquito-switch
kubectl rollout status deployment/teller-frontend -n banquito-frontend
```

## Levantar por bloques

Antes de levantar backends, confirmar que `banquito-secrets` tiene valores reales, no placeholders.

Validar placeholders sin mostrar passwords:

```powershell
$namespaces='banquito-core','banquito-switch','banquito-frontend'
foreach ($ns in $namespaces) {
  Write-Host "==== $ns ===="
  $secret = kubectl get secret banquito-secrets -n $ns -o json | ConvertFrom-Json
  foreach ($key in 'DB_USER','DB_PASS','POSTGRES_USER','POSTGRES_PASSWORD','MONGO_URI','RABBITMQ_USERNAME','RABBITMQ_PASSWORD') {
    $raw = $secret.data.$key
    if ($null -eq $raw) { Write-Host "$key=MISSING"; continue }
    $value = [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($raw))
    $isPlaceholder = $value -like 'replace-with-*'
    Write-Host "$key placeholder=$isPlaceholder length=$($value.Length)"
  }
}
```

Levantar Core:

```powershell
kubectl scale deployment --all --replicas=1 -n banquito-core
kubectl get pods -n banquito-core -w
```

Apagar Core:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
```

Levantar Switch:

```powershell
kubectl scale deployment --all --replicas=1 -n banquito-switch
kubectl get pods -n banquito-switch -w
```

Apagar Switch:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-switch
```

Levantar Frontends:

```powershell
kubectl scale deployment --all --replicas=1 -n banquito-frontend
kubectl get pods -n banquito-frontend -w
```

Apagar Frontends:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-frontend
```

Apagar todo:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-switch
kubectl scale deployment --all --replicas=0 -n banquito-frontend
```

## Aplicar manifiestos correctamente

No aplicar desde:

```powershell
C:\Users\User\Desktop\KUBERNETS-PROYECTO
kubectl apply --recursive -f .
```

Eso intenta aplicar workflows, `package.json`, `docker-compose.yml` y otros archivos que no son Kubernetes.

Aplicar desde la carpeta correcta:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply --recursive -f .
```

Advertencia:

```text
Si aplicas secret.yaml, se sobrescribe banquito-secrets con placeholders.
Despues debes recrear los Secrets reales.
```

Aplicar sin tocar `secret.yaml`:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply -f namespace.yaml
kubectl apply -f configmap.yaml
kubectl apply -f account-core
kubectl apply -f accounting
kubectl apply -f party
kubectl apply -f file-reception
kubectl apply -f tariff
kubectl apply -f clearinghouse
kubectl apply -f report
kubectl apply -f notification
kubectl apply -f teller
kubectl apply -f personas
kubectl apply -f empresas
kubectl apply -f operador
```

## Subir mejora individual de un backend

Patron:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\<repo>
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
kubectl rollout restart deployment/<deployment> -n <namespace>
kubectl rollout status deployment/<deployment> -n <namespace>
kubectl get pods -n <namespace>
```

Core:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-account-core-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest
kubectl rollout restart deployment/account-core-service -n banquito-core
kubectl rollout status deployment/account-core-service -n banquito-core
```

Accounting:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-accounting-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/accounting-service:latest
kubectl rollout restart deployment/accounting-service -n banquito-core
kubectl rollout status deployment/accounting-service -n banquito-core
```

Party:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-party-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/party-service:latest
kubectl rollout restart deployment/party-service -n banquito-core
kubectl rollout status deployment/party-service -n banquito-core
```

File Reception:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-file-reception-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/file-reception-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/file-reception-service:latest
kubectl rollout restart deployment/file-reception-service -n banquito-switch
kubectl rollout status deployment/file-reception-service -n banquito-switch
```

Tariff:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-tariff-service\banquito-tariff-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/tariff-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/tariff-service:latest
kubectl rollout restart deployment/tariff-service -n banquito-switch
kubectl rollout status deployment/tariff-service -n banquito-switch
```

Clearinghouse:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-clearinghouse-service\banquito-clearinghouse-service
.\mvnw.cmd -q -DskipTests package
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-clearinghouse-service
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/clearinghouse-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/clearinghouse-service:latest
kubectl rollout restart deployment/clearinghouse-service -n banquito-switch
kubectl rollout status deployment/clearinghouse-service -n banquito-switch
```

Report:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-report-service
docker run --rm -v ${PWD}:/workspace -w /workspace maven:3.9.9-eclipse-temurin-21 mvn -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/report-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/report-service:latest
kubectl rollout restart deployment/report-service -n banquito-switch
kubectl rollout status deployment/report-service -n banquito-switch
```

Notification:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-notification-service
docker run --rm -v ${PWD}:/workspace -w /workspace maven:3.9.9-eclipse-temurin-21 mvn -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/notification-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/notification-service:latest
kubectl rollout restart deployment/notification-service -n banquito-switch
kubectl rollout status deployment/notification-service -n banquito-switch
```

## Subir mejora individual de un frontend

Teller:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-teller-frontend
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/teller-frontend:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/teller-frontend:latest
kubectl rollout restart deployment/teller-frontend -n banquito-frontend
kubectl rollout status deployment/teller-frontend -n banquito-frontend
```

Personas:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-web-personas-frontend
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest
kubectl rollout restart deployment/web-personas-frontend -n banquito-frontend
kubectl rollout status deployment/web-personas-frontend -n banquito-frontend
```

Empresas:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-web-empresas-frontend
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-empresas-frontend:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-empresas-frontend:latest
kubectl rollout restart deployment/web-empresas-frontend -n banquito-frontend
kubectl rollout status deployment/web-empresas-frontend -n banquito-frontend
```

Operador:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-frontend-web-operador
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/operador-frontend:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/operador-frontend:latest
kubectl rollout restart deployment/operador-frontend -n banquito-frontend
kubectl rollout status deployment/operador-frontend -n banquito-frontend
```

## HPA opcional

Para aplicar HPA, primero debe existir `resources.requests.cpu` en cada Deployment. Ya existe.

Ejemplo para `account-core-service`:

```powershell
kubectl autoscale deployment account-core-service `
  --namespace banquito-core `
  --min=1 `
  --max=3 `
  --cpu-percent=70
```

Ejemplo para todos los Core:

```powershell
kubectl autoscale deployment account-core-service --namespace banquito-core --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment accounting-service --namespace banquito-core --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment party-service --namespace banquito-core --min=1 --max=3 --cpu-percent=70
```

Ejemplo para Switch:

```powershell
kubectl autoscale deployment file-reception-service --namespace banquito-switch --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment tariff-service --namespace banquito-switch --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment clearinghouse-service --namespace banquito-switch --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment report-service --namespace banquito-switch --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment notification-service --namespace banquito-switch --min=1 --max=3 --cpu-percent=70
```

Ejemplo para Frontends:

```powershell
kubectl autoscale deployment teller-frontend --namespace banquito-frontend --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment web-personas-frontend --namespace banquito-frontend --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment web-empresas-frontend --namespace banquito-frontend --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment operador-frontend --namespace banquito-frontend --min=1 --max=3 --cpu-percent=70
```

Ver HPAs:

```powershell
kubectl get hpa -n banquito-core
kubectl get hpa -n banquito-switch
kubectl get hpa -n banquito-frontend
```

Describir un HPA:

```powershell
kubectl describe hpa account-core-service -n banquito-core
```

Eliminar HPA si genera demasiados Pods o costo:

```powershell
kubectl delete hpa --all -n banquito-core
kubectl delete hpa --all -n banquito-switch
kubectl delete hpa --all -n banquito-frontend
```

Recomendacion para la demo:

```text
No aplicar HPA hasta que los Secrets reales esten corregidos y los Pods queden Running.
Cuando todo este estable, aplicar HPA con min=1 y max=2 o max=3.
```

## Comandos rapidos de diagnostico

Ver todo lo de BanQuito:

```powershell
kubectl get deployments -n banquito-core
kubectl get deployments -n banquito-switch
kubectl get deployments -n banquito-frontend
kubectl get pods -n banquito-core
kubectl get pods -n banquito-switch
kubectl get pods -n banquito-frontend
kubectl get svc -n banquito-core
kubectl get svc -n banquito-switch
kubectl get svc -n banquito-frontend
```

Ver consumo:

```powershell
kubectl top nodes
kubectl top pods -n banquito-core
kubectl top pods -n banquito-switch
kubectl top pods -n banquito-frontend
```

Ver problemas:

```powershell
kubectl get events -n banquito-core --sort-by=.lastTimestamp
kubectl get events -n banquito-switch --sort-by=.lastTimestamp
kubectl get events -n banquito-frontend --sort-by=.lastTimestamp
```
