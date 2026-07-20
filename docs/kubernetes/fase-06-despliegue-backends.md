# FASE 6 - Despliegue de microservicios backend

## Objetivo

Desplegar los ocho microservicios backend en GKE.

## Backends desplegados

| Microservicio | Namespace | Deployment | Service | HTTP | gRPC |
| --- | --- | --- | --- | ---: | ---: |
| Account Core | `banquito-core` | `account-core-service` | `account-core-service` | 8081 | 9091 |
| Accounting | `banquito-core` | `accounting-service` | `accounting-service` | 8082 | 9092 |
| Party | `banquito-core` | `party-service` | `party-service` | 8083 | 9093 |
| File Reception | `banquito-switch` | `file-reception-service` | `file-reception-service` | 8084 | n/a |
| Tariff | `banquito-switch` | `tariff-service` | `tariff-service` | 8086 | 9090 |
| Clearinghouse | `banquito-switch` | `clearinghouse-service` | `clearinghouse-service` | 8087 | n/a |
| Report | `banquito-switch` | `report-service` | `report-service` | 8088 | n/a |
| Notification | `banquito-switch` | `notification-service` | `notification-service` | 8089 | 9092 |

## Convenciones

```text
replicas: 1
strategy: Recreate
imagePullPolicy: Always
ConfigMap: banquito-config
Secret: especifico por microservicio
```

Se usa `Recreate` en demo para evitar Pods duplicados durante actualizaciones en un cluster con cuota limitada.

## Secrets por microservicio

| Deployment | Secret |
| --- | --- |
| `account-core-service` | `account-core-secrets` |
| `accounting-service` | `accounting-secrets` |
| `party-service` | `party-secrets` |
| `file-reception-service` | `file-reception-secrets` |
| `tariff-service` | `tariff-secrets` |
| `clearinghouse-service` | `mongo-services-secrets` |
| `report-service` | `mongo-services-secrets` |
| `notification-service` | `mongo-services-secrets` |

## Aplicar backends

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s

kubectl apply -f account-core
kubectl apply -f accounting
kubectl apply -f party
kubectl apply -f file-reception
kubectl apply -f tariff
kubectl apply -f clearinghouse
kubectl apply -f report
kubectl apply -f notification
```

## Levantar por dominio

Core:

```powershell
kubectl scale deployment --all --replicas=1 -n banquito-core
kubectl get pods -n banquito-core
```

Switch:

```powershell
kubectl scale deployment --all --replicas=1 -n banquito-switch
kubectl get pods -n banquito-switch
```

## Autoescalamiento HPA

Se aplicaron HPAs para los backends:

```powershell
kubectl apply -f .\hpa\account-core-hpa.yaml
kubectl apply -f .\hpa\switch-hpa.yaml
kubectl get hpa -n banquito-core
kubectl get hpa -n banquito-switch
```

Politica:

```text
Core:   min 1, max 3, CPU 70%, memoria 80%
Switch: min 1, max 3, CPU 70%, memoria 80%
```

En modo laboratorio, los Deployments pueden quedar en `0/0` para evitar consumo. Cuando se escalan a `1`, HPA puede subir replicas si CPU o memoria superan los umbrales definidos.

## Ver logs

```powershell
kubectl logs -n banquito-core deployment/account-core-service --tail=100
kubectl logs -n banquito-switch deployment/file-reception-service --tail=100
```

## Estado observado

Kubernetes descarga imagenes y crea Pods correctamente. Los fallos actuales de `CrashLoopBackOff` se deben a Secrets/credenciales reales pendientes, no a Docker ni a GKE.

## Validacion gRPC entre Core y Switch

Fecha de validacion: `2026-07-17`.

Objetivo:

```text
Core -> Switch por gRPC interno
Switch -> Core por gRPC interno
```

Se encendieron solamente:

```powershell
kubectl scale deployment account-core-service --replicas=1 -n banquito-core
kubectl scale deployment notification-service --replicas=1 -n banquito-switch
```

Se verificaron endpoints internos:

```powershell
kubectl get endpoints -n banquito-core
kubectl get endpoints -n banquito-switch
```

Resultado:

```text
account-core-service   10.2.128.33:8081,10.2.128.33:9091
notification-service   10.2.128.39:8089,10.2.128.39:9092
```

### Ajuste aplicado en notification-service

Durante la prueba se detecto que `notification-service` estaba publicando el puerto gRPC `9092`, pero la aplicacion levantaba gRPC en `9090` por la variable global:

```text
GRPC_SERVER_PORT=9090
```

Se corrigio el Deployment de notification para fijar explicitamente:

```yaml
env:
  - name: GRPC_PORT
    value: "9092"
  - name: GRPC_SERVER_PORT
    value: "9092"
```

Luego se aplico:

```powershell
kubectl apply -f .\notification\deployment.yaml
kubectl rollout restart deployment notification-service -n banquito-switch
```

### Prueba Core -> Switch

Desde namespace `banquito-core` hacia `notification-service` en `banquito-switch`:

```powershell
kubectl run grpcurl-core-to-notification `
  --rm -i --restart=Never `
  --image=fullstorydev/grpcurl:latest `
  -n banquito-core `
  --command -- grpcurl -plaintext -max-time 10 notification-service.banquito-switch.svc.cluster.local:9092 list
```

Resultado:

```text
com.banquito.switch.notification.NotificationService
grpc.health.v1.Health
grpc.reflection.v1alpha.ServerReflection
```

Prueba de health:

```powershell
kubectl run grpc-health-notification `
  --rm -i --restart=Never `
  --image=fullstorydev/grpcurl:latest `
  -n banquito-core `
  --command -- grpcurl -plaintext -max-time 10 -d '{}' notification-service.banquito-switch.svc.cluster.local:9092 grpc.health.v1.Health/Check
```

Resultado:

```json
{
  "status": "SERVING"
}
```

### Prueba Switch -> Core

Desde namespace `banquito-switch` hacia `account-core-service` en `banquito-core`:

```powershell
kubectl run grpc-switch-to-core `
  --rm -i --restart=Never `
  --image=curlimages/curl:8.8.0 `
  -n banquito-switch `
  --command -- curl -v --max-time 8 telnet://account-core-service.banquito-core.svc.cluster.local:9091
```

Resultado:

```text
Host account-core-service.banquito-core.svc.cluster.local:9091 was resolved
Received binary HTTP/2/gRPC preface
```

Tambien se intento `grpcurl list`, pero `account-core-service` no expone reflection gRPC:

```text
server does not support the reflection API
```

Eso no indica falla de red; indica que para invocar metodos reales de Account Core con `grpcurl` se necesita el archivo `.proto`.

### Conclusion

La comunicacion interna entre namespaces queda validada:

```text
Core -> Switch: gRPC real validado con Health SERVING
Switch -> Core: DNS + TCP/HTTP2 gRPC validado; requiere proto para llamada funcional
```

Al finalizar, se apagaron los deployments usados:

```powershell
kubectl scale deployment account-core-service --replicas=0 -n banquito-core
kubectl scale deployment notification-service --replicas=0 -n banquito-switch
```

Resultado:

```text
banquito-core:   0/0
banquito-switch: 0/0
```

## Validacion gRPC interna de Core

Fecha de validacion: `2026-07-17`.

Objetivo:

```text
account-core-service -> accounting-service por gRPC
account-core-service -> party-service por gRPC
party-service -> account-core-service por gRPC
```

Se encendieron solamente los microservicios de Core:

```powershell
kubectl scale deployment account-core-service --replicas=1 -n banquito-core
kubectl scale deployment accounting-service --replicas=1 -n banquito-core
kubectl scale deployment party-service --replicas=1 -n banquito-core
```

Se verifico que los tres Pods quedaran listos:

```powershell
kubectl get pods -n banquito-core -o wide
```

Resultado:

```text
account-core-service   1/1 Running
accounting-service     1/1 Running
party-service          1/1 Running
```

Se verificaron endpoints internos HTTP y gRPC:

```powershell
kubectl get endpoints -n banquito-core
```

Resultado:

```text
account-core-service   10.2.128.46:8081,10.2.128.46:9091
accounting-service     10.2.128.47:8082,10.2.128.47:9092
party-service          10.2.128.48:8083,10.2.128.48:9093
```

### Pruebas de conectividad gRPC

Desde un Pod temporal dentro del namespace `banquito-core`, se probaron los puertos gRPC:

```powershell
kubectl run grpc-core-to-accounting `
  --rm -i --restart=Never `
  --image=curlimages/curl:8.8.0 `
  -n banquito-core `
  --command -- curl -v --max-time 8 telnet://accounting-service.banquito-core.svc.cluster.local:9092
```

```powershell
kubectl run grpc-core-to-party `
  --rm -i --restart=Never `
  --image=curlimages/curl:8.8.0 `
  -n banquito-core `
  --command -- curl -v --max-time 8 telnet://party-service.banquito-core.svc.cluster.local:9093
```

```powershell
kubectl run grpc-core-self `
  --rm -i --restart=Never `
  --image=curlimages/curl:8.8.0 `
  -n banquito-core `
  --command -- curl -v --max-time 8 telnet://account-core-service.banquito-core.svc.cluster.local:9091
```

Resultado observado en los tres casos:

```text
DNS resuelve el Service interno
La conexion TCP abre contra el puerto gRPC
Se reciben bytes binarios HTTP/2/gRPC
```

`curl` termina en timeout porque no habla gRPC; sin embargo, el hecho de recibir la preface binaria HTTP/2 confirma que el puerto gRPC responde.

### Reflection gRPC

Se intento validar con `grpcurl`:

```powershell
kubectl run grpcurl-party `
  --rm -i --restart=Never `
  --image=fullstorydev/grpcurl:latest `
  -n banquito-core `
  --command -- grpcurl -plaintext -max-time 10 party-service.banquito-core.svc.cluster.local:9093 list
```

Resultado:

```text
server does not support the reflection API
```

Esto no es una falla de red. Significa que los servicios Core no exponen gRPC reflection. Para invocar metodos reales con `grpcurl`, se necesitan los archivos `.proto`.

Se busco en el workspace:

```powershell
rg --files | rg "\.proto$"
```

Resultado:

```text
No se encontraron archivos .proto
```

### Evidencia de arranque de servidores

`party-service`:

```text
Party gRPC server started on port 9093
```

`accounting-service`:

```text
accounting-service 1/1 Running
endpoint 10.2.128.47:9092
```

`account-core-service`:

```text
account-core-service 1/1 Running
endpoint 10.2.128.46:9091
```

### Conclusion

La comunicacion interna de Core queda validada a nivel Kubernetes, DNS, Service y puerto gRPC:

```text
account-core-service:9091 OK
accounting-service:9092 OK
party-service:9093 OK
```

Para una prueba funcional de metodos gRPC reales se requiere:

```text
1. Habilitar gRPC reflection en los servicios, o
2. Disponer de los archivos .proto de Account Core, Accounting y Party.
```

Al finalizar, se apagaron los microservicios de Core para evitar consumo:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
```

Resultado:

```text
banquito-core: 0/0
```

## Entregable

Los ocho microservicios tienen Deployment y Service en GKE.
