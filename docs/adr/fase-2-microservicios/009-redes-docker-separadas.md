# ADR-009 (Fase 2): Redes Docker separadas entre Core y Switch

**Estado:** Aceptado
**Fecha:** Junio 2026
**Autor:** Equipo Fase 2

## Decisión
Se crean dos redes de Docker — una para el Core y otra para el Switch. Cada servicio se conecta solo a la red de su dominio, menos `account-core-service`, que se conecta a las dos porque es el único puente permitido entre ambos.

## Contexto
El ADR-001 de esta fase dice que Core y Switch son dos dominios separados, pero esa separación, si solo vive en cómo está organizado el código, no impide que un contenedor le hable directamente a otro por red, sin pasar por su API.

## Opciones consideradas
1. **(SELECCIONADA) Dos redes Docker separadas:** cada dominio tiene su propia red; solo un servicio puente conecta a las dos.
2. **Una sola red compartida para todos los contenedores.**

## Compensaciones

**Opción 1 (SELECCIONADA) — Dos redes separadas**
- Seleccionada porque convierte la separación de "no debes llamar directo a otro dominio" en algo que la red misma impide, no solo una regla que alguien podría saltarse bajo presión de tiempo.
- Con esta opción, la separación se puede comprobar con una herramienta (`docker network inspect`), no solo mostrarse en un diagrama.
- Con esta opción, depurar un problema de conexión exige saber en qué red está cada contenedor — un error de conexión puede ser justamente por esta separación, no porque el servicio esté caído.

**Opción 2 — Una sola red compartida**
- Rechazada porque cualquier contenedor podría alcanzar a cualquier otro sin restricción, sin importar a qué dominio pertenece "en el papel" — no demuestra ninguna separación real.
