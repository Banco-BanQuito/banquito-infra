# Comunicacion Frontends -> API Manager -> Backends

## Decision de arquitectura

Los frontends no deben llamar directamente a los microservicios internos de Kubernetes.

La comunicacion recomendada es:

```text
Usuario
  -> Frontend
  -> API Manager
  -> Backend expuesto
  -> Servicios internos Kubernetes / bases / RabbitMQ
```

En BanQuito:

```text
banquito-frontend
  teller-frontend
  web-personas-frontend
  web-empresas-frontend
  operador-frontend

API Manager
  rutas publicas y controladas

banquito-core
  account-core-service
  accounting-service
  party-service

banquito-switch
  file-reception-service
  tariff-service
  clearinghouse-service
  report-service
  notification-service
```

## Que debe pasar por API Manager

Debe pasar por API Manager:

```text
Frontend -> Core Bancario
Frontend -> Switch de Pagos Masivos
Integraciones externas
Validacion de token OAuth/JWT
Rate limiting
Auditoria
Rutas publicas
```

No necesariamente debe pasar por API Manager:

```text
Llamadas internas tecnicas entre microservicios dentro del mismo cluster
gRPC interno entre servicios
Comunicacion directa con bases administradas
Mensajeria RabbitMQ
```

## Flujo objetivo

```text
web-personas-frontend
  -> https://api.banquito.com/personas
  -> API Manager
  -> account-core-service.banquito-core.svc.cluster.local:8081

web-empresas-frontend
  -> https://api.banquito.com/empresas
  -> API Manager
  -> file-reception-service.banquito-switch.svc.cluster.local:8084

teller-frontend
  -> https://api.banquito.com/teller
  -> API Manager
  -> account-core-service / party-service / accounting-service

operador-frontend
  -> https://api.banquito.com/operador
  -> API Manager
  -> report-service / clearinghouse-service / notification-service
```

## Rutas sugeridas en API Manager

### Core Bancario

```text
GET/POST/PUT/DELETE /core/accounts/**
  -> account-core-service.banquito-core.svc.cluster.local:8081

GET/POST/PUT/DELETE /core/accounting/**
  -> accounting-service.banquito-core.svc.cluster.local:8082

GET/POST/PUT/DELETE /core/parties/**
  -> party-service.banquito-core.svc.cluster.local:8083
```

### Switch de Pagos Masivos

```text
GET/POST/PUT/DELETE /switch/files/**
  -> file-reception-service.banquito-switch.svc.cluster.local:8084

GET/POST/PUT/DELETE /switch/tariffs/**
  -> tariff-service.banquito-switch.svc.cluster.local:8086

GET/POST/PUT/DELETE /switch/clearing/**
  -> clearinghouse-service.banquito-switch.svc.cluster.local:8087

GET/POST/PUT/DELETE /switch/reports/**
  -> report-service.banquito-switch.svc.cluster.local:8088

GET/POST/PUT/DELETE /switch/notifications/**
  -> notification-service.banquito-switch.svc.cluster.local:8089
```

## Variables que deben usar los frontends

Los frontends Vite normalmente leen variables en build time.

Ejemplo recomendado:

```text
VITE_API_MANAGER_URL=https://api.banquito.com
VITE_CORE_API_URL=https://api.banquito.com/core
VITE_SWITCH_API_URL=https://api.banquito.com/switch
VITE_OAUTH_URL=https://oauth.banquito.com
```

No usar:

```text
http://account-core-service:8081
http://file-reception-service:8084
http://localhost:8081
```

Los frontends deben apuntar al API Manager:

```text
https://api.banquito.com/core
https://api.banquito.com/switch
```

## ConfigMap actual

El `ConfigMap` ya tiene placeholders para API Manager:

```yaml
API_MANAGER_URL: https://api.example.com
CORE_GATEWAY_URL: https://api.example.com/core
SWITCH_GATEWAY_URL: https://api.example.com/switch
OAUTH_URL: https://oauth.example.com
```

Cuando exista el endpoint real del API Manager, actualizar:

```yaml
API_MANAGER_URL: https://api.banquito.com
CORE_GATEWAY_URL: https://api.banquito.com/core
SWITCH_GATEWAY_URL: https://api.banquito.com/switch
OAUTH_URL: https://oauth.banquito.com
```

Archivo:

```text
banquito-infra/k8s/configmap.yaml
```

Aplicar:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s
kubectl apply -f configmap.yaml
```

Reiniciar frontends:

```powershell
kubectl rollout restart deployment/teller-frontend -n banquito-frontend
kubectl rollout restart deployment/web-personas-frontend -n banquito-frontend
kubectl rollout restart deployment/web-empresas-frontend -n banquito-frontend
kubectl rollout restart deployment/operador-frontend -n banquito-frontend
```

## Importante para Vite

Si los frontends usan `VITE_*`, esas variables se resuelven al construir la imagen.

Entonces, si cambias:

```text
VITE_API_MANAGER_URL
VITE_CORE_API_URL
VITE_SWITCH_API_URL
```

probablemente debes reconstruir la imagen Docker del frontend.

Ejemplo `web-personas-frontend`:

```powershell
cd C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-web-personas-frontend

docker build `
  --build-arg VITE_API_MANAGER_URL=https://api.banquito.com `
  --build-arg VITE_CORE_API_URL=https://api.banquito.com/core `
  --build-arg VITE_SWITCH_API_URL=https://api.banquito.com/switch `
  -t us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest .

docker push us-central1-docker.pkg.dev/project-47695a8e-7cb2-4352-af2/banquito/web-personas-frontend:latest
kubectl rollout restart deployment/web-personas-frontend -n banquito-frontend
```

Si el Dockerfile no acepta `ARG`, se debe agregar algo como:

```dockerfile
ARG VITE_API_MANAGER_URL
ARG VITE_CORE_API_URL
ARG VITE_SWITCH_API_URL

ENV VITE_API_MANAGER_URL=$VITE_API_MANAGER_URL
ENV VITE_CORE_API_URL=$VITE_CORE_API_URL
ENV VITE_SWITCH_API_URL=$VITE_SWITCH_API_URL
```

antes de ejecutar:

```dockerfile
RUN npm run build
```

## Opcion recomendada para frontends

Para evitar reconstruir imagen cada vez que cambia el endpoint, se recomienda configuracion runtime con Nginx.

Patron:

```text
1. El contenedor sirve un archivo /config.js.
2. Kubernetes inyecta variables en ese archivo al iniciar.
3. El frontend lee window.__APP_CONFIG__.
```

Ejemplo de `config.js` generado:

```javascript
window.__APP_CONFIG__ = {
  API_MANAGER_URL: "https://api.banquito.com",
  CORE_API_URL: "https://api.banquito.com/core",
  SWITCH_API_URL: "https://api.banquito.com/switch",
  OAUTH_URL: "https://oauth.banquito.com"
};
```

Esto es mas flexible para ambientes `dev`, `qa` y `prod`.

Para la entrega universitaria, es aceptable reconstruir los frontends con `VITE_*`.

## API Manager dentro o fuera del cluster

Segun el requisito del proyecto, API Manager es un servicio de nube.

Por tanto:

```text
No se despliega Kong como contenedor dentro de GKE para la entrega final.
Se usa Apigee, API Gateway u otro servicio administrado.
```

Si se usa Google API Gateway:

```text
Frontend -> API Gateway -> Backend HTTP expuesto
```

Si se usa Apigee:

```text
Frontend -> Apigee -> Backend HTTP expuesto
```

## Como llega API Manager a los backends en GKE

El API Manager necesita llegar a los backends por una entrada HTTP estable.

Opciones:

```text
Opcion A: Ingress/Gateway de GKE con rutas internas hacia Services.
Opcion B: Services tipo LoadBalancer por dominio, no recomendado para tantos servicios.
Opcion C: Un backend facade/BFF por dominio, recomendado en sistemas mas maduros.
```

Para este proyecto:

```text
Usar un Ingress/Gateway de GKE como entrada tecnica.
API Manager apunta a ese endpoint.
El Ingress enruta hacia Services internos.
```

Flujo:

```text
Frontend
  -> API Manager publico
  -> Ingress/Gateway GKE
  -> Service Kubernetes
  -> Pod backend
```

## Ejemplo conceptual de rutas del Ingress

```text
/core/accounts      -> account-core-service:8081
/core/accounting    -> accounting-service:8082
/core/parties       -> party-service:8083
/switch/files       -> file-reception-service:8084
/switch/tariffs     -> tariff-service:8086
/switch/reports     -> report-service:8088
```

Nota:

```text
El Ingress real depende del dominio, certificado TLS y servicio API Manager seleccionado.
```

## Seguridad

El frontend debe enviar token:

```text
Authorization: Bearer <access_token>
```

El API Manager debe validar:

```text
JWT / OAuth
issuer
audience
expiracion
permisos
rate limit
```

Los backends pueden validar el token tambien si se requiere defensa en profundidad.

## CORS

El API Manager debe permitir los origenes reales de los frontends:

```text
https://personas.banquito.com
https://empresas.banquito.com
https://teller.banquito.com
https://operador.banquito.com
```

Durante demo se puede usar un origen temporal, pero no usar `*` en produccion.

## Comandos utiles

Ver frontends:

```powershell
kubectl get pods -n banquito-frontend
kubectl get svc -n banquito-frontend
```

Ver backends:

```powershell
kubectl get pods -n banquito-core
kubectl get pods -n banquito-switch
kubectl get svc -n banquito-core
kubectl get svc -n banquito-switch
```

Ver ConfigMap:

```powershell
kubectl get configmap banquito-config -n banquito-frontend -o yaml
kubectl get configmap banquito-config -n banquito-core -o yaml
kubectl get configmap banquito-config -n banquito-switch -o yaml
```

Reiniciar frontends:

```powershell
kubectl rollout restart deployment/teller-frontend -n banquito-frontend
kubectl rollout restart deployment/web-personas-frontend -n banquito-frontend
kubectl rollout restart deployment/web-empresas-frontend -n banquito-frontend
kubectl rollout restart deployment/operador-frontend -n banquito-frontend
```

Ver rollout:

```powershell
kubectl rollout status deployment/teller-frontend -n banquito-frontend
kubectl rollout status deployment/web-personas-frontend -n banquito-frontend
kubectl rollout status deployment/web-empresas-frontend -n banquito-frontend
kubectl rollout status deployment/operador-frontend -n banquito-frontend
```

## Frase para defensa

```text
Los frontends no consumen directamente los Services internos de Kubernetes. Todos los accesos frontend-backend pasan por el API Manager, que centraliza autenticacion, autorizacion, rate limiting, auditoria y gobierno de APIs. Los microservicios se mantienen privados dentro del cluster y se exponen de forma controlada mediante Ingress/Gateway hacia el API Manager.
```
