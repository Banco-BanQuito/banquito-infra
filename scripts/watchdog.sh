#!/bin/bash
# Revisa los contenedores del proyecto banquito-infra y arranca cualquiera que
# no este "running" (cubre el caso visto en produccion: un contenedor queda en
# estado "Created" tras un "docker compose up" y nunca llega a iniciar).
# Pensado para correr via cron cada 5 minutos en la VM de despliegue.

LOGFILE="/var/log/banquito-watchdog.log"

cd "$(dirname "$0")/.." || exit 1

containers=$(docker compose ps -a --format '{{.Name}} {{.State}}')

while read -r name state; do
    [ -z "$name" ] && continue
    if [ "$state" != "running" ]; then
        echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) [watchdog] $name esta en estado '$state', arrancando..." >> "$LOGFILE"
        docker start "$name" >> "$LOGFILE" 2>&1
    fi
done <<< "$containers"
