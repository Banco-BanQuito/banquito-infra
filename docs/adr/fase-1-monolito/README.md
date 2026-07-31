# ADR — Fase 1: Monolito Dual (Primer Parcial)

Decisiones de arquitectura del Core Bancario y el Switch de Pagos Masivos, como dos procesos Spring Boot separados, desplegados en una sola VM sin contenedores. Se sacaron leyendo el código real de los 4 repositorios de esta fase, no solo de la documentación que ya existía.

| ADR | Título |
|---|---|
| [001](001-integracion-switch-core-sincrona.md) | Cliente HTTP y tiempos de espera para la integración Switch → Core |
| [002](002-sftp-embebido-polling.md) | Servidor SFTP embebido con detección por polling |
| [003](003-despliegue-vm-systemd.md) | systemd como gestor de procesos en la VM |
| [004](004-validacion-manual-sin-bean-validation.md) | Validación imperativa en el servicio, sin Bean Validation declarativa |
| [005](005-locking-pesimista-ordenado.md) | Bloqueo pesimista ordenado para transferencias |
| [006](006-procesamiento-lote-por-linea-async.md) | Procesamiento del lote en segundo plano, con recuperación automática |
| [007](007-frontends-stacks-distintos.md) | Frontend del Core con React, frontend del Switch sin framework |
| [008](008-testing-inexistente.md) | Sin pruebas automatizadas en esta fase |
| [009](009-manejo-errores-restcontrolleradvice.md) | Manejo de errores centralizado por servicio |
| [010](010-notificaciones-smtp-sync-async.md) | Dos notificaciones independientes por correo — no un mensaje duplicado |

Varias de estas decisiones se reemplazaron en fases posteriores — cada ADR dice en su encabezado (Estado) si sigue vigente o qué ADR de una fase posterior la reemplazó.

> **Nota:** cada uno de estos ADR fue revisado contra los documentos de requisitos de Core V1 y Switch V1, y contra lo que el profesor indicó directamente en clase. Donde una parte de la decisión ya venía dada (el canal SFTP, la integración síncrona, que una línea con error no bloquee el lote, notificar por correo al beneficiario, no usar contenedores en esta fase), el ADR se dejó enfocado solo en la parte que sí fue decisión real del equipo — cómo construir cada cosa dentro de esas reglas.
>
> Se eliminaron por completo los ADR que documentaban el monolito dual (Core y Switch como dos procesos), los motores de base de datos distintos por dominio, la autenticación propia sin token, el uso de Hibernate para generar el esquema, y el bloque de "decisiones menores" — todos indicados por el profesor como requisitos ya dados en clase, o en el caso de las "decisiones menores", como un formato de ADR no reconocido.
