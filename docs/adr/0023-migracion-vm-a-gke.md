# 0023. Migración de despliegue: VM + Docker Compose + Watchtower → GKE

## Estado
En progreso — supersede a ADR-0006

## Contexto
El primer parcial se desplegó en una VM con systemd. El proyecto final exige un orquestador de contenedores real, provisto por la nube.

## Decisión
Etapa intermedia: VM + Docker Compose + Watchtower (auto-pull de imágenes nuevas en cada push a `main`) para desarrollo ágil. Migración en curso a GKE (Google Kubernetes Engine), con despliegue vía `kubectl set image` en el pipeline de GitHub Actions, autenticado por Workload Identity Federation (sin llaves de service account en texto plano).

## Alternativas consideradas
- Seguir en VM/systemd como en el primer parcial — descartado, no cumple el requisito explícito de orquestador de contenedores.
- Docker Swarm — descartado por adopción decreciente frente a Kubernetes, el estándar de facto de la industria y del curso.

## Consecuencias
- Lección aprendida en producción: un merge a `main` con Watchtower activo dispara un `docker compose down/up` completo e inmediato, sin posibilidad real de cancelarlo a mitad de camino — casi causó una caída total del sistema durante una corrección en caliente.
- La migración a GKE con `kubectl set image` reemplaza ese riesgo por actualizaciones rolling, pero introdujo una nueva clase de problema: build-args no propagados correctamente al pipeline (ningún frontend recibía sus variables de entorno reales en el build de GKE hasta corregirlo).
- Migración en curso: no todos los servicios están aún desplegados en GKE al momento de este documento.
