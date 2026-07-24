# ADR-004 (Fase 1): Autenticación propia con contraseña hasheada, sin token

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
El login revisa usuario y contraseña contra las tablas `CORE_USER` (operadores) y `WEB_CREDENTIAL` (clientes), con la contraseña protegida con BCrypt, y devuelve los datos del usuario sin ningún token.

## Contexto
Se necesitaba login para dos tipos de usuario: operadores de agencia (intranet del Core) y clientes empresariales (portal web y SFTP del Switch). El enunciado de esta fase no pedía todavía un esquema de autorización con tokens — el foco era que el flujo de negocio funcionara de punta a punta.

## Opciones consideradas
1. **(SELECCIONADA) Usuario/contraseña con hash, sin token:** login simple que solo confirma la identidad y devuelve los datos del usuario.
2. **Usuario/contraseña con JWT:** mismo login, pero emitiendo un token firmado que el backend valida en cada llamada.
3. **Sesión de servidor con cookie:** el servidor guarda la sesión y la identifica por una cookie.

## Compensaciones

**Opción 1 (SELECCIONADA) — Usuario/contraseña sin token**
- Seleccionada porque el objetivo de esta fase era demostrar el flujo de negocio completo, no un esquema de seguridad de API — construir JWT o sesiones hubiera consumido tiempo sin ser parte de lo evaluado en este parcial.
- Con esta opción, el hash de la contraseña sí queda bien hecho (BCrypt), pero ningún endpoint del backend valida quién está llamando — la única protección es que el frontend no llame rutas indebidas, no que el servidor las rechace.
- Con esta opción no hay límite de intentos de login, dejando la puerta abierta a ataques de fuerza bruta.

**Opción 2 — Usuario/contraseña con JWT**
- Rechazada por tiempo: implementar emisión y validación de token en cada endpoint no era parte de lo que pedía el enunciado de esta fase.

**Opción 3 — Sesión de servidor con cookie**
- Rechazada porque el Core y el Switch son procesos separados (ver ADR-001), y compartir sesión entre dos procesos distintos hubiera exigido un almacén de sesiones común, complejidad no justificada en esta fase.
