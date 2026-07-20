# Anexo C - HPA y GKE Autopilot

## Idea principal

GKE Autopilot escala capacidad de infraestructura. HPA escala Pods de aplicacion.

```text
HPA aumenta o reduce replicas.
Autopilot crea o libera capacidad para ejecutar esas replicas.
```

## Estado aplicado

El cluster soporta HPA:

```powershell
kubectl api-resources | Select-String -Pattern 'horizontalpodautoscalers|metrics'
```

Resultado:

```text
horizontalpodautoscalers   autoscaling/v2
pods                       metrics.k8s.io/v1beta1
```

Se crearon manifiestos HPA en:

```text
k8s/hpa/account-core-hpa.yaml
k8s/hpa/switch-hpa.yaml
k8s/hpa/frontend-hpa.yaml
```

## Aplicar HPA

Aplicar todos los HPAs:

```powershell
kubectl apply -f .\hpa
```

## Politica aplicada

| Grupo | Min | Max | Metrica |
| --- | ---: | ---: | --- |
| Core backends | 1 | 3 | CPU 70%, memoria 80% |
| Switch backends | 1 | 3 | CPU 70%, memoria 80% |
| Frontends | 1 | 3 | CPU 70% |

## Recursos ajustados

Fecha de ajuste: `2026-07-18`.

Se subieron los recursos de los backends Spring Boot porque los valores iniciales eran demasiado bajos para aplicaciones Java con conexiones a bases de datos, gRPC, RabbitMQ y health checks.

Perfil aplicado a backends pesados:

```text
account-core-service
file-reception-service
clearinghouse-service
```

```yaml
resources:
  requests:
    cpu: 300m
    memory: 768Mi
  limits:
    cpu: 750m
    memory: 1Gi
```

Perfil aplicado a backends normales:

```text
accounting-service
party-service
tariff-service
notification-service
report-service
```

```yaml
resources:
  requests:
    cpu: 250m
    memory: 512Mi
  limits:
    cpu: 500m
    memory: 768Mi
```

Los frontends Nginx/Vite se mantienen livianos:

```yaml
resources:
  requests:
    cpu: 50m
    memory: 64Mi
  limits:
    cpu: 150m
    memory: 128Mi
```

Impacto esperado:

```text
1. Menos riesgo de OOMKilled en backends Java.
2. Mejor estabilidad en readiness/liveness probes.
3. Menos escalamiento prematuro por memoria.
4. Mayor consumo reservado por Pod, por lo que se debe probar por bloques si la cuota no alcanza.
```

## Como trabaja realmente

La arquitectura del cluster mantiene la separacion clasica:

```text
Control plane:
  API Server, Scheduler, Controller Manager, etcd

Data plane:
  Nodos administrados por GKE Autopilot
  Pods de cada microservicio
```

En GKE Autopilot no se administran manualmente los nodos. Kubernetes agenda Pods y Autopilot crea o libera capacidad cuando hace falta.

HPA no crea nodos directamente. HPA solo cambia el numero de replicas del Deployment:

```text
1. El Pod consume mucha CPU o memoria.
2. HPA sube replicas del Deployment, por ejemplo de 1 a 2.
3. Kubernetes intenta agendar el nuevo Pod.
4. Si no hay capacidad, Autopilot intenta crear mas capacidad.
5. Si la cuota o disponibilidad no alcanza, el Pod queda Pending.
```

Cuando baja el consumo:

```text
1. HPA reduce replicas hasta minReplicas.
2. Los Pods extra se eliminan.
3. Autopilot puede liberar nodos despues, si quedan sin carga.
```

Con la configuracion actual:

```text
minReplicas: 1
```

HPA puede bajar de `3` a `2` y luego a `1`, pero no baja automaticamente a `0`.

Para dejar `0/0` en laboratorio se usa escalado manual:

```powershell
kubectl scale deployment <deployment> --replicas=0 -n <namespace>
```

Si se requiere scale-to-zero automatico por demanda real, se necesita otro patron, por ejemplo KEDA o Cloud Run. Para este proyecto universitario se mantiene HPA con minimo 1 replica porque es el comportamiento esperado de Kubernetes para aplicaciones siempre disponibles.

Ejemplo de HPA:

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: account-core-service-hpa
  namespace: banquito-core
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: account-core-service
  minReplicas: 1
  maxReplicas: 3
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 70
    - type: Resource
      resource:
        name: memory
        target:
          type: Utilization
          averageUtilization: 80
```

## Ver HPA

```powershell
kubectl get hpa -A
kubectl get hpa -n banquito-core
kubectl get hpa -n banquito-switch
kubectl get hpa -n banquito-frontend
kubectl describe hpa account-core-service-hpa -n banquito-core
```

Estado verificado:

```text
account-core-service-hpa      min 1 max 3
accounting-service-hpa        min 1 max 3
party-service-hpa             min 1 max 3
file-reception-service-hpa    min 1 max 3
tariff-service-hpa            min 1 max 3
clearinghouse-service-hpa     min 1 max 3
report-service-hpa            min 1 max 3
notification-service-hpa      min 1 max 3
teller-frontend-hpa           min 1 max 2
web-personas-frontend-hpa     min 1 max 2
web-empresas-frontend-hpa     min 1 max 2
operador-frontend-hpa         min 1 max 2
```

## Relacion con costos

Aunque `minReplicas` del HPA sea `1`, los deployments pueden quedar manualmente en `0/0` durante pausas de laboratorio:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-switch
kubectl scale deployment --all --replicas=0 -n banquito-frontend
```

En el estado verificado, los HPAs existen pero no dejaron pods consumiendo:

```text
HPA replicas: 0
Deployments: 0/0
```

## Pendientes por cuota

HPA y Autopilot trabajan juntos, pero no eliminan los limites de cuota del proyecto.

```text
HPA detecta carga.
HPA aumenta replicas.
Autopilot intenta crear capacidad.
Si la cuota regional esta agotada, los Pods quedan Pending.
```

Evento observado:

```text
Can't scale up due to exceeded quota
GCE quota exceeded
```

Interpretacion:

```text
El autoscaling esta funcionando, pero Google Cloud no permite crear mas capacidad por limite de cuota.
```

Acciones recomendadas para el laboratorio:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment --all --replicas=0 -n banquito-switch
kubectl scale deployment --all --replicas=0 -n banquito-frontend

kubectl scale deployment account-core-service --replicas=1 -n banquito-core
kubectl scale deployment accounting-service --replicas=1 -n banquito-core
kubectl scale deployment party-service --replicas=1 -n banquito-core
```

Si se necesita probar todo el sistema al mismo tiempo:

```text
1. Solicitar aumento de cuota regional.
2. Mantener maxReplicas bajo durante la defensa.
3. Levantar primero Core, luego Switch, luego Frontends.
4. Evitar replicas innecesarias si no hay carga real.
```

Comandos para revisar HPA y eventos:

```powershell
kubectl get hpa -A
kubectl describe hpa account-core-service-hpa -n banquito-core
kubectl get events -A --sort-by=.lastTimestamp
```

## Eliminar HPA

```powershell
kubectl delete hpa --all -n banquito-core
kubectl delete hpa --all -n banquito-switch
kubectl delete hpa --all -n banquito-frontend
```

## Frase para defensa

```text
El proyecto usa GKE Autopilot para administrar la capacidad de infraestructura y Horizontal Pod Autoscaler para escalar Pods de aplicacion. Los HPAs fueron definidos con autoscaling/v2 usando CPU y memoria para backends, y CPU para frontends. Cuando la carga aumenta, HPA incrementa replicas; si el cluster necesita mas capacidad, Autopilot aprovisiona nodos automaticamente. Para controlar costos en laboratorio, los deployments pueden pausarse en 0/0 cuando no se estan probando.
```
