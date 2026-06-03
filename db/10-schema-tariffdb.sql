-- ══════════════════════════════════════════════════════════════════════════
-- PASO 10 — Schema tariffdb (Johan — tariff-service + clearinghouse-adapter)
-- ══════════════════════════════════════════════════════════════════════════
\c tariffdb

-- Tipos de servicio del Switch
CREATE TABLE switch_service_type (
    id                  SERIAL        PRIMARY KEY,
    name                VARCHAR(100)  NOT NULL,
    max_amount_per_tx   NUMERIC(15,2),
    status              VARCHAR(15)   NOT NULL DEFAULT 'ACTIVO',
    creation_date       TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- Empresa habilitada para usar el servicio de pagos masivos
CREATE TABLE switch_customer_service (
    id                      SERIAL        PRIMARY KEY,
    customer_id             INT           NOT NULL,          -- ref a partydb.customer.id
    service_type_id         INT           NOT NULL REFERENCES switch_service_type(id),
    default_main_account    INT,                             -- ref a accountdb.account.id (cuenta concentradora)
    status                  VARCHAR(15)   NOT NULL DEFAULT 'ACTIVO',
    max_annual_per_payment  NUMERIC(15,2),
    last_update             TIMESTAMP     NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_scs_customer ON switch_customer_service(customer_id);

-- Restricciones adicionales por servicio habilitado
CREATE TABLE customer_allowed_service (
    id                    SERIAL         PRIMARY KEY,
    service_type_id       INT            NOT NULL REFERENCES switch_service_type(id),
    status                VARCHAR(15)    NOT NULL DEFAULT 'ACTIVO',
    assigned_date         TIMESTAMP      NOT NULL DEFAULT NOW()
);

-- Relación entre tipo de servicio y cuentas contables (qué asiento genera)
CREATE TABLE service_accounting_entry (
    id                       SERIAL         PRIMARY KEY,
    service_charge_id        BIGINT,
    institutional_account_id INT,           -- ref a accountdb.institutional_account.id
    accounting_account_code  VARCHAR(20),   -- código del plan de cuentas
    amount                   NUMERIC(10,2),
    movement_type            VARCHAR(10)    NOT NULL CHECK (movement_type IN ('DEBITO','CREDITO')),
    registered_at            TIMESTAMP      NOT NULL DEFAULT NOW()
);

-- Rangos de tarifa escalonada (min/max transacciones exitosas → precio unitario)
CREATE TABLE payment_tariff (
    id                 SERIAL         PRIMARY KEY,
    min_successful_tx  INT            NOT NULL,
    max_successful_tx  INT            NOT NULL,
    unit_fee           NUMERIC(10,4)  NOT NULL,
    status             VARCHAR(15)    NOT NULL DEFAULT 'ACTIVO',
    valid_from         TIMESTAMP      NOT NULL DEFAULT NOW(),
    valid_to           TIMESTAMP,
    CONSTRAINT chk_range CHECK (min_successful_tx <= max_successful_tx)
);

-- Registro del cobro calculado por lote
CREATE TABLE service_charge (
    id                   BIGSERIAL      PRIMARY KEY,
    payment_batch_id     VARCHAR(36)    NOT NULL,
    payment_tariff_id    INT            NOT NULL REFERENCES payment_tariff(id),
    successful_tx        INT            NOT NULL,
    unit_fee             NUMERIC(10,4)  NOT NULL,
    commission_subtotal  NUMERIC(15,2)  NOT NULL,
    iva_rate             NUMERIC(5,4)   NOT NULL DEFAULT 0.15,
    iva_amount           NUMERIC(15,2)  NOT NULL,
    total_charge         NUMERIC(15,2)  NOT NULL,
    status               VARCHAR(15)    NOT NULL DEFAULT 'CALCULADO',
    calculated_at        TIMESTAMP      NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sc_batch ON service_charge(payment_batch_id);
