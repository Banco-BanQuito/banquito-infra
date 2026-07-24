# ADR-007: Orquestación con Docker Compose y actualización continua con Watchtower

## Estado
Aceptado

## Contexto
El enunciado de esta fase exige Docker Compose (Kubernetes queda diferido al 3er parcial) y un flujo de CI/CD que permita publicar cambios sin intervención manual repetitiva en la VM de despliegue.

## Decisión
- Todo el stack (13 microservicios, 4 frontends, las dos instancias de Kong, RabbitMQ, Swagger, Watchtower) se define en un único archivo de Docker Compose, en el repositorio de infraestructura, con las variables sensibles guardadas aparte y nunca escritas directamente en el archivo.
- Cada repositorio de microservicio o frontend tiene su propio flujo automático en GitHub Actions que construye y publica su imagen cada vez que se sube un cambio a la rama principal.
- Watchtower corre en la máquina virtual y revisa cada minuto si hay una imagen más nueva que la que está corriendo; si la encuentra, recrea el contenedor automáticamente, sin que nadie tenga que entrar a la VM.

## Por qué Watchtower y no un despliegue explícito iniciado desde GitHub Actions
Con 13 repositorios independientes, hacer que cada uno se conecte directo a la VM para desplegar exigiría darle a los 13 repositorios acceso remoto a esa máquina. Watchtower invierte el flujo: es la VM la que decide cuándo actualizar, revisando por su cuenta si hay algo nuevo, y ningún repositorio necesita tener acceso a la infraestructura de producción.

## Consecuencias
- A favor: hay entrega continua real — un cambio subido a cualquier microservicio termina corriendo en producción en menos de 5 minutos, sin ninguna acción manual.
- A favor: ningún repositorio de aplicación necesita guardar contraseñas ni accesos de la VM de producción.
- En contra: los cambios que requieren modificar el archivo de Docker Compose en sí (nuevas variables, nuevas redes, nuevos puertos) no los aplica Watchtower — exigen entrar a la VM y aplicar el cambio a mano, un paso ya documentado como parte de la operación.
- En contra: no hay una forma automática de revertir — si una imagen nueva rompe el servicio, hay que deshacer el cambio en el código y esperar al siguiente ciclo, o intervenir manualmente.
