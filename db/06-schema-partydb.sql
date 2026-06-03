-- ══════════════════════════════════════════════════════════════════════════
-- PASO 6 — Schema partydb (Santiago — party-service)
-- ══════════════════════════════════════════════════════════════════════════
\c partydb

CREATE TABLE customer_subtype (
    id            SERIAL PRIMARY KEY,
    customer_type VARCHAR(15)  NOT NULL,
    name          VARCHAR(100) NOT NULL,
    description   VARCHAR(50),
    status        VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    observations  VARCHAR(255),
    creation_date TIMESTAMP    NOT NULL DEFAULT NOW(),
    version       INT          NOT NULL DEFAULT 1
);

CREATE TABLE customer (
    id                      SERIAL       PRIMARY KEY,
    customer_subtype_id     INT          NOT NULL REFERENCES customer_subtype(id),
    customer_type           VARCHAR(15)  NOT NULL CHECK (customer_type IN ('NATURAL','JURIDICO')),
    identification_type     VARCHAR(15)  NOT NULL CHECK (identification_type IN ('CEDULA','PASAPORTE','RUC')),
    identification          VARCHAR(20)  NOT NULL UNIQUE,
    first_name              VARCHAR(100),
    last_name               VARCHAR(100),
    legal_name              VARCHAR(100),
    birth_date              DATE,
    constitution_date       DATE,
    legal_representative_id INT          REFERENCES customer(id),  -- FK recursiva para corporativos
    email                   VARCHAR(150),
    mobile_phone            VARCHAR(20),
    address                 VARCHAR(255),
    latitude                DECIMAL(10,7),
    longitude               DECIMAL(10,7),
    status                  VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    is_favorite             BOOLEAN      NOT NULL DEFAULT FALSE,
    registration_date       TIMESTAMP    NOT NULL DEFAULT NOW(),
    version                 INT          NOT NULL DEFAULT 1
);

CREATE INDEX idx_customer_identification ON customer(identification);
CREATE INDEX idx_customer_type          ON customer(customer_type);
CREATE INDEX idx_customer_status        ON customer(status);

CREATE TABLE web_credential (
    id            SERIAL       PRIMARY KEY,
    customer_id   INT          NOT NULL REFERENCES customer(id),
    username      VARCHAR(50)  NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    last_login    TIMESTAMP,
    status        VARCHAR(15)  NOT NULL DEFAULT 'ACTIVO',
    creation_date TIMESTAMP    NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_wc_customer ON web_credential(customer_id);

CREATE TABLE branch (
    id            SERIAL       PRIMARY KEY,
    branch_code   VARCHAR(10)  NOT NULL UNIQUE,
    name          VARCHAR(100) NOT NULL,
    city          VARCHAR(50)  NOT NULL,
    creation_date TIMESTAMP    NOT NULL DEFAULT NOW(),
    version       INT          NOT NULL DEFAULT 1
);

-- Feriados (copia en partydb para que file-reception pueda consultar)
CREATE TABLE holiday (
    holiday_date  DATE         PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    is_weekend    BOOLEAN      NOT NULL DEFAULT FALSE,
    creation_date TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Parámetros (copia en partydb)
CREATE TABLE core_parameter (
    code         VARCHAR(50)  PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    value_string VARCHAR(255) NOT NULL,
    data_type    VARCHAR(15)  NOT NULL,
    description  VARCHAR(255),
    last_update  TIMESTAMP    NOT NULL DEFAULT NOW()
);
