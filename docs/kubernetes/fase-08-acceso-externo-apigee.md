# FASE 8 - Configuracion de acceso externo

## Objetivo

Preparar una entrada HTTP en GKE para que Apigee pueda enrutar hacia los microservicios.

## Apigee

Dominio externo informado:

```text
https://136.68.89.25.nip.io
```

Proxy actual:

```text
account-core-api
Base Path: /api/v2/accounts
```

## GKE Gateway

Se creo:

```text
Namespace: banquito-gateway
Gateway: banquito-public-gateway
GatewayClass: gke-l7-global-external-managed
Listener: HTTP 80
```

Archivos:

```text
k8s/gateway/gateway.yaml
k8s/gateway/core-routes.yaml
k8s/gateway/switch-routes.yaml
k8s/gateway/healthcheck-core.yaml
k8s/gateway/healthcheck-switch.yaml
```

Aplicar:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply -f namespace.yaml
kubectl apply -f gateway
```

Verificar:

```powershell
kubectl get gateway -A -o wide
kubectl get httproute -A
kubectl get healthcheckpolicy -A
```

## Rutas expuestas por Gateway

Core:

```text
/api/v2/auth/login/staff -> account-core-service:8081
/api/v2/accounts -> account-core-service:8081
/api/v2/calendar -> account-core-service:8081
/api/v2/eod -> account-core-service:8081
/api/v2/accounting -> accounting-service:8082
/api/v2/auth/login -> party-service:8083
/api/v2/customers -> party-service:8083
/api/v2/branches -> party-service:8083
/api/v2/holidays -> party-service:8083
```

Switch:

```text
/api/v2/payments/batches -> file-reception-service:8084
/api/v2/payments/routing-codes -> file-reception-service:8084
/api/v2/tariff -> tariff-service:8086
/api/v2/clearing -> clearinghouse-service:8087
/api/v2/payments/receipts -> report-service:8088
/api/v2/reports -> report-service:8088
/api/v2/notifications -> notification-service:8089
```

## Estado inicial observado

El Gateway fue creado y sus rutas fueron aceptadas. En el momento de documentacion, el objeto Gateway aun no mostraba `ADDRESS` publico.

Tambien se observaron LoadBalancers directos para Core:

```text
account-core-service -> 34.148.116.205:8081
accounting-service -> 136.108.31.44:8082
party-service -> 136.108.32.59:8083
```

Para prueba inmediata de Account Core en Apigee:

```text
Target temporal: http://34.148.116.205:8081
```

Arquitectura recomendada:

```text
Apigee -> GKE Gateway -> Services internos
```

## Entregable

Gateway y HTTPRoutes creados para preparar la exposicion controlada hacia Apigee.

## Validacion frontend -> Apigee -> Core

Fecha de validacion: `2026-07-17`.

Objetivo:

```text
web-personas-frontend
  -> Apigee
      -> GKE Gateway
          -> account-core-service
```

No se encendio Switch ni RabbitMQ para esta prueba.

### Reduccion de IPs externas

Se detecto drift en el cluster: los YAML de Core estaban como `ClusterIP`, pero en vivo seguian como `LoadBalancer`.

Estado previo:

```text
account-core-service   LoadBalancer   34.148.116.205
accounting-service     LoadBalancer   136.108.31.44
party-service          LoadBalancer   136.108.32.59
```

Se convirtieron `accounting-service` y `party-service` a `ClusterIP`:

```powershell
kubectl apply -f .\accounting\service.yaml
kubectl apply -f .\party\service.yaml
kubectl get svc -n banquito-core
```

Resultado:

```text
account-core-service   LoadBalancer   34.148.116.205
accounting-service     ClusterIP      <none>
party-service          ClusterIP      <none>
```

`account-core-service` quedo temporalmente como `LoadBalancer` para no romper Apigee si todavia apuntaba a esa IP directa.

### Gateway GKE operativo

Despues de liberar IPs externas, el Gateway quedo programado:

```powershell
kubectl get gateway -A
```

Resultado:

```text
banquito-public-gateway   gke-l7-global-external-managed   8.233.141.65   True
```

La entrada publica correcta de GKE es:

```text
http://8.233.141.65
```

### Validacion de account-core

Se encendio solo `account-core-service`:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-core
kubectl scale deployment account-core-service --replicas=1 -n banquito-core
kubectl get pods -n banquito-core -o wide
```

Resultado:

```text
account-core-service   1/1 Running
```

Prueba directa temporal:

```powershell
curl.exe -i http://34.148.116.205:8081/actuator/health
```

Resultado:

```text
HTTP/1.1 200
status: UP
Database: PostgreSQL
```

Prueba por Gateway:

```powershell
curl.exe -i http://8.233.141.65/api/v2/accounts
```

Resultado:

```text
HTTP/1.1 404 Not Found
path: /api/v2/accounts
```

El `404` es una respuesta de Spring Boot desde el backend, por lo tanto confirma que el trafico llego a:

```text
GKE Gateway -> account-core-service
```

### Validacion de Apigee

Se probo la ruta publica:

```powershell
curl.exe -k -i https://136.68.89.25.nip.io/api/v2/accounts
```

Resultado:

```text
HTTP/1.1 401 Unauthorized
Failed to Resolve Variable : policy(Verify-OAuth2-Token) variable(request.header.Authorization)
```

Esto confirma que el request llega a Apigee y que la politica JWT se ejecuta antes de permitir acceso al backend.

Para prueba funcional completa se debe enviar:

```text
x-api-key: <api-key-de-la-aplicacion>
Authorization: Bearer <jwt-valido>
```

### Validacion del frontend

Se encendio solo `web-personas-frontend`:

```powershell
kubectl scale deployment web-personas-frontend --replicas=1 -n banquito-frontend
kubectl get pods -n banquito-frontend -o wide
```

Resultado:

```text
web-personas-frontend   1/1 Running
```

Se valido sin crear IP externa, usando `port-forward`:

```powershell
kubectl port-forward svc/web-personas-frontend 18080:8080 -n banquito-frontend
curl.exe -i http://127.0.0.1:18080/
```

Resultado:

```text
HTTP/1.1 200 OK
BanQuito Personas
```

Se reviso el bundle servido por Nginx y se encontro la URL de Apigee:

```text
136.68.89.25.nip.io
```

Esto confirma que el frontend apunta al API Manager y no a IPs internas o externas de Kubernetes.

### Estado final de la prueba

Se apagaron los deployments usados para evitar consumo:

```powershell
kubectl scale deployment account-core-service --replicas=0 -n banquito-core
kubectl scale deployment web-personas-frontend --replicas=0 -n banquito-frontend
```

Resultado:

```text
banquito-core: account-core-service 0/0
banquito-frontend: web-personas-frontend 0/0
```

### Target recomendado para Apigee

El Target Endpoint final recomendado en Apigee es:

```text
http://8.233.141.65
```

No se recomienda mantener:

```text
http://34.148.116.205:8081
```

porque esa IP pertenece al `LoadBalancer` directo de `account-core-service`.

Cuando Apigee ya apunte a `http://8.233.141.65`, se debe convertir tambien `account-core-service` a `ClusterIP`:

```powershell
kubectl apply -f .\account-core\service.yaml
kubectl get svc -n banquito-core
```

Resultado esperado:

```text
account-core-service   ClusterIP   <none>
```

### Mejora aplicada: una sola entrada publica de GKE

Fecha de aplicacion: `2026-07-17`.

Una vez confirmado que Apigee cambio su Target Endpoint hacia el Gateway:

```text
http://8.233.141.65
```

se convirtio `account-core-service` a `ClusterIP`:

```powershell
kubectl apply -f .\account-core\service.yaml
kubectl get svc -n banquito-core
```

Resultado:

```text
account-core-service   ClusterIP   <none>   8081/TCP,9091/TCP
accounting-service     ClusterIP   <none>   8082/TCP,9092/TCP
party-service          ClusterIP   <none>   8083/TCP,9093/TCP
```

Se verifico que el Gateway sigue programado:

```powershell
kubectl get gateway -A
```

Resultado:

```text
banquito-public-gateway   gke-l7-global-external-managed   8.233.141.65   True
```

Se verificaron las IPs externas activas en Google Cloud:

```powershell
gcloud compute forwarding-rules list --project project-47695a8e-7cb2-4352-af2
```

Resultado:

```text
136.68.249.209   Apigee Load Balancer
8.233.141.65     GKE Gateway
```

Ya no quedan LoadBalancers directos para microservicios Core.

Arquitectura final para Core:

```text
Frontend
  -> Apigee
      -> GKE Gateway 8.233.141.65
          -> Services ClusterIP
              -> Pods
```

Estado final de consumo:

```text
banquito-core:     0/0
banquito-frontend: 0/0
```

### Confirmacion Switch de Pagos Masivos

Switch tambien queda detras del mismo Gateway y sin LoadBalancers por microservicio.

Se verificaron sus Services:

```powershell
kubectl get svc -n banquito-switch
```

Resultado:

```text
clearinghouse-service    ClusterIP   <none>   8087/TCP
file-reception-service   ClusterIP   <none>   8084/TCP
notification-service     ClusterIP   <none>   8089/TCP,9092/TCP
report-service           ClusterIP   <none>   8088/TCP
tariff-service           ClusterIP   <none>   8086/TCP,9090/TCP
```

Se verifico que las rutas de Switch estan conectadas al mismo Gateway:

```powershell
kubectl get httproute -A
```

Resultado:

```text
banquito-core     core-routes
banquito-switch   switch-routes
```

Rutas Switch publicadas por Gateway:

```text
/api/v2/payments/batches        -> file-reception-service:8084
/api/v2/payments/routing-codes  -> file-reception-service:8084
/api/v2/tariff                  -> tariff-service:8086
/api/v2/clearing                -> clearinghouse-service:8087
/api/v2/payments/receipts       -> report-service:8088
/api/v2/reports                 -> report-service:8088
/api/v2/notifications           -> notification-service:8089
```

Arquitectura final para Core y Switch:

```text
Frontend Personas / Empresas / Teller / Operador
  -> Apigee
      -> GKE Gateway 8.233.141.65
          -> Core Services ClusterIP
          -> Switch Services ClusterIP
```

IPs externas finales verificadas:

```text
136.68.249.209   Apigee Load Balancer
8.233.141.65     GKE Gateway
```

No quedan IPs externas por microservicio de Core ni Switch.

## Configuracion final Apigee -> GKE Gateway

Fecha de verificacion: `2026-07-17`.

Se reaplicaron los manifiestos del Gateway:

```powershell
kubectl apply -f .\gateway
kubectl get gateway -A
kubectl get httproute -A
```

Resultado:

```text
banquito-public-gateway   gke-l7-global-external-managed   8.233.141.65   True
core-routes               Accepted=True, ResolvedRefs=True
switch-routes             Accepted=True, ResolvedRefs=True
```

Target Endpoint que debe usar Apigee:

```text
http://8.233.141.65
```

Apigee conserva su dominio publico:

```text
https://136.68.89.25.nip.io
```

Flujo final:

```text
Frontend
  -> https://136.68.89.25.nip.io
      -> Apigee valida x-api-key y JWT
          -> http://8.233.141.65
              -> GKE Gateway
                  -> HTTPRoute Core/Switch
                      -> Service ClusterIP
                          -> Pod
```

El Gateway no valida JWT ni API Key. Esa responsabilidad queda en Apigee. El Gateway solo enruta hacia los Services internos de Kubernetes.

### Rutas que Apigee puede exponer

Core:

```text
/api/v2/accounts
/api/v2/accounting
/api/v2/auth/login
/api/v2/customers
/api/v2/branches
/api/v2/holidays
/api/v2/calendar
/api/v2/eod
```

Switch:

```text
/api/v2/payments/batches
/api/v2/payments/routing-codes
/api/v2/tariff
/api/v2/clearing
/api/v2/payments/receipts
/api/v2/reports
/api/v2/notifications
```

### Frontend

Tambien existe una ruta frontend por el mismo Gateway:

```text
personas.8.233.141.65.nip.io -> web-personas-frontend:8080
```

Esto no crea una IP adicional. Usa la misma IP del Gateway:

```text
8.233.141.65
```

Si se decide que los frontends no deben exponerse por Gateway, se puede eliminar solo `frontend-routes` sin afectar Apigee ni las APIs:

```powershell
kubectl delete httproute frontend-routes -n banquito-frontend
```

## Validacion frontend y backend mediante Apigee

Fecha de validacion: `2026-07-17`.

Objetivo:

```text
web-personas-frontend
  -> Apigee
      -> GKE Gateway
          -> account-core-service
```

Se encendieron solo los componentes necesarios:

```powershell
kubectl scale deployment account-core-service --replicas=1 -n banquito-core
kubectl scale deployment web-personas-frontend --replicas=1 -n banquito-frontend
```

### Estado de Pods y endpoints

`web-personas-frontend` quedo listo:

```text
web-personas-frontend   1/1 Running
```

`account-core-service` quedo con al menos una replica lista:

```text
account-core-service   1/1 Running
```

Endpoint interno de Core:

```text
account-core-service   10.2.128.55:8081,10.2.128.55:9091
```

Durante esta prueba, el HPA de `account-core-service` aumento replicas porque la memoria supero el umbral:

```text
memory: 140%/80%
min 1, max 3
```

Esto confirma que HPA esta activo. Tambien explica por que pueden aparecer Pods nuevos en `Pending` mientras GKE Autopilot calcula o aprovisiona capacidad.

### Backend por Gateway

Se probo el Gateway hacia Core:

```powershell
curl.exe -i --max-time 30 http://8.233.141.65/api/v2/accounts
```

Resultado:

```text
HTTP/1.1 404 Not Found
path: /api/v2/accounts
```

El `404` viene desde Spring Boot, por lo tanto confirma:

```text
GKE Gateway -> account-core-service
```

La ruta especifica no tiene handler directo en el backend o requiere una ruta mas concreta, pero el ruteo hacia el microservicio si funciona.

### Backend mediante Apigee

Se probo Apigee sin token:

```powershell
curl.exe -k -i --max-time 30 https://136.68.89.25.nip.io/api/v2/accounts
```

Resultado:

```text
HTTP/1.1 401 Unauthorized
Failed to Resolve Variable : policy(Verify-OAuth2-Token) variable(request.header.Authorization)
```

Esto confirma:

```text
Cliente -> Apigee
Apigee ejecuta politica JWT antes de permitir acceso al backend
```

Se probo tambien con un JWT generado por Identity Platform.

Primer intento usando el formato HTTP estandar:

```text
Authorization: Bearer <jwt-valido>
```

Resultado:

```text
HTTP/1.1 401 Unauthorized
Invalid token: policy(Verify-OAuth2-Token)
```

Luego se probo enviando el token puro en el header:

```text
Authorization: <jwt-valido>
```

Resultado:

```text
HTTP/1.1 404 Not Found
path: /api/v2/accounts
```

Interpretacion:

```text
Apigee valido correctamente el JWT cuando recibio el token puro.
El request paso por Apigee y llego hasta account-core-service en GKE.
El 404 pertenece a Spring Boot, no a Apigee ni a Kubernetes.
```

Conclusion tecnica:

```text
La comunicacion Apigee -> GKE Gateway -> account-core-service esta validada.
Queda pendiente ajustar la politica de Apigee para aceptar Authorization: Bearer <token>, que es el formato esperado por frontends y clientes HTTP.
```

Para una prueba funcional completa desde frontend se debe enviar:

```text
x-api-key: <api-key-de-web-personas>
Authorization: Bearer <jwt-valido>
```

Comando esperado con credenciales reales:

```powershell
$API_KEY = "<api-key-web-personas>"
$TOKEN = "<jwt-valido>"

curl.exe -k -i `
  -H "x-api-key: $API_KEY" `
  -H "Authorization: Bearer $TOKEN" `
  https://136.68.89.25.nip.io/api/v2/accounts
```

Si Apigee mantiene la politica actual leyendo el header completo como JWT, el comando temporal de prueba debe ser:

```powershell
$TOKEN = "<jwt-valido>"

curl.exe -k -i `
  -H "Authorization: $TOKEN" `
  https://136.68.89.25.nip.io/api/v2/accounts
```

Recomendacion para Apigee:

```text
Mantener el contrato externo con Authorization: Bearer <jwt>.
Configurar la politica VerifyJWT para extraer solo el token del header Authorization.
Agregar la validacion de API Key por aplicacion consumidora.
```

### Frontend

Se valido el frontend sin crear IP externa, usando `port-forward`:

```powershell
kubectl port-forward svc/web-personas-frontend 18080:8080 -n banquito-frontend
curl.exe -i http://127.0.0.1:18080/
```

Resultado:

```text
HTTP/1.1 200 OK
BanQuito Personas
```

Se reviso el bundle servido por Nginx y se confirmo que apunta a Apigee:

```text
APIGEE_URL_FOUND_IN_FRONTEND_BUNDLE
136.68.89.25.nip.io
```

No se encontraron IPs de microservicios Kubernetes en el bundle usado por el frontend.

### Estado final

Despues de la validacion se apagaron los deployments usados:

```powershell
kubectl scale deployment account-core-service --replicas=0 -n banquito-core
kubectl scale deployment web-personas-frontend --replicas=0 -n banquito-frontend
```

Verificacion final:

```powershell
kubectl get pods -n banquito-core
kubectl get pods -n banquito-frontend
```

Resultado:

```text
No resources found in banquito-core namespace.
No resources found in banquito-frontend namespace.
```

## Validacion de frontends por Gateway

Fecha de validacion: `2026-07-20`.

Objetivo:

```text
Abrir los cuatro frontends usando una sola IP publica de GKE Gateway.
```

Se encendieron solamente los frontends:

```powershell
kubectl scale deployment web-personas-frontend --replicas=1 -n banquito-frontend
kubectl scale deployment web-empresas-frontend --replicas=1 -n banquito-frontend
kubectl scale deployment teller-frontend --replicas=1 -n banquito-frontend
kubectl scale deployment operador-frontend --replicas=1 -n banquito-frontend
kubectl get pods -n banquito-frontend
```

Resultado:

```text
operador-frontend       1/1 Running
teller-frontend         1/1 Running
web-empresas-frontend   1/1 Running
web-personas-frontend   1/1 Running
```

Se crearon rutas HTTP independientes para cada portal, todas usando el mismo Gateway:

```text
personas.8.233.141.65.nip.io  -> web-personas-frontend:8080
empresas.8.233.141.65.nip.io  -> web-empresas-frontend:8080
teller.8.233.141.65.nip.io    -> teller-frontend:8080
operador.8.233.141.65.nip.io  -> operador-frontend:8080
```

Archivo aplicado:

```text
k8s/gateway/frontend-routes.yaml
```

Comandos:

```powershell
kubectl apply -f C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s\gateway\frontend-routes.yaml
kubectl get httproute -n banquito-frontend
kubectl get svc,endpoints -n banquito-frontend -o wide
```

Pruebas HTTP:

```powershell
curl.exe --noproxy "*" -i http://personas.8.233.141.65.nip.io/
curl.exe --noproxy "*" -i http://empresas.8.233.141.65.nip.io/
curl.exe --noproxy "*" -i http://teller.8.233.141.65.nip.io/
curl.exe --noproxy "*" -i http://operador.8.233.141.65.nip.io/
```

Resultado:

```text
personas  -> HTTP/1.1 200 OK - BanQuito Personas
empresas  -> HTTP/1.1 200 OK - BanQuito Empresas
teller    -> HTTP/1.1 200 OK - BanQuito Ventanilla
operador  -> HTTP/1.1 200 OK - BanQuito Operador
```

URLs para abrir en navegador:

```text
http://personas.8.233.141.65.nip.io/
http://empresas.8.233.141.65.nip.io/
http://teller.8.233.141.65.nip.io/
http://operador.8.233.141.65.nip.io/
```

Se verifico que todos los backends del Gateway para frontend quedaron saludables:

```powershell
gcloud compute backend-services get-health <backend-service-frontend> --global --project project-47695a8e-7cb2-4352-af2
```

Resultado:

```text
web-personas-frontend   HEALTHY
web-empresas-frontend   HEALTHY
teller-frontend         HEALTHY
operador-frontend       HEALTHY
```

Revision de URLs compiladas en los bundles:

```text
web-personas-frontend: contiene https://136.68.89.25.nip.io/api/v2
web-empresas-frontend: contiene http://localhost:8000 y http://localhost:8083
teller-frontend: contiene http://localhost:8081/api/v2, http://localhost:8082/api/v2 y http://localhost:8083
operador-frontend: no muestra URL de Apigee en la extraccion simple; se debe revisar variables VITE_*
```

Conclusion:

```text
Los cuatro frontends abren correctamente por el Gateway con una sola IP publica.
Para que todas las llamadas API funcionen segun la arquitectura, Empresas, Teller y Operador deben reconstruirse con variables VITE_* apuntando a Apigee.
Personas ya contiene la URL de Apigee.
```

Comando para apagar frontends al terminar la prueba:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-frontend
```

