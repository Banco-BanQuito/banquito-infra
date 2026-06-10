-- ══════════════════════════════════════════════════════════════════════════
-- PASO 2 — Schema accountdb (Oscar — account-core-service)
-- ══════════════════════════════════════════════════════════════════════════
\c accountdb

-- Subtipos de cuenta (Ahorros, Corriente, Nómina, Impuestos, Operativa)
CREATE TABLE account_subtype (
    id               SERIAL PRIMARY KEY,
    super_type       VARCHAR(15)  NOT NULL,
    name             VARCHAR(100) NOT NULL,
    description      VARCHAR(50),
    status           VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    observations     VARCHAR(255),
    creation_date    TIMESTAMP    NOT NULL DEFAULT NOW(),
    version          INT          NOT NULL DEFAULT 1
);

-- Subtipos de transacción (depósito, retiro, P2P, nómina, etc.)
CREATE TABLE transaction_subtype (
    id            SERIAL PRIMARY KEY,
    code          VARCHAR(20)  NOT NULL UNIQUE,
    name          VARCHAR(100) NOT NULL,
    status        VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    creation_date TIMESTAMP    NOT NULL DEFAULT NOW(),
    version       INT          NOT NULL DEFAULT 1
);

-- Cuentas de clientes
CREATE TABLE account (
    id                 SERIAL PRIMARY KEY,
    account_number     VARCHAR(20)    NOT NULL UNIQUE,
    customer_id        INT            NOT NULL,          -- ref lógica a partydb.customer.id
    branch_id          INT            NOT NULL,          -- ref lógica a partydb.branch.id
    account_subtype_id INT            NOT NULL REFERENCES account_subtype(id),
    accounting_balance DECIMAL(15,2)  NOT NULL DEFAULT 0.00,
    available_balance  DECIMAL(15,2)  NOT NULL DEFAULT 0.00,
    is_favorite        BOOLEAN        NOT NULL DEFAULT FALSE,
    status             VARCHAR(15)    NOT NULL DEFAULT 'ACTIVA',
    opening_date       DATE           NOT NULL DEFAULT CURRENT_DATE,
    last_update        TIMESTAMP      NOT NULL DEFAULT NOW(),
    version            INT            NOT NULL DEFAULT 1
);

CREATE INDEX idx_account_customer    ON account(customer_id);
CREATE INDEX idx_account_number      ON account(account_number);

-- Movimientos transaccionales — PARTICIONADA POR MES (RF-05 Core)
CREATE TABLE account_transaction (
    id                       BIGSERIAL,
    account_id               INT            NOT NULL,
    transaction_subtype_id   INT            REFERENCES transaction_subtype(id),
    transaction_uuid         VARCHAR(36)    NOT NULL,
    movement_type            VARCHAR(10)    NOT NULL CHECK (movement_type IN ('DEBITO','CREDITO')),
    amount                   DECIMAL(15,2)  NOT NULL,
    resulting_balance        DECIMAL(15,2)  NOT NULL,
    status                   VARCHAR(15)    NOT NULL DEFAULT 'COMPLETADA',
    description              VARCHAR(255),
    transaction_date         TIMESTAMP      NOT NULL DEFAULT NOW(),  -- fecha real del servidor
    accounting_date          DATE           NOT NULL,                 -- fecha contable (puede ser T+1)
    version                  INT            NOT NULL DEFAULT 1,
    PRIMARY KEY (id, transaction_date)
) PARTITION BY RANGE (transaction_date);

-- Particiones mensuales 2026 (data caliente)
CREATE TABLE account_transaction_2026_01 PARTITION OF account_transaction FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
CREATE TABLE account_transaction_2026_02 PARTITION OF account_transaction FOR VALUES FROM ('2026-02-01') TO ('2026-03-01');
CREATE TABLE account_transaction_2026_03 PARTITION OF account_transaction FOR VALUES FROM ('2026-03-01') TO ('2026-04-01');
CREATE TABLE account_transaction_2026_04 PARTITION OF account_transaction FOR VALUES FROM ('2026-04-01') TO ('2026-05-01');
CREATE TABLE account_transaction_2026_05 PARTITION OF account_transaction FOR VALUES FROM ('2026-05-01') TO ('2026-06-01');
CREATE TABLE account_transaction_2026_06 PARTITION OF account_transaction FOR VALUES FROM ('2026-06-01') TO ('2026-07-01');
CREATE TABLE account_transaction_2026_07 PARTITION OF account_transaction FOR VALUES FROM ('2026-07-01') TO ('2026-08-01');
CREATE TABLE account_transaction_2026_08 PARTITION OF account_transaction FOR VALUES FROM ('2026-08-01') TO ('2026-09-01');
CREATE TABLE account_transaction_2026_09 PARTITION OF account_transaction FOR VALUES FROM ('2026-09-01') TO ('2026-10-01');
CREATE TABLE account_transaction_2026_10 PARTITION OF account_transaction FOR VALUES FROM ('2026-10-01') TO ('2026-11-01');
CREATE TABLE account_transaction_2026_11 PARTITION OF account_transaction FOR VALUES FROM ('2026-11-01') TO ('2026-12-01');
CREATE TABLE account_transaction_2026_12 PARTITION OF account_transaction FOR VALUES FROM ('2026-12-01') TO ('2027-01-01');
-- Partición default para datos fuera de rango (data fría histórica)
CREATE TABLE account_transaction_historical PARTITION OF account_transaction DEFAULT;

-- Índices en partición activa
CREATE INDEX idx_at_account    ON account_transaction(account_id, transaction_date);
CREATE INDEX idx_at_uuid       ON account_transaction(transaction_uuid);
CREATE INDEX idx_at_acct_date  ON account_transaction(accounting_date);

-- Cuentas institucionales del banco (Bóveda, Banco Central, IVA, Ingresos)
CREATE TABLE institutional_account (
    id                 SERIAL PRIMARY KEY,
    account_number     VARCHAR(20)   NOT NULL UNIQUE,
    name               VARCHAR(100)  NOT NULL,
    accounting_balance DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    creation_date      TIMESTAMP     NOT NULL DEFAULT NOW(),
    version            INT           NOT NULL DEFAULT 1
);

-- Días feriados (para calcular día hábil siguiente al corte)
CREATE TABLE holiday (
    holiday_date  DATE         PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    is_weekend    BOOLEAN      NOT NULL DEFAULT FALSE,
    creation_date TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Parámetros configurables del Core (fecha contable activa, hora de corte)
CREATE TABLE core_parameter (
    code         VARCHAR(50)  PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    value_string VARCHAR(255) NOT NULL,
    data_type    VARCHAR(15)  NOT NULL,
    description  VARCHAR(255),
    last_update  TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Usuarios del sistema de Ventanilla (cajeros)
CREATE TABLE core_user (
    id            SERIAL PRIMARY KEY,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    full_name     VARCHAR(100) NOT NULL,
    role          VARCHAR(15)  NOT NULL DEFAULT 'CAJERO',
    status        VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    last_login    TIMESTAMP,
    creation_date TIMESTAMP    NOT NULL DEFAULT NOW(),
    version       INT          NOT NULL DEFAULT 1
);
