# ADR-001 (Fase 3): Google Identity Platform como OAuth2 en la nube

**Estado:** Aceptado — reemplaza la autenticación propia sin token de Fase 1
**Fecha:** Julio 2026
**Autor:** Anahy Herrera

## Decisión
Se usa Google Identity Platform, con login por correo y contraseña, mapeando la identificación real del usuario (cédula, RUC, o usuario de operador) a un correo interno con el formato `<identificación>@banquito.internal`.

## Contexto
El proyecto final pide que OAuth2 sea un servicio de la nube (no instalado por el equipo, no corriendo dentro del clúster), conectado al API Manager, y que cada aplicación tenga su propia identidad. Ni la Fase 1 ni la Fase 2 habían resuelto esto: ninguna de las dos emitía un token real, así que cualquier endpoint de negocio se podía llamar sin validar quién lo hacía.

## Opciones consideradas
1. **(SELECCIONADA) Google Identity Platform:** servicio de identidad administrado por Google, sin instalar nada propio.
2. **Keycloak instalado por el equipo:** un servidor de identidad open source, corriendo dentro del clúster.
3. **"Iniciar sesión con Google" (login federado con cuentas Gmail):** usar directamente las cuentas personales de Google de los usuarios.
4. **Firebase Authentication:** el servicio hermano de Identity Platform, pensado para apps móviles.

## Compensaciones

**Opción 1 (SELECCIONADA) — Google Identity Platform**
- Seleccionada porque es un servicio administrado, cumple el requisito de "servicio de nube" sin instalar ni mantener nada propio.
- Seleccionada porque permite dar de alta usuarios propios del banco, con sus propios roles — algo que "Iniciar sesión con Google" no permite.
- Con esta opción, el login queda completamente separado del resto del sistema: funciona aunque el backend o el API Manager estén caídos. Se comprobó en vivo llamando directo al servicio y recibiendo un token válido sin tocar ningún otro componente propio.
- Con esta opción, se necesitó inventar un correo interno (`identificación@banquito.internal`) porque el servicio exige que el usuario tenga formato de correo, aunque el banco identifique a sus clientes por cédula o RUC.
- El punto de creación masiva de cuentas tiene un límite de velocidad no documentado que apareció al migrar miles de clientes de una vez — se resolvió usando la vía de administrador en vez de la pública, que no tiene ese límite.
- Los clientes nuevos, creados después de la migración inicial, no quedaban con cuenta de login automáticamente — se corrigió agregando la creación de la cuenta de Identity Platform al mismo paso donde se da de alta un cliente nuevo.

**Opción 2 — Keycloak instalado por el equipo**
- Rechazada porque contradice directamente el requisito de "servicio de nube" — habría que instalar y mantener Keycloak dentro del propio clúster.

**Opción 3 — "Iniciar sesión con Google"**
- Rechazada porque autentica contra las cuentas personales de Google de cada persona, no contra un directorio que el banco controla, y no tiene sentido pedirle a un cliente bancario que tenga cuenta de Gmail para entrar a su banco.

**Opción 4 — Firebase Authentication**
- Rechazada porque está pensado para aplicaciones de consumo masivo, sin el nivel de control y auditoría que necesita un sistema bancario.
