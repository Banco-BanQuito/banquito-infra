# ADR-010: Idempotencia de operaciones financieras vía UUID de transacción

## Estado
Aceptado

## Contexto
En un sistema distribuido con reintentos de red, colas de mensajes y procesamiento asíncrono, la misma instrucción de pago puede llegar más de una vez al Core (ej. un cliente HTTP reintenta tras un timeout, o un consumidor de RabbitMQ reprocesa un mensaje no confirmado). Sin control de duplicados, esto generaría débitos o créditos dobles.

## Decisión
Toda operación financiera (depósito, retiro, transferencia P2P, transferencia externa, crédito de nómina) exige un `transactionUuid` generado por el cliente/origen de la instrucción. Antes de aplicar el movimiento, `account-core-service` verifica si ya existe una transacción con ese UUID; si existe, la petición se considera ya procesada y no se repite el efecto financiero.

## Por qué UUID generado por el origen y no un ID autogenerado por el servidor
Si el ID lo generara el servidor, un cliente que no recibe la respuesta (por timeout de red) no tendría forma de saber si su operación ya se aplicó antes de reintentar. Generar el UUID en el origen (Banca Web, Ventanilla, o el propio Switch) permite que el reintento use el **mismo** UUID, y el servidor pueda reconocerlo como duplicado de forma segura.

## Consecuencias
- (+) Reintentos de red, archivos duplicados, o reprocesamiento de un mensaje de RabbitMQ no generan dinero ni lo destruyen.
- (+) Es la base que permitió descubrir y corregir en pruebas un bug de generación de UUID en navegador (`crypto.randomUUID` no disponible en contexto HTTP no seguro), que de no existir esta verificación habría sido más difícil de detectar (los duplicados habrían pasado silenciosamente como transacciones nuevas).
- (-) Exige que todo cliente (frontend o servicio) que inicie una operación financiera implemente correctamente la generación de un UUID único y estable por intento, incluyendo un mecanismo de respaldo si la API nativa del navegador no está disponible.
