-- ══════════════════════════════════════════════════════════════════════════
-- PASO 4 — Schema accountingdb (Bryan — accounting-service)
-- Tablas exactas del Anexo 1 del documento Core V2
-- ══════════════════════════════════════════════════════════════════════════
\c accountingdb

-- Árbol contable — Plan Único de Cuentas
-- ACCOUNT_TYPE: 'ESTRUCTURAL' (no recibe asientos) | 'DETALLE' (nodo hoja, sí recibe)
CREATE TABLE accounting_account (
    account_code         VARCHAR(20)   PRIMARY KEY,
    name                 VARCHAR(100)  NOT NULL,
    account_class        VARCHAR(15)   NOT NULL,          -- ACTIVO | PASIVO | INGRESO | GASTO
    account_type         VARCHAR(15)   NOT NULL CHECK (account_type IN ('ESTRUCTURAL','DETALLE')),
    parent_account_code  VARCHAR(20)   REFERENCES accounting_account(account_code),  -- FK recursiva
    current_balance      DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    creation_date        TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_aa_parent ON accounting_account(parent_account_code);

-- Cabecera del asiento contable
CREATE TABLE journal_entry (
    id          BIGSERIAL    PRIMARY KEY,
    entry_uuid  VARCHAR(36)  NOT NULL UNIQUE,    -- UUID de la transacción que lo originó
    description VARCHAR(255) NOT NULL,
    entry_date  TIMESTAMP    NOT NULL DEFAULT NOW(),
    status      VARCHAR(15)  NOT NULL DEFAULT 'REGISTRADO' CHECK (status IN ('REGISTRADO','ANULADO'))
);

CREATE INDEX idx_je_uuid ON journal_entry(entry_uuid);
CREATE INDEX idx_je_date ON journal_entry(entry_date);

-- Líneas del asiento (las "patas") — suma(DEBITOS) debe = suma(CREDITOS)
CREATE TABLE journal_entry_line (
    id               BIGSERIAL    PRIMARY KEY,
    journal_entry_id BIGINT       NOT NULL REFERENCES journal_entry(id),
    account_code     VARCHAR(20)  NOT NULL REFERENCES accounting_account(account_code),
    movement_type    VARCHAR(10)  NOT NULL CHECK (movement_type IN ('DEBITO','CREDITO')),
    amount           DECIMAL(15,2) NOT NULL CHECK (amount > 0),
    reference        VARCHAR(255)
);

CREATE INDEX idx_jel_entry   ON journal_entry_line(journal_entry_id);
CREATE INDEX idx_jel_account ON journal_entry_line(account_code);
