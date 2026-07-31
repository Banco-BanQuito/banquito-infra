# ADR — Fase 1: Monolito Dual (Primer Parcial)

Decisiones de arquitectura del Core Bancario y el Switch de Pagos Masivos, como dos procesos Spring Boot separados, desplegados en una sola VM sin contenedores. Se sacaron leyendo el código real de los 4 repositorios de esta fase, no solo de la documentación que ya existía.

| ADR | Título |
|---|---|
| [003](003-integracion-switch-core-sincrona.md) | Cliente HTTP y tiempos de espera para la integración Switch → Core |
| [005](005-sftp-embebido-polling.md) | Servidor SFTP embebido con detección por polling |
| [006](006-despliegue-vm-systemd.md) | Despliegue en una VM con systemd, sin contenedores |
| [007](007-validacion-manual-sin-bean-validation.md) | Validación de negocio escrita a mano en el servicio |
| [008](008-locking-pesimista-ordenado.md) | Bloqueo pesimista ordenado para transferencias |
| [009](009-procesamiento-lote-por-linea-async.md) | Procesamiento del lote en segundo plano, con recuperación automática |
| [010](010-frontends-stacks-distintos.md) | Cada frontend con su propio stack tecnológico |
| [011](011-testing-inexistente.md) | Sin pruebas automatizadas en esta fase |
| [012](012-manejo-errores-restcontrolleradvice.md) | Manejo de errores centralizado por servicio |
| [013](013-notificaciones-smtp-sync-async.md) | Notificaciones por correo — asíncronas en el Switch, bloqueantes en el Core |

Varias de estas decisiones se reemplazaron en fases posteriores — cada ADR dice en su encabezado (Estado) si sigue vigente o qué ADR de una fase posterior la reemplazó.

> **Nota:** los ADR 003, 005, 009 y 013 fueron ajustados para dejar claro qué parte de cada uno era un requisito explícito de los documentos de Core V1 y Switch V1 (SFTP como canal, integración síncrona, que una línea con error no bloquee el lote, notificar por correo al beneficiario) y qué parte fue realmente decisión del equipo (cómo construir cada cosa). Solo la segunda parte cuenta como ADR.
>
> Se eliminaron los ADR que documentaban el monolito dual (Core y Switch como dos procesos), los motores de base de datos distintos por dominio, la autenticación propia sin token, el uso de Hibernate para generar el esquema, y el bloque de "decisiones menores" — todos indicados por el profesor como requisitos ya dados en clase, no decisiones del equipo, o en el caso de las "decisiones menores", como un formato de ADR no reconocido.
