# Switch de Pagos Masivos BanQuito — C2 (Contenedores)

```mermaid
C4Container
    title Diagrama de Contenedores — Switch de Pagos Masivos BanQuito

    Person(clienteEmpresarial, "Cliente Empresarial")
    Person(operador, "Operador")
    System_Ext(core, "Core Bancario BanQuito")
    System_Ext(bancoCentral, "Banco Central")

    Container_Boundary(switchPagos, "Switch de Pagos Masivos BanQuito") {
        Container(empresasFrontend, "Web Empresas Frontend", "React + Vite", "Carga de lotes y seguimiento para el cliente empresarial")
        Container(operadorFrontend, "Operador Frontend", "React + Vite", "Gestión de compensación interbancaria (Banco Central)")
        Container(kongSwitch, "Kong Switch", "Kong API Gateway", "Enrutamiento, autenticación JWT y CORS para el dominio Switch")
        Container(fileReception, "file-reception-service", "Spring Boot", "Recibe, valida cabecera/pie, despacha y liquida cada línea del lote")
        Container(tariff, "tariff-service", "Spring Boot", "Calcula comisión e IVA por lote procesado")
        Container(clearinghouse, "clearinghouse-service", "Spring Boot", "Compensación interbancaria off-us hacia el Banco Central")
        Container(report, "report-service", "Spring Boot", "Genera reportes de novedades y comprobantes de lote")
        Container(notification, "notification-service", "Spring Boot", "Envía notificaciones por correo a beneficiarios")
        ContainerQueue(rabbit, "RabbitMQ", "AMQP", "payment.exchange (on-us/off-us/inválidas) y clearing.exchange")
        ContainerDb(mongo, "MongoDB", "MongoDB Atlas", "Lotes, detalles, notificaciones y reportes")
        ContainerDb(tariffDb, "tariffdb", "MySQL", "Rangos y reglas de tarifas")
    }

    Rel(clienteEmpresarial, empresasFrontend, "Usa", "HTTPS")
    Rel(operador, operadorFrontend, "Usa", "HTTPS")

    Rel(empresasFrontend, kongSwitch, "Solicita", "HTTPS/REST")
    Rel(operadorFrontend, kongSwitch, "Solicita", "HTTPS/REST")

    Rel(kongSwitch, fileReception, "Enruta carga y estado de lote", "REST")
    Rel(kongSwitch, report, "Enruta reportes y comprobantes", "REST")
    Rel(kongSwitch, core, "Enruta consulta de cuentas", "REST")

    Rel(fileReception, rabbit, "Publica líneas on-us/off-us/inválidas", "AMQP")
    Rel(fileReception, rabbit, "Consume sus propias colas", "AMQP")
    Rel(fileReception, rabbit, "Publica transacción off-us", "AMQP (clearing.exchange)")
    Rel(fileReception, tariff, "Calcula comisión del lote", "gRPC")
    Rel(fileReception, notification, "Envía notificación de crédito", "gRPC")
    Rel(fileReception, mongo, "Lee/escribe lote y detalle", "Driver MongoDB")
    Rel(fileReception, core, "Valida cuenta, debita declarado, acredita on-us, devuelve rechazadas", "HTTPS/REST")

    Rel(clearinghouse, rabbit, "Consume clearing.outbound.queue", "AMQP")
    Rel(clearinghouse, core, "Registra asiento contable off-us", "HTTPS/REST")
    Rel(clearinghouse, bancoCentral, "Envía archivo de compensación", "Archivo (CSV/TXT/PDF)")
    Rel(clearinghouse, mongo, "Lee/escribe transacciones de compensación", "Driver MongoDB")

    Rel(report, mongo, "Lee lotes, detalles y notificaciones", "Driver MongoDB")
    Rel(report, notification, "Reenvía notificación", "gRPC")

    Rel(tariff, tariffDb, "Lee/escribe", "JDBC")
    Rel(notification, mongo, "Guarda notificaciones", "Driver MongoDB")
```

## Lectura del diagrama

- El **enrutamiento on-us/off-us/inválidas** no lo hace un microservicio propio: lo resuelve `payment.exchange` de **RabbitMQ** mediante *routing keys*, y `file-reception-service` es quien publica y consume esas colas (ver ADR 011 — eliminación de routing-service).
- `file-reception-service` es el contenedor con más responsabilidad: valida el lote, debita el monto **declarado** en cabecera/pie al aceptar el archivo, procesa cada línea, y al completar el lote devuelve el monto de las líneas **rechazadas** como un movimiento independiente del cobro de comisión.
- `clearinghouse-service` es quien realmente "sale" del banco: solo él habla con el **Banco Central** (vía archivo) y solo él consume la cola de compensación off-us.
- `tariff-service` y `notification-service` se comunican por **gRPC** (RPC binario de baja latencia), mientras que la integración con el Core y el Banco Central es por **REST/archivo** — refleja que son límites de sistema distintos.
