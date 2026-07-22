# 0005. Servidor SFTP embebido con polling por filesystem

## Estado
Aceptado (histórico — el segundo parcial mueve la ingesta a un modelo de colas, ver ADR-0017)

## Contexto
Requisito funcional de recibir archivos de nómina/pagos masivos de forma desatendida, sin que la empresa cliente esté conectada al portal web.

## Decisión
Servidor SFTP embebido con Apache MINA SSHD, con *chroot* por usuario/RUC, autenticación delegada al Core (reutilizando `WebCredential`, la misma credencial del portal web). Un archivo se considera "procesado" al moverlo físicamente de carpeta (`processed/`/`errors/`), no mediante un flag en base de datos.

## Alternativas consideradas
- `WatchService`/inotify (basado en eventos del sistema de archivos, no polling).
- Tabla de estado en BD en vez de mover archivos físicamente.
- Modelar una tabla de credenciales SFTP separada en vez de reutilizar `WebCredential`.

## Consecuencias
- Reutilizar las credenciales web evitó modelar un sistema de credenciales paralelo — atajo razonable para el alcance del parcial.
- El polling activo no escala a múltiples instancias del Switch: dos réplicas procesarían el mismo archivo dos veces.
- Discrepancia real encontrada entre documentación y despliegue: el código por defecto hace polling cada 1 segundo, pero la VM de producción lo sobreescribe a 10 segundos vía variable de entorno, casi con certeza para bajar la carga de I/O constante en una VM compartida.
- Mitigación parcial: hash SHA-256 del archivo + ventana de 30 días para detectar duplicados.
