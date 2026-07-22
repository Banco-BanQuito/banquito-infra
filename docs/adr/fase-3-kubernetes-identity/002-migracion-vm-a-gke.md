# ADR-002 (Fase 3): Migración de despliegue — VM + Docker Compose + Watchtower → Google Kubernetes Engine

## Estado
En progreso — supersede a ADR-007 de Fase 2

## Contexto
El proyecto final exige explícitamente un orquestador de contenedores real, provisto por la nube — Docker Compose sobre una única VM, aunque funcional para las fases anteriores, no cumple ese requisito por definición: no hay orquestación real (rescheduling automático ante fallo de nodo, escalado horizontal declarativo, rolling updates nativos).

## Decisión
Migración a GKE (Google Kubernetes Engine), con el pipeline de GitHub Actions de cada repositorio desplegando vía `kubectl set image` sobre el clúster, autenticado mediante Workload Identity Federation — sin llaves de cuenta de servicio en texto plano almacenadas como secreto de GitHub.

## Por qué GKE y no Docker Swarm
Docker Swarm es más simple de operar que Kubernetes, pero tiene adopción decreciente en la industria y un ecosistema de herramientas (observabilidad, gestión de secretos, políticas de red) sustancialmente más limitado. Kubernetes es el estándar de facto tanto de la industria como del propio curso, y GKE en particular ofrece integración nativa con el resto del stack de GCP ya en uso (Cloud SQL, Secret Manager, Identity Platform), reduciendo el número de puntos de integración manual entre proveedores.

## Por qué Workload Identity Federation y no una llave de cuenta de servicio descargada
Una llave de cuenta de servicio en formato JSON, almacenada como secreto de GitHub, es una credencial de larga duración que, si se filtra, otorga acceso hasta que alguien la revoque manualmente. Workload Identity Federation permite que GitHub Actions se autentique directamente contra GCP usando la identidad propia del workflow (un token de corta duración emitido por GitHub, intercambiado por credenciales temporales de GCP), sin que exista ningún archivo de credencial persistente que pueda filtrarse.

## Lección real aprendida durante la transición, no anticipada en el diseño original
Mientras el sistema corría sobre Docker Compose con Watchtower, un merge a `main` disparaba un `docker compose down` seguido de `up` **completo e inmediato**, sin posibilidad real de cancelarlo a mitad de camino una vez iniciado — se comprobó en producción que intentar cancelar la ejecución de GitHub Actions después de que el script ya había empezado a correr no detiene el `docker compose down` ya en curso, dejando el sistema completo caído hasta que se restaura manualmente. GKE con `kubectl set image` reemplaza ese riesgo por una actualización rolling (los pods viejos se retiran gradualmente a medida que los nuevos pasan su *health check*), pero introdujo una clase de problema distinta: los `--build-arg` necesarios para que cada frontend reciba sus variables de entorno reales en tiempo de build no se estaban propagando en el pipeline de GKE — ningún frontend apuntaba a las URLs correctas hasta que se corrigió explícitamente.

## Consecuencias
- (+) Actualizaciones rolling reales, sin la ventana de caída completa que Watchtower + Docker Compose sí tenía.
- (+) Sin credenciales de larga duración expuestas en ningún repositorio, gracias a Workload Identity Federation.
- (+) Integración nativa con el resto de servicios GCP del proyecto (Cloud SQL, Secret Manager, Identity Platform) usando el mismo modelo de identidad de carga de trabajo.
- (-) Migración todavía en progreso al momento de este documento: no todos los servicios están desplegados en GKE, y el pipeline de build-args para los frontends requirió una corrección posterior a la migración inicial para funcionar correctamente.
- (-) Los secretos que antes se leían como variable de entorno simple en el `.service` de systemd (Fase 1) o en el `.env` de Docker Compose (Fase 2) ahora requieren, para hacerlo correctamente y no solo copiar el valor a mano, configurar el Secrets Store CSI Driver de GKE con Workload Identity — mecanismo correcto pero con una curva de configuración inicial mayor que las fases anteriores.
