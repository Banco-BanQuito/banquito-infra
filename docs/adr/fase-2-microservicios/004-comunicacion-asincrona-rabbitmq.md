# ADR-004: Exchange con Routing Key para el modelo Publicador-Suscriptor

## Estado
Aceptado

## Contexto
Que el broker fuera RabbitMQ (Kafka no permitido) y que el modelo fuera Publicador-Suscriptor real, no una cola simple, fue una instrucción explícita del profesor, no una decisión del equipo. Lo que sí quedó abierto fue cómo armar ese modelo Publicador-Suscriptor dentro de RabbitMQ — y esa es la decisión que documenta este ADR.

## Decisión
- Se usa RabbitMQ como único broker de mensajes.
- Cada flujo asíncrono se publica a un punto de entrada (un "Exchange") que decide a qué cola mandar cada mensaje según una etiqueta, en vez de publicar directo a una cola fija:
  - Las líneas de pago se publican con una etiqueta según su clasificación (dentro del banco, hacia otro banco, o inválida), y van a la cola correspondiente. file-reception-service publica cada línea ya clasificada y las consume ella misma (ver ADR-008). Es el Exchange, no un microservicio de ruteo, el que decide a qué cola llega cada línea.
  - Las transacciones hacia otros bancos se publican con su propia etiqueta: file-reception-service y account-core-service publican, y clearinghouse-service consume.
- La confirmación de que un mensaje se procesó bien es automática: si el consumidor no lanza ningún error, el mensaje se da por recibido; si falla, vuelve a la cola.

## Por qué este modelo y no solo una cola con nombre fijo
Publicar directo a una cola por nombre funciona, pero es un modelo de "un publicador, un consumidor", no de Publicador-Suscriptor real. Usar un punto de entrada que reparte a varias colas permite, sin cambiar el código del que publica, agregar más colas y más consumidores suscritos al mismo evento en el futuro — por ejemplo, un futuro servicio de auditoría que también necesite ver cada línea de pago.

## Consecuencias
- A favor: el Switch responde de inmediato al subir un archivo, con un código de éxito, antes de que termine el procesamiento real — el procesamiento ocurre después, fuera de esa misma petición.
- A favor: un fallo temporal en el Core (ver ADR-006 de Fase 1) no tira el archivo completo — cada línea fallida se reporta individualmente sin afectar a las demás.
- A favor: el modelo permite agregar más consumidores sin tocar el código del que publica.
- En contra: requiere operar RabbitMQ como una pieza más de infraestructura — actualmente corre como un contenedor en la misma máquina virtual, no como un servicio administrado por un proveedor de nube (ver la limitación documentada más adelante en el bloque de infraestructura).
