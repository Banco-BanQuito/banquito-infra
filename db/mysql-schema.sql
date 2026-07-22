-- ══════════════════════════════════════════════════════════════════════════════
-- BanQuito V2 — Cloud SQL MySQL 8.4
-- Servicios: party-service, tariff-service, file-reception-service
--
-- Ejecutar con:
--   mysql -h 136.111.132.119 -u root -p < mysql-schema.sql
-- ══════════════════════════════════════════════════════════════════════════════

-- ── partydb (party-service — Santiago) ────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS partydb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE partydb;

CREATE TABLE IF NOT EXISTS customer_subtype (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    customer_type VARCHAR(15)  NOT NULL,
    name          VARCHAR(100) NOT NULL,
    description   VARCHAR(50),
    status        VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    observations  VARCHAR(255),
    creation_date DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version       INT          NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS customer (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    customer_subtype_id     INT          NOT NULL,
    customer_type           VARCHAR(15)  NOT NULL,
    identification_type     VARCHAR(15)  NOT NULL,
    identification          VARCHAR(20)  NOT NULL UNIQUE,
    first_name              VARCHAR(100),
    last_name               VARCHAR(100),
    legal_name              VARCHAR(100),
    birth_date              DATE,
    constitution_date       DATE,
    legal_representative_id INT,
    email                   VARCHAR(150),
    mobile_phone            VARCHAR(20),
    address                 VARCHAR(255),
    latitude                DECIMAL(10,7),
    longitude               DECIMAL(10,7),
    status                  VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    is_favorite             TINYINT(1)   NOT NULL DEFAULT 0,
    registration_date       DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version                 INT          NOT NULL DEFAULT 1,
    CONSTRAINT fk_cust_subtype FOREIGN KEY (customer_subtype_id) REFERENCES customer_subtype(id),
    CONSTRAINT fk_legal_rep    FOREIGN KEY (legal_representative_id) REFERENCES customer(id)
);

CREATE INDEX idx_customer_identification ON customer(identification);
CREATE INDEX idx_customer_type           ON customer(customer_type);
CREATE INDEX idx_customer_status         ON customer(status);

CREATE TABLE IF NOT EXISTS web_credential (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    customer_id   INT          NOT NULL,
    username      VARCHAR(50)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    last_login    DATETIME,
    status        VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    creation_date DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_wc_customer FOREIGN KEY (customer_id) REFERENCES customer(id)
);

CREATE INDEX idx_wc_customer ON web_credential(customer_id);

CREATE TABLE IF NOT EXISTS branch (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    branch_code   VARCHAR(10)  NOT NULL UNIQUE,
    name          VARCHAR(100) NOT NULL,
    city          VARCHAR(50)  NOT NULL,
    creation_date DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    version       INT          NOT NULL DEFAULT 1
);

CREATE TABLE IF NOT EXISTS holiday (
    holiday_date  DATE         PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    is_weekend    TINYINT(1)   NOT NULL DEFAULT 0,
    creation_date DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS core_parameter (
    code         VARCHAR(50)  PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    value_string VARCHAR(255) NOT NULL,
    data_type    VARCHAR(15)  NOT NULL,
    description  VARCHAR(255),
    last_update  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- ── tariffdb (tariff-service — Johan) ─────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS tariffdb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE tariffdb;

CREATE TABLE IF NOT EXISTS switch_service_type (
    id                  INT AUTO_INCREMENT PRIMARY KEY,
    name                VARCHAR(100)   NOT NULL,
    max_amount_per_tx   DECIMAL(15,2),
    status              VARCHAR(15)    NOT NULL DEFAULT 'ACTIVO',
    creation_date       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS switch_customer_service (
    id                      INT AUTO_INCREMENT PRIMARY KEY,
    customer_id             INT            NOT NULL,
    service_type_id         INT            NOT NULL,
    default_main_account    INT,
    status                  VARCHAR(15)    NOT NULL DEFAULT 'ACTIVO',
    max_annual_per_payment  DECIMAL(15,2),
    last_update             DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_scs_service FOREIGN KEY (service_type_id) REFERENCES switch_service_type(id)
);

CREATE INDEX idx_scs_customer ON switch_customer_service(customer_id);

CREATE TABLE IF NOT EXISTS customer_allowed_service (
    id              INT AUTO_INCREMENT PRIMARY KEY,
    service_type_id INT            NOT NULL,
    status          VARCHAR(15)    NOT NULL DEFAULT 'ACTIVO',
    assigned_date   DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cas_service FOREIGN KEY (service_type_id) REFERENCES switch_service_type(id)
);

CREATE TABLE IF NOT EXISTS service_accounting_entry (
    id                       INT AUTO_INCREMENT PRIMARY KEY,
    service_charge_id        BIGINT,
    institutional_account_id INT,
    accounting_account_code  VARCHAR(20),
    amount                   DECIMAL(10,2),
    movement_type            VARCHAR(10)    NOT NULL,
    registered_at            DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_movement CHECK (movement_type IN ('DEBITO','CREDITO'))
);

CREATE TABLE IF NOT EXISTS payment_tariff (
    id                 INT AUTO_INCREMENT PRIMARY KEY,
    min_successful_tx  INT            NOT NULL,
    max_successful_tx  INT            NOT NULL,
    unit_fee           DECIMAL(10,4)  NOT NULL,
    status             VARCHAR(15)    NOT NULL DEFAULT 'ACTIVO',
    valid_from         DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    valid_to           DATETIME,
    CONSTRAINT chk_range CHECK (min_successful_tx <= max_successful_tx)
);

CREATE TABLE IF NOT EXISTS service_charge (
    id                   BIGINT AUTO_INCREMENT PRIMARY KEY,
    payment_batch_id     VARCHAR(36)    NOT NULL,
    payment_tariff_id    INT            NOT NULL,
    successful_tx        INT            NOT NULL,
    unit_fee             DECIMAL(10,4)  NOT NULL,
    commission_subtotal  DECIMAL(15,2)  NOT NULL,
    iva_rate             DECIMAL(5,4)   NOT NULL DEFAULT 0.15,
    iva_amount           DECIMAL(15,2)  NOT NULL,
    total_charge         DECIMAL(15,2)  NOT NULL,
    status               VARCHAR(15)    NOT NULL DEFAULT 'CALCULADO',
    calculated_at        DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sc_tariff FOREIGN KEY (payment_tariff_id) REFERENCES payment_tariff(id)
);

CREATE INDEX idx_sc_batch ON service_charge(payment_batch_id);

-- ── filedb (file-reception-service — Alan) ────────────────────────────────────

CREATE DATABASE IF NOT EXISTS filedb CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE filedb;

CREATE TABLE IF NOT EXISTS payment_file_validation (
    payment_batch_id        VARCHAR(36)    PRIMARY KEY,
    header_total_records    INT,
    header_total_amount     DECIMAL(15,2),
    footer_total_records    INT,
    footer_total_amount     DECIMAL(15,2),
    security_hash           VARCHAR(64),
    structure_valid         TINYINT(1)     NOT NULL DEFAULT 0,
    amount_control_valid    TINYINT(1)     NOT NULL DEFAULT 0,
    customer_service_valid  TINYINT(1)     NOT NULL DEFAULT 0,
    duplicate_file_valid    TINYINT(1)     NOT NULL DEFAULT 0,
    validation_result       VARCHAR(15)    NOT NULL DEFAULT 'PENDIENTE',
    validated_at            DATETIME
);

CREATE TABLE IF NOT EXISTS switch_parameter (
    code         VARCHAR(50)  PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    value_string VARCHAR(255) NOT NULL,
    data_type    VARCHAR(15)  NOT NULL DEFAULT 'STRING',
    description  VARCHAR(255),
    last_update  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP
);
