# 0004. Autenticación propia sin emisión de token real

## Estado
Aceptado (histórico — reemplazado por ADR-0021 en el segundo parcial)

## Contexto
Se necesitaba login para operadores (intranet) y clientes empresariales (portal web/SFTP) en el primer parcial.

## Decisión
El login valida usuario/contraseña (BCrypt vía `PasswordEncoderFactories`, correcto) contra las tablas `CORE_USER`/`WEB_CREDENTIAL`, pero devuelve un DTO plano sin ningún token. No existe `SecurityFilterChain` ni `spring-boot-starter-security` en el proyecto — solo el módulo de hashing (`spring-security-crypto`).

## Alternativas consideradas
- Spring Security + JWT (`jjwt` o `spring-security-oauth2-resource-server`).
- Sesiones de servidor con `HttpSession` + cookies.

## Consecuencias
- Cualquier endpoint del Core es alcanzable sin autenticación real — la "seguridad" depende de que el frontend no llame rutas indebidas, no de que el servidor las proteja.
- El frontend compensa con un header casero `X-Core-User-Id` que el backend nunca valida.
- Sin rate limiting en `/auth/*`, dejando el login potencialmente expuesto a fuerza bruta.
- El hashing de contraseñas sí es correcto (BCrypt) — la brecha es de autorización, no de almacenamiento de credenciales.
- Esta misma brecha se identificó también en el proyecto de microservicios antes de integrar Identity Platform (ADR-0021) — un patrón repetido entre ambos proyectos, coherente con una curva de aprendizaje real en torno a autenticación distribuida.
