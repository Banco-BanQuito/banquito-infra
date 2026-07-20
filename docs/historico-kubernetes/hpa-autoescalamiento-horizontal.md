# HPA - Autoescalamiento horizontal en GKE Autopilot

## Idea principal

GKE Autopilot administra la capacidad del cluster, pero no aumenta automaticamente el numero de Pods de una aplicacion.

El escalamiento funciona asi:

```text
HPA escala Pods.
GKE Autopilot escala nodos/capacidad.
```

Con HPA:

```text
Carga normal     -> 1 Pod
Carga alta       -> 2 o 3 Pods
Carga baja       -> vuelve a 1 Pod
```

Configuracion recomendada para demo:

```text
minReplicas: 1
maxReplicas: 3
cpu-percent: 70
```

## Verificar metricas

Antes de aplicar HPA, validar que Kubernetes pueda leer consumo:

```powershell
kubectl top nodes
kubectl top pods -n banquito-core
kubectl top pods -n banquito-switch
kubectl top pods -n banquito-frontend
```

Ver si ya existe HPA:

```powershell
kubectl get hpa -A
```

## Aplicar HPA a Core Bancario

```powershell
kubectl autoscale deployment account-core-service --namespace banquito-core --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment accounting-service --namespace banquito-core --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment party-service --namespace banquito-core --min=1 --max=3 --cpu-percent=70
```

Ver HPA de Core:

```powershell
kubectl get hpa -n banquito-core
kubectl describe hpa account-core-service -n banquito-core
kubectl describe hpa accounting-service -n banquito-core
kubectl describe hpa party-service -n banquito-core
```

## Aplicar HPA a Switch de Pagos Masivos

```powershell
kubectl autoscale deployment file-reception-service --namespace banquito-switch --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment tariff-service --namespace banquito-switch --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment clearinghouse-service --namespace banquito-switch --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment report-service --namespace banquito-switch --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment notification-service --namespace banquito-switch --min=1 --max=3 --cpu-percent=70
```

Ver HPA de Switch:

```powershell
kubectl get hpa -n banquito-switch
kubectl describe hpa file-reception-service -n banquito-switch
kubectl describe hpa tariff-service -n banquito-switch
kubectl describe hpa clearinghouse-service -n banquito-switch
kubectl describe hpa report-service -n banquito-switch
kubectl describe hpa notification-service -n banquito-switch
```

## Aplicar HPA a Frontends

```powershell
kubectl autoscale deployment teller-frontend --namespace banquito-frontend --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment web-personas-frontend --namespace banquito-frontend --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment web-empresas-frontend --namespace banquito-frontend --min=1 --max=3 --cpu-percent=70
kubectl autoscale deployment operador-frontend --namespace banquito-frontend --min=1 --max=3 --cpu-percent=70
```

Ver HPA de Frontends:

```powershell
kubectl get hpa -n banquito-frontend
kubectl describe hpa teller-frontend -n banquito-frontend
kubectl describe hpa web-personas-frontend -n banquito-frontend
kubectl describe hpa web-empresas-frontend -n banquito-frontend
kubectl describe hpa operador-frontend -n banquito-frontend
```

## Ver Pods creados por HPA

```powershell
kubectl get pods -n banquito-core
kubectl get pods -n banquito-switch
kubectl get pods -n banquito-frontend
```

Ver consumo:

```powershell
kubectl top pods -n banquito-core
kubectl top pods -n banquito-switch
kubectl top pods -n banquito-frontend
```

Ver Deployments y replicas:

```powershell
kubectl get deployments -n banquito-core
kubectl get deployments -n banquito-switch
kubectl get deployments -n banquito-frontend
```

## Eliminar HPA

Si el autoescalamiento genera muchos Pods o costo, eliminarlo:

```powershell
kubectl delete hpa --all -n banquito-core
kubectl delete hpa --all -n banquito-switch
kubectl delete hpa --all -n banquito-frontend
```

Luego dejar 1 Pod por microservicio:

```powershell
kubectl scale deployment --all --replicas=1 -n banquito-core
kubectl scale deployment --all --replicas=1 -n banquito-switch
kubectl scale deployment --all --replicas=1 -n banquito-frontend
```

O apagar todo para no consumir:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-switch
kubectl scale deployment --all --replicas=0 -n banquito-frontend
```

## Frase para defensa

```text
El proyecto usa GKE Autopilot para administrar la infraestructura del cluster. El escalamiento horizontal de las aplicaciones se habilita con Horizontal Pod Autoscaler. HPA aumenta o reduce Pods segun consumo de CPU y Autopilot aprovisiona la capacidad necesaria para ejecutar esos Pods. Cuando baja la carga, HPA retorna al minimo de una replica y Autopilot libera capacidad no utilizada.
```
