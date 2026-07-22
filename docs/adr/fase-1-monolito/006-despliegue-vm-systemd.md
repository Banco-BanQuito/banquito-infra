# ADR-006 (Fase 1): Despliegue en una VM con systemd, sin contenedores

## Estado
Aceptado (histórico — reemplazado por ADR-007 de Fase 2, Docker Compose + Watchtower)

## Contexto
Plazo de un mes para desplegar un sistema funcional en la nube, sin experiencia previa del equipo en Docker ni Kubernetes, y sin que esta fase del curso exigiera todavía contenedorización.

## Decisión
Instancia GCE `e2-standard-2`, cada backend (`banquito-core.service`, `banquito-switch.service`, `banquito-buzon.service`) como unidad systemd independiente, con Nginx como reverse proxy sirviendo ambos frontends compilados y enrutando `/core/` y `/api/switch/` a los puertos internos correspondientes. Confirmado por revisión directa del repositorio: cero `Dockerfile`, cero workflow de CI/CD en los 4 repositorios — el ciclo de despliegue es `mvn package` → copiar el `.jar` a `/var/banquito/apps/` → `systemctl restart`.

## Por qué systemd y no contenedores, ni siquiera localmente
Con el equipo aprendiendo simultáneamente el dominio bancario y los conceptos de arquitectura distribuida, agregar Docker como una tercera curva de aprendizaje en el mismo mes hubiera desplazado tiempo de desarrollo de funcionalidad. `systemd` ofrece exactamente lo que se necesitaba en esta fase — reinicio automático ante fallo (`Restart=on-failure`), gestión de variables de entorno, arranque ordenado por dependencias (`After=network.target mariadb.service`) — sin la sobrecarga conceptual de imágenes, redes virtuales y orquestación.

## Consecuencias
- (+) Cero fricción de infraestructura para desplegar una actualización durante el desarrollo activo del parcial.
- (+) Cada servicio se reinicia automáticamente ante fallo sin intervención manual (`Restart=on-failure`, `RestartSec=10`).
- (-) Sin aislamiento de procesos: un fallo de memoria o un pico de CPU de un servicio afecta la disponibilidad de los demás, al compartir el mismo kernel y los mismos recursos físicos sin límites impuestos.
- (-) Sin rolling deploy: cada `systemctl restart` implica una ventana de downtime, por breve que sea.
- (-) Credenciales en texto plano dentro de los archivos `.service` de systemd, confirmado en el propio repositorio de infraestructura (`DB_PASSWORD=root`, `SFTP_SERVER_PASSWORD=password`) — exactamente el tipo de exposición que la Fase 2 y Fase 3 resuelven con contenedores + variables de entorno inyectadas + un baúl de secretos administrado (ver ADR-008 de Fase 2 y el manejo de secretos en Fase 3).
