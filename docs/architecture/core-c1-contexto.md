# Core Bancario BanQuito — C1 (Contexto)

```mermaid
C4Context
    title Diagrama de Contexto — Core Bancario BanQuito

    Person(cajero, "Cajero", "Opera transacciones de ventanilla: depósitos y retiros")
    Person(clientePersona, "Cliente (Banca Personas)", "Consulta saldos, hace transferencias P2P")
    Person(operador, "Operador", "Administra clientes, cuentas, sucursales y feriados")

    System(core, "Core Bancario BanQuito", "Gestiona cuentas, clientes, transacciones y contabilidad del banco")

    System_Ext(switchPagos, "Switch de Pagos Masivos", "Sistema externo que consume el Core para validar cuentas y ejecutar débitos/créditos de nómina")

    Rel(cajero, core, "Deposita y retira", "HTTPS")
    Rel(clientePersona, core, "Consulta saldo, transfiere", "HTTPS")
    Rel(operador, core, "Administra clientes y cuentas", "HTTPS")
    Rel(switchPagos, core, "Valida cuentas, debita y acredita por lotes de nómina", "HTTPS/REST")
```

## Lectura del diagrama

- **Cajero**, **Cliente (Banca Personas)** y **Operador** son los tres roles humanos que interactúan directamente con el Core.
- El Core es un sistema **pasivo**: no inicia comunicación hacia el Switch, solo responde a sus solicitudes (ver ADR 001 y ADR 011 de este repositorio).
- El **Switch de Pagos Masivos** es el único sistema externo relevante: valida cuentas y ejecuta movimientos de nómina masiva contra el Core, pero el Core no conoce ni depende de su lógica interna.
