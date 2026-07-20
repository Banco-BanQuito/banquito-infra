# Anexo L - Validacion de frontends por GKE Gateway

## Objetivo

Validar que los cuatro frontends de BanQuito puedan abrirse desde navegador usando una sola entrada publica en Google Kubernetes Engine.

La entrada publica usada es el Gateway de GKE:

```text
Gateway: banquito-public-gateway
Namespace: banquito-gateway
IP publica: 8.233.141.65
```

## Arquitectura validada

```text
Usuario
  -> GKE Gateway 8.233.141.65
      -> HTTPRoute por hostname
          -> Service ClusterIP
              -> Pod frontend
```

No se crearon LoadBalancers por frontend. Todos usan la misma IP publica del Gateway.

## Frontends publicados

| Frontend | URL publica | Service interno |
| --- | --- | --- |
| Banca Personas | `http://personas.8.233.141.65.nip.io/` | `web-personas-frontend:8080` |
| Banca Empresas | `http://empresas.8.233.141.65.nip.io/` | `web-empresas-frontend:8080` |
| Ventanilla | `http://teller.8.233.141.65.nip.io/` | `teller-frontend:8080` |
| Operador | `http://operador.8.233.141.65.nip.io/` | `operador-frontend:8080` |

## Manifiesto usado

Archivo:

```text
k8s/gateway/frontend-routes.yaml
```

Contiene cuatro `HTTPRoute`, uno por frontend:

```text
personas-frontend-route
empresas-frontend-route
teller-frontend-route
operador-frontend-route
```

## Comandos ejecutados

Encender frontends:

```powershell
kubectl scale deployment web-personas-frontend --replicas=1 -n banquito-frontend
kubectl scale deployment web-empresas-frontend --replicas=1 -n banquito-frontend
kubectl scale deployment teller-frontend --replicas=1 -n banquito-frontend
kubectl scale deployment operador-frontend --replicas=1 -n banquito-frontend
```

Aplicar rutas:

```powershell
kubectl apply -f C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s\gateway\frontend-routes.yaml
```

Verificar estado:

```powershell
kubectl get gateway -A -o wide
kubectl get httproute -n banquito-frontend
kubectl get deployments -n banquito-frontend
kubectl get pods -n banquito-frontend
kubectl get svc,endpoints -n banquito-frontend -o wide
```

Probar apertura HTTP:

```powershell
curl.exe --noproxy "*" -i http://personas.8.233.141.65.nip.io/
curl.exe --noproxy "*" -i http://empresas.8.233.141.65.nip.io/
curl.exe --noproxy "*" -i http://teller.8.233.141.65.nip.io/
curl.exe --noproxy "*" -i http://operador.8.233.141.65.nip.io/
```

## Resultado de Pods

```text
operador-frontend       1/1 Running
teller-frontend         1/1 Running
web-empresas-frontend   1/1 Running
web-personas-frontend   1/1 Running
```

## Resultado HTTP

| URL | Resultado |
| --- | --- |
| `http://personas.8.233.141.65.nip.io/` | `HTTP/1.1 200 OK` |
| `http://empresas.8.233.141.65.nip.io/` | `HTTP/1.1 200 OK` |
| `http://teller.8.233.141.65.nip.io/` | `HTTP/1.1 200 OK` |
| `http://operador.8.233.141.65.nip.io/` | `HTTP/1.1 200 OK` |

## Health checks del Gateway

Se verifico que los backend services generados por el Gateway para los frontends estaban saludables:

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

## Revision de URLs compiladas

Se revisaron los bundles JavaScript servidos por Nginx para identificar a donde apuntan las llamadas API.

Resultado encontrado:

| Frontend | Estado de URL API |
| --- | --- |
| Banca Personas | Correcto: contiene `https://136.68.89.25.nip.io/api/v2` |
| Banca Empresas | Pendiente: contiene `http://localhost:8000` y `http://localhost:8083` |
| Ventanilla | Pendiente: contiene `http://localhost:8081/api/v2`, `http://localhost:8082/api/v2` y `http://localhost:8083` |
| Operador | Pendiente de revisar variables `VITE_*` antes de reconstruir imagen |

## Interpretacion

La publicacion web esta correcta:

```text
Gateway -> Service ClusterIP -> Pod frontend
```

Pero la comunicacion API desde todos los frontends aun no esta completa, porque algunos bundles fueron construidos con URLs locales.

Para cumplir la arquitectura final, los frontends deben llamar a Apigee:

```text
Frontend
  -> Apigee https://136.68.89.25.nip.io
      -> GKE Gateway http://8.233.141.65
          -> Backends Core/Switch
```

## Mejora pendiente

Reconstruir las imagenes de:

```text
banquito-web-empresas-frontend
banquito-teller-frontend
banquito-frontend-web-operador
```

con variables de entorno de build apuntando a Apigee.

Ejemplo esperado:

```text
VITE_API_BASE_URL=https://136.68.89.25.nip.io/api/v2
VITE_APIGEE_BASE_URL=https://136.68.89.25.nip.io/api/v2
```

El nombre exacto de cada variable debe salir del codigo de cada frontend.

## Apagar frontends para evitar consumo

Cuando termine la prueba:

```powershell
kubectl scale deployment --all --replicas=0 -n banquito-frontend
kubectl get pods -n banquito-frontend
```

Resultado esperado:

```text
No resources found in banquito-frontend namespace.
```

## Validacion integral frontend, Apigee y backend

Fecha de validacion: `2026-07-20`.

Objetivo:

```text
Validar el flujo:

Frontend
  -> Apigee
      -> GKE Gateway
          -> account-core-service
```

### Estado de frontends

Comando:

```powershell
kubectl get pods -n banquito-frontend
```

Resultado:

```text
operador-frontend        1/1 Running
teller-frontend          1/1 Running
web-empresas-frontend    1/1 Running
web-personas-frontend    1/1 Running
```

Pruebas:

```powershell
curl.exe --noproxy "*" -s -o NUL -w "personas HTTP %{http_code}`n" http://personas.8.233.141.65.nip.io/
curl.exe --noproxy "*" -s -o NUL -w "empresas HTTP %{http_code}`n" http://empresas.8.233.141.65.nip.io/
curl.exe --noproxy "*" -s -o NUL -w "teller HTTP %{http_code}`n" http://teller.8.233.141.65.nip.io/
curl.exe --noproxy "*" -s -o NUL -w "operador HTTP %{http_code}`n" http://operador.8.233.141.65.nip.io/
```

Resultado:

```text
personas HTTP 200
empresas HTTP 200
teller HTTP 200
operador HTTP 200
```

### Estado de backend Core

Se encendio solo `account-core-service`:

```powershell
kubectl scale deployment account-core-service --replicas=1 -n banquito-core
kubectl rollout status deployment/account-core-service -n banquito-core --timeout=180s
kubectl get pods -n banquito-core -o wide
```

Resultado:

```text
account-core-service   1/1 Running
```

Logs relevantes:

```text
Tomcat started on port 8081
HikariPool-1 - Start completed
Database JDBC URL: jdbc:postgresql://136.112.87.173:5432/banquito?currentSchema=account_core
Default catalog/schema: banquito/account_core
```

Esto confirma que el microservicio inicio correctamente y conecto con PostgreSQL.

### Gateway hacia backend

Prueba:

```powershell
curl.exe --noproxy "*" -i --max-time 30 http://8.233.141.65/api/v2/accounts
```

Resultado:

```text
HTTP/1.1 404 Not Found
path: /api/v2/accounts
```

Interpretacion:

```text
El 404 viene desde Spring Boot, por lo tanto el Gateway si llego al backend.
La ruta base /api/v2/accounts no tiene handler directo o requiere una ruta mas especifica.
```

### Apigee sin token

Prueba:

```text
GET https://136.68.89.25.nip.io/api/v2/accounts
```

Resultado:

```text
HTTP/1.1 401 Unauthorized
Failed to Resolve Variable : policy(Verify-OAuth2-Token) variable(request.header.Authorization)
```

Interpretacion:

```text
Apigee esta activo y ejecuta la politica JWT antes de permitir acceso al backend.
Esto valida la capa de seguridad de entrada.
```

### IPs publicas actuales

Comando:

```powershell
gcloud compute forwarding-rules list --project project-47695a8e-7cb2-4352-af2
```

Resultado:

```text
Apigee Load Balancer: 136.68.249.209
GKE Gateway:          8.233.141.65
```

Nota:

```text
El dominio documentado de Apigee es https://136.68.89.25.nip.io.
Ese dominio resolvio a 136.68.89.25 y respondio 401 correctamente.
La IP 136.68.249.209 pertenece a otro forwarding rule de Apigee y respondio 503 durante esta prueba.
```

### Pendiente para prueba autenticada completa

No se pudo generar un JWT fresco desde esta maquina durante la prueba porque Identity Platform corto la conexion local.

Para completar la prueba autenticada, ejecutar desde una maquina que pueda generar el token:

```powershell
$TOKEN = "<jwt-valido>"
$API_KEY = "<api-key-de-la-aplicacion>"

curl.exe -k -i `
  -H "x-api-key: $API_KEY" `
  -H "Authorization: Bearer $TOKEN" `
  https://136.68.89.25.nip.io/api/v2/accounts
```

Resultado esperado si Apigee esta configurado con formato estandar:

```text
Apigee valida x-api-key y JWT.
La peticion llega a GKE Gateway.
El backend responde con el resultado de Spring Boot.
```

Si la politica de Apigee todavia espera el token puro en el header `Authorization`, probar temporalmente:

```powershell
curl.exe -k -i `
  -H "Authorization: $TOKEN" `
  https://136.68.89.25.nip.io/api/v2/accounts
```

Recomendacion:

```text
Corregir Apigee para aceptar Authorization: Bearer <token>, porque ese es el contrato HTTP esperado por frontends y clientes.
```
