#!/bin/bash

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
