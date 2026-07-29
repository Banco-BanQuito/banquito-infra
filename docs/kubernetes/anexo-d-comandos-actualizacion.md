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

Ejemplo Payment Line Publisher:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-payment-line-publisher-service
.\mvnw.cmd -q -DskipTests package
docker build -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/payment-line-publisher-service:latest .
docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/payment-line-publisher-service:latest
kubectl rollout restart deployment/payment-line-publisher-service -n banquito-switch
kubectl rollout status deployment/payment-line-publisher-service -n banquito-switch
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
## Levantar deployments individuales

Core:

```powershell
kubectl scale deployment account-core-service --replicas=1 -n banquito-core
kubectl scale deployment accounting-service --replicas=1 -n banquito-core
kubectl scale deployment party-service --replicas=1 -n banquito-core
```

Switch:

```powershell
kubectl scale deployment file-reception-service --replicas=1 -n banquito-switch
kubectl scale deployment payment-line-classifier-service --replicas=1 -n banquito-switch
kubectl scale deployment payment-line-publisher-service --replicas=1 -n banquito-switch
kubectl scale deployment payment-line-subscriber-service --replicas=1 -n banquito-switch
kubectl scale deployment clearinghouse-service --replicas=1 -n banquito-switch
kubectl scale deployment tariff-service --replicas=1 -n banquito-switch
kubectl scale deployment report-service --replicas=1 -n banquito-switch
kubectl scale deployment notification-service --replicas=1 -n banquito-switch
```

Frontends:

```powershell
kubectl scale deployment web-personas-frontend --replicas=1 -n banquito-frontend
kubectl scale deployment web-empresas-frontend --replicas=1 -n banquito-frontend
kubectl scale deployment teller-frontend --replicas=1 -n banquito-frontend
kubectl scale deployment operador-frontend --replicas=1 -n banquito-frontend
```

## Levantar por bloques

Core completo:

```powershell
kubectl scale deployment account-core-service accounting-service party-service --replicas=1 -n banquito-core
```

Switch completo:

```powershell
kubectl scale deployment file-reception-service payment-line-classifier-service payment-line-publisher-service payment-line-subscriber-service clearinghouse-service tariff-service report-service notification-service --replicas=1 -n banquito-switch
```

Switch por bloque de ingesta, clasificacion y broker:

```powershell
kubectl scale deployment file-reception-service payment-line-classifier-service payment-line-publisher-service payment-line-subscriber-service --replicas=1 -n banquito-switch
```

Switch por bloque de compensacion:

```powershell
kubectl scale deployment clearinghouse-service --replicas=1 -n banquito-switch
```

Switch por bloque secundario:

```powershell
kubectl scale deployment tariff-service report-service notification-service --replicas=1 -n banquito-switch
```

Frontends completos:

```powershell
kubectl scale deployment web-personas-frontend web-empresas-frontend teller-frontend operador-frontend --replicas=1 -n banquito-frontend
```

## Bajar por bloques

Core completo:

```powershell
kubectl scale deployment account-core-service accounting-service party-service --replicas=0 -n banquito-core
```

Switch completo:

```powershell
kubectl scale deployment file-reception-service payment-line-classifier-service payment-line-publisher-service payment-line-subscriber-service clearinghouse-service tariff-service report-service notification-service --replicas=0 -n banquito-switch
```

Frontends completos:

```powershell
kubectl scale deployment web-personas-frontend web-empresas-frontend teller-frontend operador-frontend --replicas=0 -n banquito-frontend
```

## Bajar individual

Core:

```powershell
kubectl scale deployment account-core-service --replicas=0 -n banquito-core
kubectl scale deployment accounting-service --replicas=0 -n banquito-core
kubectl scale deployment party-service --replicas=0 -n banquito-core
```

Switch:

```powershell
kubectl scale deployment file-reception-service --replicas=0 -n banquito-switch
kubectl scale deployment payment-line-classifier-service --replicas=0 -n banquito-switch
kubectl scale deployment payment-line-publisher-service --replicas=0 -n banquito-switch
kubectl scale deployment payment-line-subscriber-service --replicas=0 -n banquito-switch
kubectl scale deployment clearinghouse-service --replicas=0 -n banquito-switch
kubectl scale deployment tariff-service --replicas=0 -n banquito-switch
kubectl scale deployment report-service --replicas=0 -n banquito-switch
kubectl scale deployment notification-service --replicas=0 -n banquito-switch
```

Frontends:

```powershell
kubectl scale deployment web-personas-frontend --replicas=0 -n banquito-frontend
kubectl scale deployment web-empresas-frontend --replicas=0 -n banquito-frontend
kubectl scale deployment teller-frontend --replicas=0 -n banquito-frontend
kubectl scale deployment operador-frontend --replicas=0 -n banquito-frontend
```

## Bajar seleccionados

Solo `file-reception-service` y `clearinghouse-service`:

```powershell
kubectl scale deployment file-reception-service clearinghouse-service --replicas=0 -n banquito-switch
```

Solo frontends web:

```powershell
kubectl scale deployment web-personas-frontend web-empresas-frontend --replicas=0 -n banquito-frontend
```

## Ver worker nodes y ubicacion de pods

Ver los worker nodes activos:

```powershell
kubectl get nodes -o wide
```

Ver todos los pods y en que worker node estan alojados:

```powershell
kubectl get pods -A -o wide
```

Ver pods ordenados por worker node:

```powershell
kubectl get pods -A -o wide --sort-by=.spec.nodeName
```

Ver solo los pods del Core con su worker node:

```powershell
kubectl get pods -n banquito-core -o wide
```

Ver solo los pods del Switch con su worker node:

```powershell
kubectl get pods -n banquito-switch -o wide
```

Ver solo los pods de Frontend con su worker node:

```powershell
kubectl get pods -n banquito-frontend -o wide
```

Ver detalle de un worker node:

```powershell
kubectl describe node <nombre-del-worker-node>
```

En el detalle del nodo revisar:

| Seccion | Que muestra |
| --- | --- |
| `Capacity` | CPU y memoria total del nodo. |
| `Allocatable` | CPU y memoria disponible para pods. |
| `Non-terminated Pods` | Pods que estan corriendo en ese worker node. |
| `Allocated resources` | Recursos solicitados por los pods del nodo. |
| `Events` | Eventos importantes del nodo. |

Ver consumo de worker nodes:

```powershell
kubectl top nodes
```

Ver consumo de pods:

```powershell
kubectl top pods -A
```

Ver consumo de pods del Switch ordenado por CPU:

```powershell
kubectl top pods -n banquito-switch --sort-by=cpu
```

## Probar comunicacion interna de Clearing OFF-US

El flujo principal entre `payment-line-subscriber-service` y `clearinghouse-service` usa gRPC por el puerto `9094`.

Verificar que el Service expone HTTP y gRPC:

```powershell
kubectl get svc clearinghouse-service -n banquito-switch
```

Ver logs del servidor gRPC de clearing:

```powershell
kubectl logs -n banquito-switch deployment/clearinghouse-service --since=10m
```

Levantar un `port-forward` local hacia el puerto gRPC:

```powershell
kubectl port-forward svc/clearinghouse-service 9094:9094 -n banquito-switch
```

En otra terminal, con `grpcurl` instalado, probar el contrato interno:

```powershell
grpcurl -plaintext `
  -d "{\"batch_id\":\"00000000-0000-0000-0000-000000000001\",\"transaction_id\":\"00000000-0000-0000-0000-000000000002\",\"routing_code\":\"002\",\"origin_account\":\"1010114999\",\"destination_account\":\"2014146881\",\"amount\":\"10.50\",\"currency\":\"USD\",\"concept\":\"Prueba OFF-US\",\"value_date\":\"2026-07-28\"}" `
  localhost:9094 `
  banquito.clearing.v2.ClearingService/RegisterOffUsPayment
```

Ver logs de clearing:

```powershell
kubectl logs -n banquito-switch deployment/clearinghouse-service --since=10m
```
