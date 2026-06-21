# ADR-007: Orquestación con Docker Compose y actualización continua con Watchtower

## Estado
Aceptado

## Contexto
El enunciado de esta fase exige Docker Compose (Kubernetes queda diferido al 3er parcial) y un flujo de CI/CD que permita publicar cambios sin intervención manual repetitiva en la VM de despliegue.

## Decisión
- Todo el stack (13 microservicios, 4 frontends, Kong x2, RabbitMQ, Swagger, Watchtower) se define en un único `docker-compose.yml` en `banquito-infra`, parametrizado con variables de entorno (`.env`, nunca credenciales quemadas — ver bloque de infraestructura).
- Cada repo de microservicio/frontend tiene su propio pipeline de GitHub Actions que construye y publica su imagen a GHCR (`ghcr.io/banco-banquito/<servicio>`) en cada push a `main`.
- **Watchtower** corre en la VM y revisa GHCR cada minuto; si encuentra una imagen `:latest` más nueva que la corriendo, recrea el contenedor automáticamente.

## Por qué Watchtower y no un pipeline de despliegue explícito (ej. SSH + `docker compose pull` por GitHub Actions)
Con 13 repos independientes, coordinar un despliegue push-based desde cada pipeline hacia la VM requeriría exponer credenciales SSH de la VM en cada uno de los 13 repos. Watchtower invierte el flujo a pull-based: la VM decide cuándo actualizar, y ningún repo necesita credenciales de infraestructura.

## Consecuencias
- (+) Despliegue continuo real: un `git push` a cualquier microservicio termina corriendo en producción en menos de 5 minutos sin acción manual.
- (+) Ningún repositorio de aplicación necesita secretos de la VM de producción.
- (-) Los cambios que requieren modificar `docker-compose.yml` (nuevas variables de entorno, nuevas redes, nuevos puertos) **no** los aplica Watchtower — exigen un `git pull` + `docker compose up -d --force-recreate` manual en la VM, ya documentado como paso operativo.
- (-) No hay rollback automático: si una imagen nueva rompe el servicio, hay que revertir el commit y esperar el siguiente ciclo de build, o intervenir manualmente.
