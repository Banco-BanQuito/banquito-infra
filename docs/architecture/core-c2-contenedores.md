# Core Bancario BanQuito — C2 (Contenedores)

```mermaid
C4Container
    title Diagrama de Contenedores — Core Bancario BanQuito

    Person(cajero, "Cajero")
    Person(clientePersona, "Cliente (Banca Personas)")
    Person(operador, "Operador")
    System_Ext(switchPagos, "Switch de Pagos Masivos")

    Container_Boundary(core, "Core Bancario BanQuito") {
        Container(tellerFrontend, "Teller Frontend", "React + Vite", "Interfaz de ventanilla para el cajero")
        Container(personasFrontend, "Web Personas Frontend", "React + Vite", "Banca en línea para clientes individuales")
        Container(operadorFrontend, "Operador Frontend", "React + Vite", "Intranet de administración de clientes y cuentas")
        Container(kongCore, "Kong Core", "Kong API Gateway", "Enrutamiento, autenticación JWT y CORS para el dominio Core")
        Container(accountCore, "account-core-service", "Spring Boot", "Cuentas, transacciones, saldos, particionamiento caliente/frío")
        Container(accounting, "accounting-service", "Spring Boot", "Motor contable de partida doble, reglas y asientos")
        Container(party, "party-service", "Spring Boot", "Clientes, sucursales, feriados, credenciales web")
        ContainerDb(accountDb, "accountdb / accountingdb", "PostgreSQL", "Cuentas, transacciones y asientos contables")
        ContainerDb(partyDb, "partydb", "MySQL", "Clientes, sucursales, credenciales")
    }

    Rel(cajero, tellerFrontend, "Usa", "HTTPS")
    Rel(clientePersona, personasFrontend, "Usa", "HTTPS")
    Rel(operador, operadorFrontend, "Usa", "HTTPS")

    Rel(tellerFrontend, kongCore, "Solicita", "HTTPS/REST")
    Rel(personasFrontend, kongCore, "Solicita", "HTTPS/REST")
    Rel(operadorFrontend, kongCore, "Solicita", "HTTPS/REST")

    Rel(kongCore, accountCore, "Enruta", "REST")
    Rel(kongCore, party, "Enruta", "REST")

    Rel(accountCore, accounting, "Registra asiento contable", "gRPC")
    Rel(accountCore, party, "Valida cliente y sucursal", "gRPC")
    Rel(accountCore, accountDb, "Lee/escribe", "JDBC")
    Rel(accounting, accountDb, "Lee/escribe", "JDBC")
    Rel(party, partyDb, "Lee/escribe", "JDBC")

    Rel(switchPagos, accountCore, "Valida cuenta, debita, acredita, devuelve", "HTTPS/REST")
```

## Lectura del diagrama

- **Colores por rol** (convención C4): interfaces de usuario (teal), lógica de negocio (morado), datos (ámbar), externos (coral) — no se muestran clases de color explícitas porque el renderer de GitHub usa su propia paleta por defecto para `C4Container`.
- `account-core-service` es el corazón del dominio: habla por **gRPC** con `accounting-service` (para contabilizar cada movimiento) y con `party-service` (para validar el cliente dueño de la cuenta).
- `operador-frontend` también se conecta al Switch (`clearinghouse-service`) para la sección de Banco Central, pero esa relación se documenta en el diagrama del Switch para no mezclar dominios en este C2.
- `Kong Core` es el único punto de entrada público hacia los tres microservicios del dominio Core.
