-- ══════════════════════════════════════════════════════════════════════════
-- PASO 8 — Schema filedb PostgreSQL (Alan — file-reception-service)
-- ══════════════════════════════════════════════════════════════════════════
\c filedb

-- Resultado de validación de cada archivo recibido
CREATE TABLE payment_file_validation (
    payment_batch_id        VARCHAR(36)    PRIMARY KEY,
    header_total_records    INT,
    header_total_amount     NUMERIC(15,2),
    footer_total_records    INT,
    footer_total_amount     NUMERIC(15,2),
    security_hash           VARCHAR(64),
    structure_valid         BOOLEAN        NOT NULL DEFAULT FALSE,
    amount_control_valid    BOOLEAN        NOT NULL DEFAULT FALSE,
    customer_service_valid  BOOLEAN        NOT NULL DEFAULT FALSE,
    duplicate_file_valid    BOOLEAN        NOT NULL DEFAULT FALSE,
    validation_result       VARCHAR(15)    NOT NULL DEFAULT 'PENDIENTE',
    validated_at            TIMESTAMP
);

-- Catálogo de parámetros del Switch (routing codes, configuración)
CREATE TABLE switch_parameter (
    code         VARCHAR(50)  PRIMARY KEY,
    name         VARCHAR(100) NOT NULL,
    value_string VARCHAR(255) NOT NULL,
    data_type    VARCHAR(15)  NOT NULL DEFAULT 'STRING',
    description  VARCHAR(255),
    last_update  TIMESTAMP    NOT NULL DEFAULT NOW()
);
