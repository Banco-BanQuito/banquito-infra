# ADR-001 (Fase 1): Servidor SFTP embebido con detección por polling

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
Se levanta un servidor SFTP (el protocolo para subir archivos por internet de forma segura) dentro del propio proceso del Switch, revisando cada cierto tiempo si hay archivos nuevos, y usando las mismas credenciales del portal web para autenticar al cliente.

## Contexto
El documento de requisitos del Switch (V1) ya exige que el canal SFTP exista, como segunda vía de carga junto al portal web — eso no fue una decisión del equipo. Lo que sí quedó abierto fue cómo construir ese servidor SFTP: una empresa cliente debe poder dejar su archivo de nómina en el buzón sin tener el portal web abierto, incluso fuera de horario laboral, y el equipo decidió cómo lograr eso.

## Opciones consideradas
1. **(SELECCIONADA) Servidor SFTP dentro del mismo proceso, revisando la carpeta cada cierto tiempo:** el propio proceso del Switch corre el servidor SFTP y revisa la carpeta de archivos cada cierto tiempo.
2. **Servidor SFTP externo, gestionado aparte:** un proceso separado recibe el archivo y avisa al Switch.
3. **Detección automática por evento del sistema de archivos:** en vez de revisar cada cierto tiempo, el sistema avisa apenas llega un archivo nuevo.

## Compensaciones

**Opción 1 (SELECCIONADA) — Servidor SFTP dentro del mismo proceso**
- Seleccionada porque, al vivir dentro del mismo proceso del Switch, reutiliza directamente la validación de credenciales y el envío al motor de procesamiento que ya existían — sin necesitar un segundo proceso ni un canal de comunicación adicional.
- Seleccionada porque reutilizar la misma credencial del portal web evita tener dos contraseñas por cliente que se puedan desincronizar.
- Con esta opción, si se corrieran dos copias del Switch al mismo tiempo, ambas podrían intentar procesar el mismo archivo nuevo a la vez, duplicando el pago (mitigado en parte con un control de archivos repetidos).
- El valor de revisión por defecto en el código es de 1 segundo, pero en producción tuvo que subirse a 10 segundos porque generaba demasiada carga en la máquina compartida.

**Opción 2 — Servidor SFTP externo gestionado aparte**
- Rechazada porque hubiera exigido un segundo proceso, con su propia configuración, y un mecanismo para avisarle al Switch cuando llega un archivo nuevo — más piezas que mantener sin un beneficio claro para el alcance de esta fase.

**Opción 3 — Detección por evento del sistema de archivos**
- Rechazada porque, aunque gasta menos CPU que el polling, exige que el proceso que escucha eventos esté corriendo sin interrupciones. El polling, aunque menos eficiente, es mucho más simple de entender, de revisar en los logs, y de ajustar sin tocar código (como de hecho pasó al subir el intervalo de 1 a 10 segundos).
