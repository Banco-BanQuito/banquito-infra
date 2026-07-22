# ADR-005 (Fase 1): Servidor SFTP embebido (Apache MINA SSHD) con detección por polling

## Estado
Aceptado (histórico — la ingesta se rediseña sobre colas en Fase 2, ver ADR-004 y ADR-011 de Fase 2)

## Contexto
Requisito funcional explícito: una empresa cliente debe poder depositar su archivo de nómina/pagos en un buzón, sin necesidad de tener el portal web abierto — el canal debe funcionar de forma desatendida, incluso fuera de horario laboral.

## Decisión
Servidor SFTP embebido dentro del propio proceso del Switch, usando Apache MINA SSHD, con *chroot* por usuario (cada RUC ve solo su propio directorio virtual). La autenticación del canal SFTP se delega al mismo mecanismo de login del portal web (`WebCredential`), exigiendo únicamente que el cliente sea de tipo `JURIDICO`. Un archivo se considera procesado moviéndolo físicamente entre carpetas (`ingesta/` → `processed/` o `errors/`), no mediante un flag en base de datos.

## Por qué Apache MINA SSHD y no un servidor SFTP externo (ej. OpenSSH gestionado aparte)
Levantar SFTP como parte del mismo proceso Java permite reutilizar directamente la lógica de negocio ya existente (validación de credenciales, envío del archivo al motor de procesamiento) sin necesidad de exponer un segundo proceso, un segundo lenguaje de configuración, o un mecanismo de comunicación entre el servidor SFTP y el backend. Apache MINA SSHD es la librería estándar de facto para SFTP embebido en el ecosistema Java/Spring, con soporte documentado para autenticación custom y sistema de archivos virtual (`VirtualFileSystemFactory`), que es justamente lo que se necesitaba para el aislamiento por cliente.

## Por qué reutilizar `WebCredential` en vez de una tabla de credenciales SFTP dedicada
Modelar una entidad `SftpCredential` separada hubiera duplicado exactamente la misma información (usuario/contraseña por cliente jurídico) que ya vive en `WebCredential`, con el riesgo adicional de que ambas credenciales pudieran desincronizarse (un cambio de contraseña en el portal web que no se refleje en el canal SFTP). Reutilizar la credencial única del cliente jurídico mantiene una sola fuente de verdad para "quién puede autenticarse como esta empresa", sin importar el canal.

## Por qué detectar archivos por polling y no por evento del sistema de archivos
Un mecanismo basado en eventos (`WatchService`/inotify) hubiera sido más eficiente en CPU, pero exige que el proceso que escucha eventos esté corriendo de forma continua e ininterrumpida sobre el mismo filesystem del servidor SFTP — con un `@Scheduled` de polling, el mecanismo es trivial de razonar, de loguear y de ajustar en caliente (como de hecho se hizo, cambiando el intervalo de 1 a 10 segundos en producción vía variable de entorno, sin tocar código).

## Consecuencias
- (+) Ingesta desatendida real, verificada en producción con clientes reales depositando archivos fuera de horario.
- (+) Mitigación de duplicados: hash SHA-256 del archivo completo + ventana de 30 días evita reprocesar el mismo CSV si se sube dos veces por error.
- (-) El polling activo no escala a múltiples instancias del Switch: si se corrieran dos réplicas del proceso, ambas intentarían procesar el mismo archivo nuevo simultáneamente, duplicando el efecto financiero salvo por la protección de idempotencia aguas abajo.
- (-) Discrepancia real entre el valor por defecto del código (1000 ms) y el valor real de producción (10000 ms, ajustado vía variable de entorno de systemd) — evidencia de que el intervalo agresivo de 1 segundo generó carga de I/O perceptible en la VM compartida y tuvo que corregirse operativamente después del despliegue inicial.
