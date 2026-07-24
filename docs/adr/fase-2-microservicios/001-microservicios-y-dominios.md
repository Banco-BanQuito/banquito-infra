# ADR-001: División en microservicios y separación de dominios (Core / Switch)

## Estado
Aceptado

## Contexto
La Fase 1 del proyecto era un monolito que mezclaba la lógica de cuentas, contabilidad y pagos masivos en un solo proceso. Esto impedía escalar cada parte de forma independiente y acoplaba el ciclo de despliegue de funcionalidades con ritmos de cambio muy distintos: el Core cambia poco, el Switch de Pagos cambia con cada nueva integración bancaria.

## Decisión
Se divide el sistema en **8 microservicios** agrupados en dos dominios:

**Dominio Core (banca tradicional):**
- account-core-service: cuentas, saldos, ventanilla, transferencias entre clientes del banco y hacia otros bancos.
- accounting-service: libro mayor, partida doble, cierre del día, Balance de Comprobación.
- party-service: clientes, sucursales, feriados, autenticación de canales.

**Dominio Switch (pagos masivos e interbancarios):**
- file-reception-service: recepción y validación de archivos, clasificación entre pagos dentro del mismo banco y hacia otros bancos, y despacho de las líneas de pago (ver ADR-011: no existe un microservicio de ruteo separado).
- tariff-service: cálculo de comisiones.
- clearinghouse-service: simulación de la Cámara de Compensación y el Banco Central.
- report-service: comprobantes y reportes de novedades.
- notification-service: envío de notificaciones a beneficiarios.

Cada microservicio tiene **su propia base de datos** y expone únicamente su propia API; no hay acceso directo a la base de datos de otro servicio.

## Por qué esta cantidad y no más o menos
- Se separó por **responsabilidad transaccional distinta**: el Core necesita consistencia fuerte e inmediata porque afecta dinero real; el Switch necesita alto volumen y tolerancia a fallos parciales, porque un archivo de 100 mil líneas no debe bloquear al Core.
- accounting-service se separó de account-core-service porque el documento de requisitos exige que sean contextos independientes con bases de datos propias, y porque la contabilidad de partida doble tiene reglas de negocio propias (Plan de Cuentas, cuadre contable) que no dependen de cómo se calculan los saldos del cliente.
- tariff-service, notification-service y clearinghouse-service se mantienen separados de file-reception-service porque cada uno cambia a un ritmo distinto: la comisión cambia con frecuencia comercial, la integración con el Banco Central cambia por regulación. Ver ADR-010 sobre por qué el despacho de pagos vive en file-reception-service y no en un microservicio de ruteo aparte.

## Consecuencias
- A favor: cada equipo puede desplegar su servicio sin afectar a los demás.
- A favor: permite políticas de escalado y de base de datos distintas por servicio (ver ADR-002).
- En contra: aumenta la complejidad operativa — son 9 servicios más 4 frontends más el gateway más el broker de mensajes.
- En contra: requiere comunicación entre servicios bien definida (ver ADR-003 y ADR-004).
