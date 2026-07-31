# ADR-008: Eliminación de routing-service, el Exchange de RabbitMQ hace el ruteo

## Estado
Aceptado

## Contexto
El profesor observó que no tiene sentido mantener un microservicio dedicado exclusivamente a decidir si una línea de pago es dentro del banco o hacia otro banco y reenviarla, cuando RabbitMQ ya resuelve ese problema por su cuenta. El servicio de ruteo que existía antes consumía una sola cola y decidía en código a qué flujo pertenecía cada línea, duplicando una responsabilidad que el propio broker de mensajes ya cumple.

## Decisión
- El punto de entrada de RabbitMQ que reparte las líneas de pago pasa a tener tres destinos posibles (dentro del banco, hacia otro banco, o inválida), cada uno a su propia cola. file-reception-service, que ya calculaba esa clasificación con su catálogo, decide a cuál de los tres pertenece cada línea al publicarla; RabbitMQ entrega cada mensaje a la cola correspondiente sin que ningún otro servicio tenga que volver a evaluarlo.
- Toda la lógica de coordinación del lote que vivía en el servicio de ruteo (evitar procesar la misma línea dos veces, el débito inicial del lote, el crédito dentro del banco llamando a account-core-service, adaptar y publicar los pagos hacia otro banco, calcular la comisión llamando a tariff-service, devolver los rechazados, y llevar el estado del lote) se mueve a file-reception-service, que ahora consume directamente las tres colas.
- account-core-service (Core) no cambia: sigue siendo un sistema pasivo que solo expone sus endpoints, tal como exige el documento de requisitos: el Core actúa como un sistema pasivo y subordinado a las instrucciones del Switch.
- El microservicio de ruteo se elimina por completo de la infraestructura. Su endpoint para consultar el estado de un lote se mueve a file-reception-service.

## Por qué file-reception-service y no account-core-service
Se evaluó mover esta lógica a account-core-service, pero el documento de requisitos del Core es explícito: el Core debe ser pasivo, y es el Switch quien coordina y llama a su API. Mover la coordinación al Core invertiría esa relación documentada. file-reception-service ya es dueño del catálogo de clasificación y del ciclo de vida del lote y del archivo, así que absorber el despacho de las líneas es una extensión natural de lo que ya hacía, sin inventar un nuevo microservicio ni tocar el Core.

## Consecuencias
- A favor: se elimina un microservicio completo — menos piezas que mantener, menos superficie que desplegar.
- A favor: el ruteo real, a qué cola llega cada mensaje, ahora lo hace exclusivamente RabbitMQ, no código de la aplicación.
- A favor: se elimina un salto de red innecesario — file-reception-service ya no necesita llamarse a sí mismo para el crédito dentro del banco, ahora llama directo a account-core-service.
- En contra: file-reception-service gana más responsabilidades (guardar el estado del lote en Mongo, además de llamar a tariff-service y a notification-service), acercándose a ser el servicio más grande del dominio Switch — aceptado porque esas responsabilidades son parte natural del ciclo de vida del lote, que este servicio ya coordinaba.
