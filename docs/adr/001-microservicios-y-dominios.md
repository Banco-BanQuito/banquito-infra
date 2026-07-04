# ADR-001: División en microservicios y separación de dominios (Core / Switch)

## Estado
Aceptado

## Contexto
La Fase 1 del proyecto era un monolito que mezclaba la lógica de cuentas, contabilidad y pagos masivos en un solo proceso. Esto impedía escalar cada parte de forma independiente y acoplaba el ciclo de despliegue de funcionalidades con ritmos de cambio muy distintos (el Core cambia poco, el Switch de Pagos cambia con cada nueva integración bancaria).

## Decisión
Se divide el sistema en **9 microservicios** agrupados en dos dominios (Bounded Contexts):

**Dominio Core (banca tradicional):**
- `account-core-service`: cuentas, saldos, ventanilla, transferencias P2P y externas.
- `accounting-service`: libro mayor, partida doble, EOD, Balance de Comprobación.
- `party-service`: clientes, sucursales, feriados, autenticación de canales.

**Dominio Switch (pagos masivos e interbancarios):**
- `file-reception-service`: recepción y validación estructural de archivos.
- `routing-service`: enrutamiento dinámico On-Us/Off-Us.
- `tariff-service`: cálculo de comisiones.
- `clearinghouse-service`: simulación de la Cámara de Compensación / Banco Central.
- `report-service`: comprobantes y reportes de novedades.
- `notification-service`: envío de notificaciones a beneficiarios.

Cada microservicio tiene **su propia base de datos** (Database per Service) y expone únicamente su propia API; no hay acceso directo a la base de datos de otro servicio.

## Por qué esta cantidad y no más/menos
- Se separó por **responsabilidad transaccional distinta**: el Core necesita consistencia fuerte e inmediata (afecta dinero real); el Switch necesita alto volumen y tolerancia a fallos parciales (un archivo de 100k líneas no debe bloquear el Core).
- `accounting-service` se separó de `account-core-service` porque el documento de requisitos exige que sean **contextos delimitados independientes** con bases de datos propias, y porque la contabilidad de partida doble tiene reglas de negocio (Plan de Cuentas, cuadre) que no dependen de cómo se calculan los saldos del cliente.
- `tariff-service`, `notification-service` y `clearinghouse-service` se separaron del `routing-service` porque cada uno tiene un ciclo de cambio distinto (la lógica de comisión cambia con frecuencia comercial; la integración con el Banco Central cambia por regulación).

## Consecuencias
- (+) Cada equipo/feature puede desplegar su servicio sin afectar a los demás.
- (+) Permite políticas de escalado y persistencia distintas por servicio (ver ADR-002).
- (-) Aumenta la complejidad operativa (9 servicios + 4 frontends + gateway + broker).
- (-) Requiere comunicación inter-servicio bien definida (ver ADR-003 y ADR-004).
