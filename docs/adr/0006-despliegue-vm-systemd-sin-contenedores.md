# 0006. Despliegue en una VM con systemd, sin contenedores ni CI/CD

## Estado
Aceptado (histórico — reemplazado por ADR-0023 en el segundo parcial)

## Contexto
Plazo del primer parcial y ausencia de experiencia previa en Docker/Kubernetes en el equipo.

## Decisión
Instancia GCE (`e2-standard-2`), cada backend como servicio systemd, Nginx como reverse proxy. Confirmado en el código: cero `Dockerfile`, cero `.github/workflows` en los 4 repositorios — despliegue 100% manual (`mvn package` → copiar el `.jar` → `systemctl restart`).

## Alternativas consideradas
- Docker Compose para levantar todo el stack con un comando.
- GitHub Actions para build+deploy automatizado.

## Consecuencias
- Rápido de levantar para un demo puntual de un mes.
- Sin aislamiento de procesos: un fallo de memoria de un servicio afecta a los demás en la misma VM.
- Sin rolling deploy: downtime en cada actualización.
- Credenciales en texto plano en los archivos `.service` de systemd (confirmado: `DB_PASSWORD=root`, `SFTP_SERVER_PASSWORD=password`).
- Esta es la brecha que el segundo parcial resuelve con contenedores + Secret Manager + orquestador (ADR-0021, ADR-0023).
