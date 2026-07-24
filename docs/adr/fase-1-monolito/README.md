# ADR — Fase 1: Monolito Dual (Primer Parcial)

Decisiones de arquitectura del Core Bancario y el Switch de Pagos Masivos, como dos procesos Spring Boot separados, desplegados en una sola VM sin contenedores. Se sacaron leyendo el código real de los 4 repositorios de esta fase, no solo de la documentación que ya existía.

| ADR | Título |
|---|---|
| [001](001-monolito-dual-core-switch.md) | Monolito dual — Core y Switch como dos procesos separados |
| [002](002-mariadb-postgresql-por-dominio.md) | Motores de base de datos distintos por dominio |
| [003](003-integracion-switch-core-sincrona.md) | Integración Switch → Core síncrona vía HTTP |
| [004](004-autenticacion-propia-sin-jwt.md) | Autenticación propia con contraseña hasheada, sin token |
| [005](005-sftp-embebido-polling.md) | Servidor SFTP embebido con detección por polling |
| [006](006-despliegue-vm-systemd.md) | Despliegue en una VM con systemd, sin contenedores |
| [007](007-validacion-manual-sin-bean-validation.md) | Validación de negocio escrita a mano en el servicio |
| [008](008-locking-pesimista-ordenado.md) | Bloqueo pesimista ordenado para transferencias |
| [009](009-procesamiento-lote-por-linea-async.md) | Procesamiento del lote línea por línea, en segundo plano |
| [010](010-frontends-stacks-distintos.md) | Cada frontend con su propio stack tecnológico |
| [011](011-testing-inexistente.md) | Sin pruebas automatizadas en esta fase |
| [012](012-manejo-errores-restcontrolleradvice.md) | Manejo de errores centralizado por servicio |
| [013](013-notificaciones-smtp-sync-async.md) | Notificaciones por correo — asíncronas en el Switch, bloqueantes en el Core |
| [014](014-ddl-automatico-hibernate.md) | Hibernate genera el esquema automáticamente |
| [015](015-decisiones-menores.md) | Otras decisiones técnicas pequeñas |

Varias de estas decisiones se reemplazaron en fases posteriores — cada ADR dice en su encabezado (Estado) si sigue vigente o qué ADR de una fase posterior la reemplazó.
