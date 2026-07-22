# ADR — Fase 1: Monolito Dual (Primer Parcial)

Decisiones de arquitectura del Core Bancario y el Switch de Pagos Masivos como dos procesos Spring Boot independientes, desplegados en una única VM sin contenedores. Extraídas por lectura directa del código fuente de los 4 repositorios de esta fase, no solo de la documentación existente.

| ADR | Título |
|---|---|
| [001](001-monolito-dual-core-switch.md) | Monolito dual — Core y Switch como dos procesos separados, no microservicios |
| [002](002-mariadb-postgresql-por-dominio.md) | Motores de base de datos distintos por dominio (MariaDB / PostgreSQL) |
| [003](003-integracion-switch-core-sincrona.md) | Integración Switch → Core síncrona vía HTTP (RestClient) |
| [004](004-autenticacion-propia-sin-jwt.md) | Autenticación propia con contraseña hasheada, sin emisión de token |
| [005](005-sftp-embebido-polling.md) | Servidor SFTP embebido (Apache MINA SSHD) con detección por polling |
| [006](006-despliegue-vm-systemd.md) | Despliegue en una VM con systemd, sin contenedores |
| [007](007-validacion-manual-sin-bean-validation.md) | Validación de negocio manual en la capa de servicio |
| [008](008-locking-pesimista-ordenado.md) | Locking pesimista con bloqueo ordenado para transferencias |
| [009](009-procesamiento-lote-por-linea-async.md) | Procesamiento de lote línea por línea (partial success), asíncrono |
| [010](010-frontends-stacks-distintos.md) | Frontends con stacks tecnológicos independientes por dominio |
| [011](011-testing-inexistente.md) | Sin cobertura de pruebas automatizadas |
| [012](012-manejo-errores-restcontrolleradvice.md) | Manejo de errores centralizado con `@RestControllerAdvice` |
| [013](013-notificaciones-smtp-sync-async.md) | Notificaciones SMTP — asíncronas en Switch, síncronas en Core |
| [014](014-ddl-automatico-hibernate.md) | DDL automático de Hibernate, sin migraciones versionadas |
| [015](015-decisiones-menores.md) | Otras decisiones técnicas menores, con evidencia directa del código |

Varias de estas decisiones fueron superadas en fases posteriores — cada ADR indica explícitamente en su sección **Estado** si sigue vigente o qué ADR de una fase posterior lo reemplaza.
