# 0021. Google Identity Platform como servicio de OAuth2/OIDC en la nube

## Estado
Aceptado — supersede a ADR-0004

## Contexto
El proyecto exige OAuth2 como servicio de nube, integrado al API Manager, sin ser autoimplementado ni corriendo dentro de Kubernetes.

## Decisión
Identity Platform (Google Cloud), proveedor Email/Password, con email sintético `<identificación>@banquito.internal` para mapear cédula/RUC/username (identificador de negocio real) al formato de email que Identity Platform exige técnicamente.

## Alternativas consideradas
- **Keycloak autoalojado**: descartado — contradice el requisito de "servicio de nube", implicaría correr y mantener pods propios dentro del clúster.
- **"Login with Google" (OAuth federado con cuentas Gmail)**: descartado — autentica contra el directorio de Google, no permite que el banco controle sus propios usuarios/roles, e implicaría exigirle a un cliente bancario tener cuenta de Gmail.
- **Firebase Authentication**: descartado por estar orientado a apps de consumo, no a un caso de uso bancario con roles y auditoría.

## Consecuencias
- El login es una llamada directa del frontend a Identity Platform, independiente de si el backend o el API Manager están arriba.
- Se eliminó el sistema de autenticación propio (`CORE_USER`/`WEB_CREDENTIAL` del primer parcial, ADR-0004) — nunca emitía un JWT real; la seguridad a nivel de API era, de hecho, inexistente antes de este cambio.
- Migración de 9,510 clientes únicos a Identity Platform, con contraseña temporal compartida para pruebas de carga.
- El API Manager valida el token vía JWKS público — validación de firma local, sin llamar a Identity Platform en cada request de negocio.
- Los clientes creados después de la migración masiva requieren aprovisionamiento automático en Identity Platform al momento de la creación (ver ADR-0024).
