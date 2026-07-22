# 0010. Frontends con stacks tecnológicos completamente distintos

## Estado
Aceptado (histórico)

## Contexto
El frontend del Core y el frontend del Switch fueron construidos, con alta probabilidad, por sub-equipos distintos con afinidad tecnológica distinta.

## Decisión
Frontend Core: React 19 + JSX + Context API + Tailwind. Frontend Switch: TypeScript sin ningún framework de componentes — manipulación directa del DOM (`document.querySelector`), estado global casero persistido en `localStorage`, servido originalmente por un servidor Node.js HTTP nativo propio (reemplazado por Nginx en producción sin eliminar el código del servidor Node redundante).

## Alternativas consideradas
- Unificar ambos frontends en el mismo stack (React o TypeScript vainilla para los dos).

## Consecuencias
- Sin `DIVISIÓN_TRABAJO.md` explícito que documente el reparto — inferencia basada en el código: cada equipo aplicó lo que ya sabía usar.
- El interceptor de axios del Core prueba 4 nombres distintos de clave de `localStorage` "por compatibilidad histórica" (comentario textual encontrado en el propio código) — evidencia de que el nombre de la clave de sesión cambió varias veces durante el desarrollo sin limpieza posterior.
- Mayor costo de mantenimiento a largo plazo por la falta de un stack común entre los dos frontends del mismo sistema.
