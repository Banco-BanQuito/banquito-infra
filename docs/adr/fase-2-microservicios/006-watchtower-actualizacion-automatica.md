# ADR-006: Watchtower para actualizar automáticamente los contenedores

## Estado
Aceptado

## Contexto
Que el despliegue de esta fase fuera con Docker Compose fue una instrucción directa del profesor, no una decisión del equipo. Lo que sí quedó abierto fue cómo lograr que un cambio subido a cualquiera de los 13 repositorios terminara corriendo en producción sin que alguien tuviera que entrar a la VM a mano cada vez — y esa es la decisión que documenta este ADR.

## Decisión
- Cada repositorio de microservicio o frontend tiene su propio flujo automático en GitHub Actions que construye y publica su imagen cada vez que se sube un cambio a la rama principal.
- Watchtower corre en la máquina virtual y revisa cada minuto si hay una imagen más nueva que la que está corriendo; si la encuentra, recrea el contenedor automáticamente, sin que nadie tenga que entrar a la VM.

## Opciones consideradas
1. **(SELECCIONADA) Watchtower revisando por su cuenta si hay una imagen nueva.**
2. **Despliegue explícito iniciado desde GitHub Actions**, conectándose directo a la VM para actualizar el contenedor.

## Compensaciones

**Opción 1 (SELECCIONADA) — Watchtower**
- Seleccionada porque, con 13 repositorios independientes, hacer que cada uno se conecte directo a la VM para desplegar exigiría darle a los 13 repositorios acceso remoto a esa máquina.
- Watchtower invierte el flujo: es la VM la que decide cuándo actualizar, revisando por su cuenta si hay algo nuevo, y ningún repositorio necesita tener acceso a la infraestructura de producción.
- Con esta opción, los cambios que requieren modificar el archivo de Docker Compose en sí (nuevas variables, nuevas redes, nuevos puertos) no los aplica Watchtower — exigen entrar a la VM y aplicar el cambio a mano.
- Con esta opción no hay una forma automática de revertir — si una imagen nueva rompe el servicio, hay que deshacer el cambio en el código y esperar al siguiente ciclo, o intervenir manualmente.

**Opción 2 — Despliegue explícito desde GitHub Actions**
- Rechazada porque hubiera exigido guardar credenciales de acceso a la VM de producción en los 13 repositorios, uno por cada microservicio o frontend — más superficie expuesta si alguna se filtra.
