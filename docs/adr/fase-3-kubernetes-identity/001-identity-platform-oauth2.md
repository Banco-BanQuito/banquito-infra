# ADR-001 (Fase 3): Google Identity Platform como servicio de OAuth2/OIDC en la nube

## Estado
Aceptado — supersede a ADR-004 de Fase 1 (autenticación propia sin token)

## Contexto
El proyecto final exige explícitamente que OAuth2 sea un servicio provisto por la nube (no autoalojado, no corriendo dentro del propio clúster), integrado con el API Manager, y que cada aplicación cliente tenga su propia identidad verificable. Ninguna de las dos fases anteriores había resuelto esto: la Fase 1 no emitía ningún token, y hasta antes de esta decisión, la Fase 2 tampoco tenía un mecanismo de autorización de API real — cualquier endpoint de negocio era alcanzable sin validar quién llamaba.

## Decisión
Google Identity Platform, con el proveedor Email/Password habilitado, usando un email sintético `<identificación>@banquito.internal` para mapear el identificador real de negocio (cédula, RUC, o username de operador) al formato de correo que Identity Platform exige técnicamente para el proveedor de contraseña.

## Por qué Identity Platform y no las alternativas evaluadas

| Alternativa | Por qué se descartó |
|---|---|
| Keycloak autoalojado | Contradice directamente el requisito explícito de "servicio de nube" — implicaría correr y mantener pods propios de Keycloak dentro del clúster de Kubernetes, exactamente lo que el enunciado prohíbe. |
| "Login with Google" (OAuth federado con cuentas Gmail personales) | Autentica contra el directorio de identidades de Google, no contra un directorio que el banco controla — no permite dar de alta clientes y operadores propios con sus propios roles, y es operacionalmente inviable exigirle a un cliente bancario que tenga una cuenta de Gmail para acceder a su banco. |
| Firebase Authentication | Orientado a aplicaciones móviles y de consumo masivo; no ofrece el nivel de control de auditoría y administración de usuarios que un caso de uso bancario exige. |

## Por qué un email sintético y no forzar el login por cédula/RUC directamente
Identity Platform, como cualquier proveedor de identidad basado en el estándar OIDC, exige que el identificador de un usuario con proveedor "password" tenga formato de correo electrónico — es una restricción técnica del proveedor, no una elección de diseño propia. Construir el email como `<identificación>@banquito.internal` (un dominio interno, no resoluble ni real) permite que el negocio siga identificando a sus usuarios por cédula/RUC/username, tal como siempre lo ha hecho, sin que el usuario final necesite saber que, por debajo, existe un correo sintético — la pantalla de login sigue pidiendo "Usuario (cédula/RUC)", no un correo real.

## Consecuencias
- (+) El login es una llamada directa del frontend a Identity Platform, completamente independiente de si el backend, el API Manager, o cualquier otro componente del sistema están arriba en ese momento — verificado en vivo: un `curl` directo a `identitytoolkit.googleapis.com` devuelve un JWT válido sin tocar ningún otro servicio propio.
- (+) Se eliminó por completo el sistema de autenticación propio de la Fase 2 (equivalente al `CORE_USER`/`WEB_CREDENTIAL` de la Fase 1) — confirmado por revisión de código que nunca emitía un token real; la seguridad de API era, de hecho, inexistente antes de esta decisión.
- (+) El API Manager valida la firma del token de forma local contra el JWKS público de Identity Platform, sin necesitar una llamada de red a Identity Platform en cada petición de negocio — validación de firma criptográfica offline, no una consulta síncrona por cada request.
- (+) Migración real ejecutada de 9,510 clientes únicos (de 14,996 cuentas) hacia Identity Platform, con contraseña temporal compartida para uso en pruebas de carga.
- (-) El endpoint público de creación de cuentas (`accounts:signUp`) tiene un límite de tasa anti-abuso agresivo y no documentado explícitamente para uso de migración masiva (`TOO_MANY_ATTEMPTS_TRY_LATER`) — descubierto en producción durante la migración de los 9,510 clientes, resuelto usando el endpoint autenticado con credenciales administrativas en vez del API key público, que no está sujeto a ese límite.
- (-) Los clientes creados **después** de la migración masiva inicial no quedaban automáticamente aprovisionados en Identity Platform — brecha real encontrada y corregida agregando la creación automática de cuenta de Identity Platform dentro del propio flujo de alta de cliente en `party-service`, de forma transaccional (si Identity Platform falla, la creación del cliente se revierte, evitando clientes sin forma de autenticarse).
