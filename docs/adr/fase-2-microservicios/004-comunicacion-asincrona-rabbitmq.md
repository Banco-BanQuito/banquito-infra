# ADR-004: Mensajería asíncrona con RabbitMQ (modelo Pub-Sub)

## Estado
Aceptado

## Contexto
El Switch de Pagos Masivos debe procesar archivos de miles de líneas sin dejar esperando al usuario que sube el archivo, y sin que la velocidad de recepción del archivo dependa de qué tan rápido el Core procese cada línea. El enunciado exige explícitamente usar RabbitMQ (Kafka no está permitido) y un modelo real de Publicador-Suscriptor, no solo una cola simple.

## Decisión
- Se usa RabbitMQ como único broker de mensajes.
- Cada flujo asíncrono se publica a un punto de entrada (un "Exchange") que decide a qué cola mandar cada mensaje según una etiqueta, en vez de publicar directo a una cola fija:
  - Las líneas de pago se publican con una etiqueta según su clasificación (dentro del banco, hacia otro banco, o inválida), y van a la cola correspondiente. file-reception-service publica cada línea ya clasificada y las consume ella misma (ver ADR-011). Es el Exchange, no un microservicio de ruteo, el que decide a qué cola llega cada línea.
  - Las transacciones hacia otros bancos se publican con su propia etiqueta: file-reception-service y account-core-service publican, y clearinghouse-service consume.
- La confirmación de que un mensaje se procesó bien es automática: si el consumidor no lanza ningún error, el mensaje se da por recibido; si falla, vuelve a la cola.

## Por qué este modelo y no solo una cola con nombre fijo
Publicar directo a una cola por nombre funciona, pero es un modelo de "un publicador, un consumidor", no de Publicador-Suscriptor real. Usar un punto de entrada que reparte a varias colas permite, sin cambiar el código del que publica, agregar más colas y más consumidores suscritos al mismo evento en el futuro — por ejemplo, un futuro servicio de auditoría que también necesite ver cada línea de pago.

## Consecuencias
- A favor: el Switch responde de inmediato al subir un archivo, con un código de éxito, antes de que termine el procesamiento real — el procesamiento ocurre después, fuera de esa misma petición.
- A favor: un fallo temporal en el Core (ver ADR-009 de Fase 1) no tira el archivo completo — cada línea fallida se reporta individualmente sin afectar a las demás.
- A favor: el modelo permite agregar más consumidores sin tocar el código del que publica.
- En contra: requiere operar RabbitMQ como una pieza más de infraestructura — actualmente corre como un contenedor en la misma máquina virtual, no como un servicio administrado por un proveedor de nube (ver la limitación documentada más adelante en el bloque de infraestructura).
