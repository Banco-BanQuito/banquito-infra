# Exposicion de GKE para Apigee

## Objetivo

Exponer de forma controlada los microservicios desplegados en GKE para que Apigee pueda enrutar peticiones hacia ellos.

Flujo objetivo:

```text
Frontend
  -> Apigee
  -> Endpoint publico de GKE
  -> Kubernetes Service
  -> Pod backend
```

## Estado actual del cluster

Cluster:

```text
banquito-cluster-east
```

Modo:

```text
Autopilot
```

Region:

```text
us-east1
```

Endpoint administrativo Kubernetes:

```text
34.148.92.193
```

Importante:

```text
34.148.92.193 es el endpoint del API Server de Kubernetes.
No es el endpoint de aplicaciones para Apigee.
```

## Gateway API creado

Se creo un Gateway publico en GKE:

```text
Namespace:
banquito-gateway

Gateway:
banquito-public-gateway

GatewayClass:
gke-l7-global-external-managed

Puerto:
80 HTTP
```

Manifiestos:

```text
banquito-infra/k8s/gateway/gateway.yaml
banquito-infra/k8s/gateway/core-routes.yaml
banquito-infra/k8s/gateway/switch-routes.yaml
banquito-infra/k8s/gateway/healthcheck-core.yaml
banquito-infra/k8s/gateway/healthcheck-switch.yaml
```

Comando aplicado:

```powershell
kubectl apply -f banquito-infra\k8s\namespace.yaml
kubectl apply -f banquito-infra\k8s\gateway
```

Estado observado:

```text
Gateway creado.
HTTPRoutes aceptadas.
BackendServices y NEGs creados en Google Cloud.
Gateway aun sin ADDRESS publico visible en el objeto Gateway.
```

Verificar:

```powershell
kubectl get gateway -A -o wide
kubectl describe gateway banquito-public-gateway -n banquito-gateway
kubectl get httproute -A
```

Salida observada:

```text
NAMESPACE          NAME                      CLASS                            ADDRESS   PROGRAMMED
banquito-gateway   banquito-public-gateway   gke-l7-global-external-managed
```

Interpretacion:

```text
El Gateway esta creado y las rutas estan aceptadas, pero todavia no tiene IP publica asignada en status.addresses.
```

## Rutas Gateway creadas

### Core

HTTPRoute:

```text
banquito-core/core-routes
```

Rutas hacia `account-core-service:8081`:

```text
/api/v2/auth/login/staff
/api/v2/accounts
/api/v2/calendar
/api/v2/eod
/api/v2/payments/batch-credit
/api/v2/payments/corporate-debit
/api/v2/payments/corporate-refund
/api/v2/payments/offus-settlement
```

Rutas hacia `accounting-service:8082`:

```text
/api/v2/accounting
```

Rutas hacia `party-service:8083`:

```text
/api/v2/auth/login
/api/v2/auth/change-password
/api/v2/customers
/api/v2/customer-subtypes
/api/v2/core-parameters
/api/v2/branches
/api/v2/holidays
```

### Switch

HTTPRoute:

```text
banquito-switch/switch-routes
```

Rutas hacia `file-reception-service:8084`:

```text
/api/v2/payments/batches
/api/v2/payments/routing-codes
```

Rutas hacia `tariff-service:8086`:

```text
/api/v2/tariff
```

Rutas hacia `clearinghouse-service:8087`:

```text
/api/v2/clearing
```

Rutas hacia `report-service:8088`:

```text
/api/v2/payments/receipts
/api/v2/reports
```

Rutas hacia `notification-service:8089`:

```text
/api/v2/notifications
```

## Estado actual de Services

Se observo que en el cluster actual los Services de Core aparecen como `LoadBalancer`:

```text
account-core-service   LoadBalancer   EXTERNAL-IP 34.148.116.205   8081,9091
accounting-service     LoadBalancer   EXTERNAL-IP 136.108.31.44    8082,9092
party-service          LoadBalancer   EXTERNAL-IP 136.108.32.59    8083,9093
```

Los Services de Switch siguen internos:

```text
clearinghouse-service    ClusterIP
file-reception-service   ClusterIP
notification-service     ClusterIP
report-service           ClusterIP
tariff-service           ClusterIP
```

Comando:

```powershell
kubectl get svc -n banquito-core -o wide
kubectl get svc -n banquito-switch -o wide
```

## Target inmediato para Apigee Account Core

Si se necesita probar inmediatamente solo Account Core, Apigee puede apuntar temporalmente a:

```text
http://34.148.116.205:8081
```

Ruta Apigee:

```text
https://136.68.89.25.nip.io/api/v2/accounts
```

Target:

```text
http://34.148.116.205:8081
```

Advertencia:

```text
Este target usa un Service LoadBalancer directo para account-core-service.
Es util para pruebas, pero no es la arquitectura final mas limpia.
```

## Target recomendado para Apigee

La opcion recomendada es esperar/usar el ADDRESS del Gateway:

```powershell
kubectl get gateway banquito-public-gateway -n banquito-gateway -o wide
```

Cuando aparezca:

```text
ADDRESS <ip-publica>
```

Apigee debe apuntar a:

```text
http://<ip-publica-del-gateway>
```

Y mantener rutas:

```text
/api/v2/accounts/**
/api/v2/accounting/**
/api/v2/customers/**
/api/v2/payments/**
/api/v2/clearing/**
/api/v2/reports/**
/api/v2/notifications/**
```

## Diferencia entre opciones

### LoadBalancer por microservicio

Ventajas:

```text
Simple para pruebas.
Cada microservicio tiene una IP publica propia.
```

Desventajas:

```text
Mas costo.
Mas IPs publicas.
Mas dificil de gobernar.
Menos limpio para Apigee.
```

### Gateway unico

Ventajas:

```text
Una entrada publica para GKE.
Rutas centralizadas.
Mejor alineado con Apigee.
Menos exposicion directa de microservicios.
```

Desventajas:

```text
Requiere esperar aprovisionamiento de Load Balancer.
Requiere que los backends esten Ready para health checks.
```

## Estado de Pods

Aunque la exposicion existe parcialmente, los Pods backend estan fallando por configuracion de aplicacion:

```text
CrashLoopBackOff
```

Causa diagnosticada previamente:

```text
Secrets con placeholders o credenciales incorrectas.
```

Mientras los Pods no esten `Running` y `Ready`, Apigee puede llegar al endpoint, pero el backend respondera error o el balanceador marcara el servicio como no saludable.

Ver estado:

```powershell
kubectl get pods -n banquito-core
kubectl get pods -n banquito-switch
```

Ver logs:

```powershell
kubectl logs -n banquito-core deployment/account-core-service --tail=100
kubectl logs -n banquito-switch deployment/file-reception-service --tail=100
```

## Recomendacion para documentacion

Para la entrega:

```text
Se implemento Gateway API en GKE como punto de entrada publico/controlado para que Apigee enrute hacia los microservicios internos. Adicionalmente, durante pruebas, algunos servicios Core aparecen expuestos mediante LoadBalancer directo. La arquitectura recomendada es Apigee -> GKE Gateway -> Services internos, evitando exponer cada microservicio individualmente.
```

## Comandos de verificacion

```powershell
kubectl get gateway -A -o wide
kubectl get httproute -A
kubectl get healthcheckpolicy -A
kubectl get svc -n banquito-core -o wide
kubectl get svc -n banquito-switch -o wide
kubectl get pods -n banquito-core
kubectl get pods -n banquito-switch
```

Ver recursos creados en Google Cloud:

```powershell
gcloud compute backend-services list --project project-47695a8e-7cb2-4352-af2
gcloud compute forwarding-rules list --project project-47695a8e-7cb2-4352-af2
```

