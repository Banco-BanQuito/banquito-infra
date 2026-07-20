# Anexo D - Comandos para subir mejoras

## Backend Java

Patron:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\<repo>
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
kubectl rollout restart deployment/<deployment> -n <namespace>
kubectl rollout status deployment/<deployment> -n <namespace>
```

Ejemplo Account Core:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-account-core-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:latest
kubectl rollout restart deployment/account-core-service -n banquito-core
kubectl rollout status deployment/account-core-service -n banquito-core
```

## Frontend

Patron:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\<repo-frontend>
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/<image>:latest
kubectl rollout restart deployment/<deployment> -n banquito-frontend
kubectl rollout status deployment/<deployment> -n banquito-frontend
```

Ejemplo Web Personas:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-web-personas-frontend
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest
kubectl rollout restart deployment/web-personas-frontend -n banquito-frontend
kubectl rollout status deployment/web-personas-frontend -n banquito-frontend
```

## Verificar rollout

```powershell
kubectl get pods -n banquito-core
kubectl get pods -n banquito-switch
kubectl get pods -n banquito-frontend
kubectl get events -n banquito-core --sort-by=.lastTimestamp
```

## Pausar despliegues durante correcciones

Si despues de subir una mejora los Pods quedan en `CrashLoopBackOff` por configuracion runtime, se pueden apagar temporalmente los backends:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-core
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=0 -n banquito-switch
```

Verificar estado `0/0`:

```powershell
kubectl --insecure-skip-tls-verify=true get deploy -n banquito-core
kubectl --insecure-skip-tls-verify=true get deploy -n banquito-switch
```

Despues de corregir Secrets o ConfigMaps, levantar otra vez:

```powershell
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=1 -n banquito-core
kubectl --insecure-skip-tls-verify=true scale deployment --all --replicas=1 -n banquito-switch
```

## Recomendacion

Para despliegues trazables usar tags por commit:

```text
us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/account-core-service:<github-sha>
```
