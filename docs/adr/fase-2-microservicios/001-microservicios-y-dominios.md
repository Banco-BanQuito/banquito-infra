# ADR-001: Por qué 8 microservicios específicos, y no solo el mínimo pedido

## Estado
Aceptado

## Contexto
Los documentos de requisitos de esta fase ya exigen dividir el sistema en microservicios — no fue una decisión libre del equipo. El Core V2 pide, como mínimo, dos: un microservicio Transaccional (Cuentas y Saldos) y un microservicio Contable (Libro Mayor), cada uno con su propia base de datos. El Switch V2 pide dividir el Switch en microservicios también, dando como ejemplo "Servicio de Recepción de Archivos" y "Servicio de Enrutamiento".

Lo que sí fue decisión del equipo es que el sistema terminó con **8** microservicios, no el mínimo de 2 pedido para el Core, y con una división del Switch distinta a la que el documento sugería como ejemplo (ver ADR-008, donde el equipo decidió no construir el "Servicio de Enrutamiento" sugerido). Este ADR documenta esas decisiones específicas: por qué separar party-service del resto del Core, y por qué el Switch terminó en 5 servicios y no en los 2 del ejemplo.

## Decisión
Se divide el sistema en **8 microservicios** agrupados en dos dominios:

**Dominio Core (banca tradicional):**
- account-core-service: cuentas, saldos, ventanilla, transferencias entre clientes del banco y hacia otros bancos.
- accounting-service: libro mayor, partida doble, cierre del día, Balance de Comprobación.
- party-service: clientes, sucursales, feriados, autenticación de canales.

**Dominio Switch (pagos masivos e interbancarios):**
- file-reception-service: recepción y validación de archivos, clasificación entre pagos dentro del mismo banco y hacia otros bancos, y despacho de las líneas de pago (ver ADR-008: no existe un microservicio de ruteo separado).
- tariff-service: cálculo de comisiones.
- clearinghouse-service: simulación de la Cámara de Compensación y el Banco Central.
- report-service: comprobantes y reportes de novedades.
- notification-service: envío de notificaciones a beneficiarios.

Cada microservicio tiene **su propia base de datos** y expone únicamente su propia API; no hay acceso directo a la base de datos de otro servicio.

## Por qué esta cantidad y no solo el mínimo pedido
- account-core-service y accounting-service son la división mínima que el documento de requisitos exige (Transaccional / Contable) — esa parte no fue decisión del equipo.
- party-service sí fue decisión del equipo: el documento no lo pide como microservicio aparte, pero se separó de account-core-service porque clientes, sucursales y feriados cambian a un ritmo y con reglas propias que no dependen de cómo se calculan los saldos.
- El Switch se dividió en 5 servicios (file-reception, tariff, clearinghouse, report, notification) en vez de los 2 que el documento daba como ejemplo, porque cada uno cambia a un ritmo distinto: la comisión cambia con frecuencia comercial, la integración con el Banco Central cambia por regulación. Ver ADR-008 sobre por qué, además, el equipo decidió no construir el "Servicio de Enrutamiento" que el documento sugería como ejemplo, y en su lugar esa lógica vive en file-reception-service.

## Consecuencias
- A favor: cada equipo puede desplegar su servicio sin afectar a los demás.
- A favor: permite políticas de escalado y de base de datos distintas por servicio (ver ADR-002).
- En contra: aumenta la complejidad operativa — son 9 servicios más 4 frontends más el gateway más el broker de mensajes.
- En contra: requiere comunicación entre servicios bien definida (ver ADR-003 y ADR-004).
