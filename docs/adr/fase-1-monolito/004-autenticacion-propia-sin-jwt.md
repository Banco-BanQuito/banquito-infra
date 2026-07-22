# ADR-004 (Fase 1): Autenticación propia con contraseña hasheada, sin emisión de token

## Estado
Aceptado (histórico — reemplazado por ADR-001 de Fase 3, Identity Platform)

## Contexto
El primer parcial necesitaba login para dos audiencias distintas: operadores de agencia (intranet del Core) y clientes empresariales (portal web y canal SFTP del Switch), sin que el enunciado de esta fase exigiera todavía un esquema de autorización basado en tokens.

## Decisión
El login valida usuario/contraseña contra las tablas `CORE_USER` (operadores) y `WEB_CREDENTIAL` (clientes), usando `PasswordEncoderFactories.createDelegatingPasswordEncoder()` (BCrypt) para el hash de contraseñas, y devuelve un DTO plano con los datos del usuario autenticado — sin emitir JWT, sin `SecurityFilterChain`, sin `spring-boot-starter-security` en el classpath (solo el módulo de hashing, `spring-security-crypto`).

## Por qué no se implementó un esquema de autorización basado en token
El primer parcial evaluaba explícitamente la capacidad de construir el flujo de negocio (apertura de cuentas, transferencias, procesamiento de lotes) end-to-end contra bases de datos reales en una VM de producción — la autorización de API (quién puede llamar a qué endpoint) no era un criterio de evaluación de esta fase, a diferencia de fases posteriores donde el API Manager y OAuth2 sí se vuelven requisitos explícitos (ver ADR-001 y ADR-002 de Fase 3).

## Consecuencias
- (+) El hash de contraseñas es correcto y estándar (BCrypt vía `PasswordEncoderFactories`) — la decisión débil está en la capa de autorización de API, no en el almacenamiento de credenciales.
- (+) El servidor SFTP reutiliza inteligentemente las credenciales web del cliente jurídico (`WebCredential`) en vez de modelar un sistema de credenciales paralelo — decisión pragmática que evita duplicar lógica de autenticación para un canal adicional.
- (-) Cualquier endpoint del Core es alcanzable sin autenticación real a nivel de servidor — la restricción de acceso depende de que el frontend no llame rutas indebidas, no de que el backend las rechace. El frontend compensa con un header casero `X-Core-User-Id` que el backend nunca valida, lo que confirma que la protección es puramente de interfaz, no de servidor.
- (-) Sin rate limiting en `/auth/*`, dejando el login potencialmente expuesto a intentos de fuerza bruta.
- Esta misma brecha (falta de token real) se identificó también en la arquitectura de microservicios antes de integrar Identity Platform, señal de que es un punto ciego recurrente en torno a autenticación distribuida que la Fase 3 corrige de forma definitiva con un proveedor de identidad externo.
