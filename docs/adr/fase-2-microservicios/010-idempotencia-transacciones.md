# ADR-010: Idempotencia de operaciones financieras vía UUID de transacción

## Estado
Aceptado

## Contexto
En un sistema distribuido con reintentos de red, colas de mensajes y procesamiento asíncrono, la misma instrucción de pago puede llegar más de una vez al Core (ej. un cliente HTTP reintenta tras un timeout, o un consumidor de RabbitMQ reprocesa un mensaje no confirmado). Sin control de duplicados, esto generaría débitos o créditos dobles.

## Decisión
Toda operación financiera (depósito, retiro, transferencia entre clientes, transferencia externa, crédito de nómina) exige un identificador único generado por quien origina la instrucción. Antes de aplicar el movimiento, account-core-service verifica si ya existe una transacción con ese identificador; si ya existe, la petición se considera ya procesada y no se repite el efecto financiero.

## Por qué el identificador lo genera el origen y no el servidor
Si el identificador lo generara el servidor, un cliente que no recibe la respuesta a tiempo, por ejemplo por un problema de red, no tendría forma de saber si su operación ya se aplicó antes de volver a intentarlo. Generar el identificador desde el origen (Banca Web, Ventanilla, o el propio Switch) permite que el reintento use el mismo identificador de siempre, y el servidor pueda reconocerlo como algo repetido de forma segura.

## Consecuencias
- A favor: los reintentos por fallos de red, archivos duplicados, o el reprocesamiento de un mensaje de la cola no generan dinero de más ni lo destruyen.
- A favor: este control permitió descubrir y corregir en pruebas un error real en la forma en que el navegador generaba este identificador (fallaba en conexiones sin HTTPS) — sin este control, ese error habría pasado desapercibido, como transacciones nuevas en vez de duplicadas.
- En contra: exige que todo cliente que inicie una operación financiera, sea un frontend o un servicio, genere correctamente un identificador único y estable por cada intento, con un mecanismo de respaldo si la función normal del navegador no está disponible.
