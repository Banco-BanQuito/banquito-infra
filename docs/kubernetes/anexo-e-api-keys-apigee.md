# Anexo E - API Keys por aplicacion en Apigee

## Requisito

Cada aplicacion que llame APIs expuestas en el API Manager debe tener su propia API Key.

Esto aplica a:

```text
teller-frontend
web-personas-frontend
web-empresas-frontend
operador-frontend
```

## Objetivo de la API Key

La API Key identifica la aplicacion cliente ante Apigee.

No reemplaza el token OAuth/JWT del usuario.

El flujo correcto es:

```text
Frontend
  -> envia API Key de la aplicacion
  -> envia Authorization: Bearer <token>
  -> Apigee valida API Key
  -> Apigee valida JWT
  -> Apigee enruta hacia GKE
```

## Matriz de aplicaciones

| Aplicacion | Namespace | API Key requerida | Uso |
| --- | --- | --- | --- |
| Teller Frontend | `banquito-frontend` | Si | Ventanilla |
| Web Personas Frontend | `banquito-frontend` | Si | Banca Personas |
| Web Empresas Frontend | `banquito-frontend` | Si | Banca Empresas |
| Operador Frontend | `banquito-frontend` | Si | Operador |

## Configuracion esperada en Apigee

En Apigee se debe crear:

```text
1. API Product para Core/Switch.
2. Developer App por frontend.
3. Consumer Key/API Key por Developer App.
4. Politica VerifyAPIKey en los proxies.
5. Politica VerifyJWT para tokens de usuario.
```

## Header recomendado

El frontend puede enviar la API Key en un header:

```text
x-api-key: <api-key-de-la-aplicacion>
Authorization: Bearer <jwt-del-usuario>
```

Tambien Apigee permite query param, pero no se recomienda para frontends:

```text
?apikey=<api-key>
```

## Variables por frontend

Como los frontends usan Vite, la API Key podria configurarse como:

```text
VITE_APIGEE_API_KEY=<api-key-de-la-app>
```

Advertencia:

```text
En aplicaciones frontend, cualquier API Key incluida en el build puede ser visible en el navegador.
Por eso la API Key identifica la aplicacion, pero no debe considerarse un secreto fuerte.
La proteccion real de usuario debe hacerse con OAuth/JWT.
```

## Politica Apigee conceptual

```xml
<VerifyAPIKey name="Verify-API-Key">
  <APIKey ref="request.header.x-api-key"/>
</VerifyAPIKey>
```

Luego se aplica JWT:

```xml
<VerifyJWT name="Verify-OAuth2-Token">
  <Source>request.header.Authorization</Source>
  <Algorithm>RS256</Algorithm>
  <PublicKey>
    <JWKS uri="https://www.googleapis.com/service_accounts/v1/jwk/securetoken@system.gserviceaccount.com"/>
  </PublicKey>
  <Issuer>https://securetoken.google.com/project-47695a8e-7cb2-4352-af2</Issuer>
  <Audience>project-47695a8e-7cb2-4352-af2</Audience>
</VerifyJWT>
```

## Entregable

Para evidenciar el requisito:

```text
Cada frontend debe tener una Developer App distinta en Apigee.
Cada Developer App debe tener su propia API Key.
Los proxies deben validar x-api-key.
Las rutas privadas tambien deben validar JWT.
```
