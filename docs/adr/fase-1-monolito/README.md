# ADR — Fase 1: Monolito Dual (Primer Parcial)

Decisiones de arquitectura del Core Bancario y el Switch de Pagos Masivos, como dos procesos Spring Boot separados, desplegados en una sola VM sin contenedores.

| ADR | Título |
|---|---|
| [001](001-sftp-embebido-polling.md) | Servidor SFTP embebido con detección por polling |
| [002](002-validacion-manual-sin-bean-validation.md) | Validación imperativa en el servicio, sin Bean Validation declarativa |
| [003](003-locking-pesimista-ordenado.md) | Bloqueo pesimista ordenado para transferencias |
| [004](004-procesamiento-lote-por-linea-async.md) | Procesamiento del lote en segundo plano, con recuperación automática |
| [005](005-frontends-stacks-distintos.md) | Frontend del Core con React, frontend del Switch sin framework |
| [006](006-notificaciones-smtp-sync-async.md) | Dos notificaciones independientes por correo — no un mensaje duplicado |

Varias de estas decisiones se reemplazaron en fases posteriores — cada ADR dice en su encabezado (Estado) si sigue vigente o qué ADR de una fase posterior la reemplazó.

> **Nota:** esta es la segunda pasada de recorte. Además de quitar lo que ya venía dado por los documentos de requisitos o por el profesor en clase, se quitaron los ADR donde la "alternativa" no era algo que el equipo hubiera considerado en serio (por ejemplo, systemd contra correr el proceso a mano con `nohup`, o el manejo de errores centralizado, que es la forma estándar en Spring y no algo debatido). Solo quedan los que representan una elección real entre alternativas viables, con una razón concreta para descartar cada una.
