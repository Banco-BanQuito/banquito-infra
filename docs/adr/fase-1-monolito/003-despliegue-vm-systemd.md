# ADR-003 (Fase 1): systemd como gestor de procesos en la VM

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
Cada backend corre como un servicio del sistema operativo administrado por systemd, con Nginx repartiendo el tráfico hacia cada uno.

## Contexto
Que esta fase se desplegara en una sola máquina virtual, sin contenedores, fue el alcance que el profesor definió para este parcial — los contenedores quedaron para la fase siguiente, cuando ya eran un requisito explícito. Lo que sí quedó abierto fue cómo mantener cada backend corriendo dentro de esa VM sin contenedores, y esa es la decisión que documenta este ADR.

## Opciones consideradas
1. **(SELECCIONADA) systemd:** cada backend como un servicio del sistema operativo, reiniciado automáticamente si falla.
2. **Proceso manual en segundo plano (nohup / screen), sin gestor de servicios.**

## Compensaciones

**Opción 1 (SELECCIONADA) — systemd**
- Seleccionada porque ya da reinicio automático si un servicio falla, sin configuración extra ni scripts propios.
- Con esta opción, un problema de memoria o de CPU en un servicio afecta a los demás, porque todos comparten el mismo sistema operativo sin límites entre ellos.
- Con esta opción, actualizar un servicio implica un corte breve — no hay forma de actualizar sin interrumpir el servicio un momento.
- Con esta opción, las contraseñas quedaron escritas directamente en los archivos de configuración de systemd, sin ningún baúl de secretos.

**Opción 2 — Proceso manual en segundo plano**
- Rechazada porque no reinicia solo si el proceso se cae, y no sobrevive a un reinicio de la VM sin configurar algo aparte para eso — systemd resuelve ambas cosas de fábrica.
