# Switch de Pagos Masivos BanQuito — C1 (Contexto)

```mermaid
C4Context
    title Diagrama de Contexto — Switch de Pagos Masivos BanQuito

    Person(clienteEmpresarial, "Cliente Empresarial", "Sube archivos de nómina/pagos masivos y consulta su estado")
    Person(operador, "Operador", "Gestiona la compensación interbancaria")

    System(switchPagos, "Switch de Pagos Masivos BanQuito", "Recibe, valida, enruta y liquida lotes de pagos masivos on-us y off-us")

    System_Ext(core, "Core Bancario BanQuito", "Valida cuentas, debita el monto declarado y acredita/devuelve según el resultado del lote")
    System_Ext(bancoCentral, "Banco Central", "Recibe los archivos de compensación de transacciones off-us (interbancarias)")

    Rel(clienteEmpresarial, switchPagos, "Sube lote, consulta estado, descarga comprobantes", "HTTPS")
    Rel(operador, switchPagos, "Gestiona compensación interbancaria", "HTTPS")
    Rel(switchPagos, core, "Valida cuenta, debita declarado, acredita on-us, devuelve rechazadas", "HTTPS/REST")
    Rel(switchPagos, bancoCentral, "Envía archivo de compensación off-us", "Archivo (CSV/TXT/PDF)")
```

## Lectura del diagrama

- El **Cliente Empresarial** es quien opera el flujo de negocio principal: sube el archivo, consulta el avance y descarga comprobantes.
- El Switch **orquesta** al Core Bancario (lo consume, nunca al revés — ver ADR 011), a diferencia de una arquitectura donde el routing lo haría un microservicio propio: aquí ese enrutamiento lo resuelve RabbitMQ internamente (ver C2).
- **Banco Central** es el sistema externo con el que se liquidan las transacciones off-us (cuentas de otros bancos).
