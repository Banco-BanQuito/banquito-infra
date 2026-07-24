# ADR-015 (Fase 1): Otras decisiones técnicas pequeñas

**Estado:** Aceptado (histórico)
**Fecha:** Mayo 2026
**Autor:** Equipo Fase 1

## Decisión
Este ADR no es una sola decisión — junta varios hallazgos pequeños del código, cada uno muy chico para tener su propio ADR, pero útiles en conjunto para mostrar que el análisis de esta fase se hizo sobre el código real.

## Contexto
Al revisar el código de los 4 repositorios de esta fase, aparecieron varios detalles que vale la pena dejar anotados.

## Compensaciones

**Lombok en el Core, nada de Lombok en el Switch.** El Core usa la librería Lombok para no escribir a mano los getters y setters; el Switch los escribe todos a mano, en los mismos archivos. Es consistente en todo el módulo del Switch, así que fue una elección de ese sub-equipo, no un descuido en un solo archivo.

**Nunca se exponen las entidades de base de datos directamente en las respuestas.** Los dos backends siempre devuelven un DTO (un objeto pensado para la respuesta), nunca la entidad de la base de datos tal cual. Esto evita errores de serialización y evita mostrar campos internos que no le importan al cliente.

**La versión de la API va fija en la URL** (`/core/v1/`, `/switch/v1/`), no en un encabezado. Es la forma más simple de versionar una API, suficiente para un sistema con un solo consumidor por endpoint.

**El Core deja entrar peticiones de cualquier origen (CORS abierto); el Switch solo acepta una lista fija de orígenes conocidos.** El Switch, al manejar pagos masivos, quedó más restringido — probablemente porque se reescribió más tarde que el Core y ahí sí se pensó en este detalle.

**Las variables de entorno tienen un valor por defecto escrito en el mismo archivo de configuración**, en vez de tener un archivo distinto para desarrollo y otro para producción. Esto permite mover el mismo programa compilado entre la laptop de un desarrollador y la VM sin mantener dos archivos sincronizados a mano.

**No hay límite de peticiones por segundo en ningún endpoint**, ni siquiera en el login — consecuencia directa de que tampoco hay control de quién puede llamar a cada endpoint (ver ADR-004).

**Se encontró código que ya no hace nada real.** Un método de validación de archivos siempre marca el resultado como exitoso, sin volver a revisar nada — la validación real ya se había movido a otro lugar del código antes, y este método quedó "pegado" sin actualizarse. Es un ejemplo concreto de una parte del código que quedó a medias tras un cambio anterior.
