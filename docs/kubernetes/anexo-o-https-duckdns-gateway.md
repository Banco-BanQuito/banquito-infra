# Anexo O - HTTPS para frontends con DuckDNS y GKE Gateway

## Objetivo

Habilitar acceso HTTPS para los cuatro frontends publicados por el Gateway de GKE, usando dominios gratuitos de DuckDNS y un certificado SSL administrado por Google Cloud.

La motivacion es mejorar compatibilidad con navegadores moviles y evitar advertencias de sitio no seguro al acceder desde celular.

## Estado inicial

Los frontends estaban publicados por HTTP usando dominios temporales `nip.io`:

```text
http://personas.8.233.141.65.nip.io
http://empresas.8.233.141.65.nip.io
http://teller.8.233.141.65.nip.io
http://operador.8.233.141.65.nip.io
```

Gateway actual:

```text
Gateway: banquito-public-gateway
Namespace: banquito-gateway
GatewayClass: gke-l7-global-external-managed
IP publica: 8.233.141.65
Listener actual: HTTP puerto 80
```

El manifiesto actual solo expone HTTP:

```yaml
listeners:
  - name: http
    protocol: HTTP
    port: 80
```

## Dominios DuckDNS creados

Se definieron cuatro subdominios DuckDNS, uno por frontend:

| Frontend | Dominio HTTPS propuesto |
| --- | --- |
| Banca Personas | `banquito-personas.duckdns.org` |
| Banca Empresas | `banquito-empresas.duckdns.org` |
| Ventanilla | `banquito-teller.duckdns.org` |
| Operador | `banquito-operador.duckdns.org` |

Todos apuntan a la misma IP publica del Gateway:

```text
8.233.141.65
```

## Validacion DNS

Comandos ejecutados desde Windows 11:

```powershell
nslookup banquito-personas.duckdns.org
nslookup banquito-empresas.duckdns.org
nslookup banquito-teller.duckdns.org
nslookup banquito-operador.duckdns.org
```

Resultado observado:

```text
banquito-personas.duckdns.org   Address: 8.233.141.65
banquito-empresas.duckdns.org   Address: 8.233.141.65
banquito-teller.duckdns.org     Address: 8.233.141.65
banquito-operador.duckdns.org   Address: 8.233.141.65
```

## Certificado SSL administrado por Google

Se creo un certificado SSL global administrado por Google Cloud.

Primer intento fallido:

```powershell
gcloud compute ssl-certificates create banquito-frontends-cert `
  --domains=banquito-personas.duckdns.org,banquito-empresas.duckdns.org,banquito-teller.duckdns.org,banquito-operador.duckdns.org `
  --global
```

Error:

```text
Invalid domain name specified.
```

Causa:

```text
PowerShell envio los dominios como un solo texto con espacios.
```

Comando corregido:

```powershell
gcloud compute ssl-certificates create banquito-frontends-cert `
  --domains="banquito-personas.duckdns.org,banquito-empresas.duckdns.org,banquito-teller.duckdns.org,banquito-operador.duckdns.org" `
  --global
```

Validacion de certificados existentes:

```powershell
gcloud compute ssl-certificates list
```

Resultado relevante:

```text
NAME: apigee-ssl-cert-hqfqi79e8qky
TYPE: MANAGED
MANAGED_STATUS: ACTIVE
136.68.249.209.nip.io: ACTIVE
```

Luego se creo correctamente:

```text
name: banquito-frontends-cert
type: MANAGED
status: PROVISIONING
```

## Estado final del certificado

Comando:

```powershell
gcloud compute ssl-certificates describe banquito-frontends-cert --global --format="yaml(managed)"
```

Estado final observado:

```yaml
managed:
  domainStatus:
    banquito-empresas.duckdns.org: ACTIVE
    banquito-operador.duckdns.org: ACTIVE
    banquito-personas.duckdns.org: ACTIVE
    banquito-teller.duckdns.org: ACTIVE
  status: ACTIVE
```

Interpretacion:

```text
El certificado administrado por Google ya fue validado correctamente para los cuatro dominios.
Los frontends ya pueden ser consumidos por HTTPS.
```

Tiempo esperado:

```text
Normal: 10 a 60 minutos.
Puede tardar hasta 24 horas en casos excepcionales.
```

Durante la fase `PROVISIONING` se mantuvo esta regla:

```text
No cambiar la IP 8.233.141.65.
No borrar el Gateway.
No borrar el certificado.
No cambiar los registros DuckDNS.
No reemplazar HTTP como unica entrada.
```

## Correccion de FAILED_NOT_VISIBLE

Durante la validacion, el certificado paso a:

```yaml
managed:
  domainStatus:
    banquito-empresas.duckdns.org: FAILED_NOT_VISIBLE
    banquito-operador.duckdns.org: FAILED_NOT_VISIBLE
    banquito-personas.duckdns.org: FAILED_NOT_VISIBLE
    banquito-teller.duckdns.org: FAILED_NOT_VISIBLE
  status: PROVISIONING
```

Interpretacion:

```text
Los dominios resolvian por DNS, pero Google todavia no veia esos hostnames servidos por el Load Balancer/Gateway.
El certificado estaba creado, pero aun no estaba adjunto al listener HTTPS del Gateway.
```

Se aplicaron tres cambios:

1. Agregar listener HTTPS al Gateway.
2. Agregar hostnames DuckDNS a las rutas de frontend.
3. Agregar los origenes HTTPS DuckDNS al ConfigMap CORS.

Archivos modificados:

```text
banquito-infra/k8s/gateway/gateway.yaml
banquito-infra/k8s/gateway/frontend-routes.yaml
banquito-infra/k8s/configmap.yaml
```

Comandos aplicados:

```powershell
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\gateway\gateway.yaml
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\gateway\frontend-routes.yaml
kubectl --insecure-skip-tls-verify=true apply -f banquito-infra\k8s\configmap.yaml
```

Validacion del Gateway:

```powershell
kubectl --insecure-skip-tls-verify=true describe gateway banquito-public-gateway -n banquito-gateway
```

Resultado relevante:

```text
Listener http:  Accepted=True, ResolvedRefs=True
Listener https: Accepted=True, ResolvedRefs=True
SYNC on banquito-gateway/banquito-public-gateway was a success
```

Validacion del HTTPS proxy:

```powershell
gcloud compute target-https-proxies list --global --format="table(name,sslCertificates)"
```

Resultado:

```text
NAME: gkegw1-svax-banquito-gateway-banquito-public-gatew-10e1mt7cutao
SSL_CERTIFICATES: banquito-frontends-cert
```

Conclusion:

```text
El certificado ya esta asociado al HTTPS proxy del Gateway.
Google ya revalido los dominios y el certificado quedo ACTIVE.
```

## Comando de seguimiento

Revisar cada 5 minutos:

```powershell
gcloud compute ssl-certificates describe banquito-frontends-cert --global --format="yaml(managed.status,managed.domainStatus)"
```

Estado esperado y confirmado:

```text
managed.status: ACTIVE
```

## Cambio aplicado en Gateway

Se agrego un listener HTTPS al Gateway.

Archivo:

```text
banquito-infra/k8s/gateway/gateway.yaml
```

Configuracion esperada:

```yaml
apiVersion: gateway.networking.k8s.io/v1
kind: Gateway
metadata:
  name: banquito-public-gateway
  namespace: banquito-gateway
spec:
  gatewayClassName: gke-l7-global-external-managed
  listeners:
    - name: http
      protocol: HTTP
      port: 80
      allowedRoutes:
        namespaces:
          from: All
    - name: https
      protocol: HTTPS
      port: 443
      tls:
        mode: Terminate
        options:
          networking.gke.io/pre-shared-certs: banquito-frontends-cert
      allowedRoutes:
        namespaces:
          from: All
```

Se conserva HTTP durante la transicion para no romper acceso, pero las URLs recomendadas para pruebas finales son las HTTPS.

## Cambio aplicado en rutas frontend

Archivo:

```text
banquito-infra/k8s/gateway/frontend-routes.yaml
```

Se agregaron los hostnames DuckDNS manteniendo tambien los hostnames `nip.io`:

```yaml
hostnames:
  - personas.8.233.141.65.nip.io
  - banquito-personas.duckdns.org
```

```yaml
hostnames:
  - empresas.8.233.141.65.nip.io
  - banquito-empresas.duckdns.org
```

```yaml
hostnames:
  - teller.8.233.141.65.nip.io
  - banquito-teller.duckdns.org
```

```yaml
hostnames:
  - operador.8.233.141.65.nip.io
  - banquito-operador.duckdns.org
```

## Aplicacion realizada

```powershell
kubectl --insecure-skip-tls-verify=true apply -f C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s\gateway\gateway.yaml
kubectl --insecure-skip-tls-verify=true apply -f C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s\gateway\frontend-routes.yaml
kubectl --insecure-skip-tls-verify=true apply -f C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s\configmap.yaml
```

Verificar:

```powershell
kubectl get gateway -n banquito-gateway
kubectl get httproute -n banquito-frontend
```

Probar HTTPS:

```powershell
curl.exe -I https://banquito-personas.duckdns.org
curl.exe -I https://banquito-empresas.duckdns.org
curl.exe -I https://banquito-teller.duckdns.org
curl.exe -I https://banquito-operador.duckdns.org
```

## Ajuste aplicado de CORS

Se agregaron estos origenes al `CORS_ALLOWED_ORIGINS`:

```text
https://banquito-personas.duckdns.org
https://banquito-empresas.duckdns.org
https://banquito-teller.duckdns.org
https://banquito-operador.duckdns.org
```

Archivo:

```text
banquito-infra/k8s/configmap.yaml
```

Aplicar:

```powershell
kubectl --insecure-skip-tls-verify=true apply -f C:\Users\User\Desktop\KUBERNETS-PROYECTO\banquito-infra\k8s\configmap.yaml
kubectl rollout restart deployment account-core-service -n banquito-core
kubectl rollout restart deployment file-reception-service -n banquito-switch
```

Nota:

```text
Los cambios de ConfigMap no se inyectan automaticamente en pods ya levantados.
Si un backend valida CORS desde variables de entorno, se debe reiniciar su Deployment.
```

## Validacion HTTPS

Comando ejecutado desde Windows 11:

```powershell
$urls = @(
  "https://banquito-personas.duckdns.org",
  "https://banquito-empresas.duckdns.org",
  "https://banquito-teller.duckdns.org",
  "https://banquito-operador.duckdns.org"
)

foreach ($u in $urls) {
  try {
    $r = Invoke-WebRequest -Uri $u -Method Head -UseBasicParsing -TimeoutSec 20
    "$u -> $($r.StatusCode) $($r.StatusDescription)"
  } catch {
    "$u -> ERROR $($_.Exception.Message)"
  }
}
```

Resultado:

```text
https://banquito-personas.duckdns.org -> 200 OK
https://banquito-empresas.duckdns.org -> 200 OK
https://banquito-teller.duckdns.org -> 200 OK
https://banquito-operador.duckdns.org -> 200 OK
```

## Correccion de CORS en account-core

Problema observado desde `web-personas`:

```text
GET https://136.68.89.25.nip.io/api/v2/customers/1750285577
Status Code: 403 Forbidden
Origin: https://banquito-personas.duckdns.org
Respuesta: Invalid CORS request
```

Causa:

```text
El ConfigMap ya tenia los origenes HTTPS DuckDNS, pero el pod de account-core habia arrancado antes del cambio.
Los ConfigMaps inyectados como variables de entorno solo se cargan al iniciar el contenedor.
```

Validacion dentro del pod antes del reinicio:

```powershell
kubectl --insecure-skip-tls-verify=true exec -n banquito-core account-core-service-f75d5df48-4ggl6 -- printenv CORS_ALLOWED_ORIGINS
```

Resultado anterior:

```text
http://personas.8.233.141.65.nip.io,http://empresas.8.233.141.65.nip.io,http://teller.8.233.141.65.nip.io,http://operador.8.233.141.65.nip.io,https://136.68.89.25.nip.io
```

Correccion aplicada:

```powershell
kubectl --insecure-skip-tls-verify=true rollout restart deployment account-core-service -n banquito-core
kubectl --insecure-skip-tls-verify=true rollout status deployment account-core-service -n banquito-core --timeout=180s
```

Validacion del pod nuevo:

```powershell
kubectl --insecure-skip-tls-verify=true get pods -n banquito-core -l app=account-core -o wide
kubectl --insecure-skip-tls-verify=true exec -n banquito-core account-core-service-76f5d67668-6rdv9 -- printenv CORS_ALLOWED_ORIGINS
```

Resultado actualizado:

```text
http://personas.8.233.141.65.nip.io,http://empresas.8.233.141.65.nip.io,http://teller.8.233.141.65.nip.io,http://operador.8.233.141.65.nip.io,https://banquito-personas.duckdns.org,https://banquito-empresas.duckdns.org,https://banquito-teller.duckdns.org,https://banquito-operador.duckdns.org,https://136.68.89.25.nip.io
```

Estado final:

```text
account-core-service-76f5d67668-6rdv9   1/1   Running
```

Conclusion:

```text
El 403 Invalid CORS request se debia a un pod con variables CORS antiguas.
El backend ya tiene los origenes HTTPS DuckDNS cargados.
```

## URLs finales esperadas

```text
https://banquito-personas.duckdns.org
https://banquito-empresas.duckdns.org
https://banquito-teller.duckdns.org
https://banquito-operador.duckdns.org
```

## Nota de costos

El certificado administrado por Google no es normalmente el principal costo. Los costos relevantes son:

```text
GKE Gateway / Load Balancer
IP publica
trafico de salida
dominio, si se compra uno
```

DuckDNS evita comprar dominio, pero para una entrega formal de produccion se recomienda dominio propio.
