-- ══════════════════════════════════════════════════════════════════════════
-- PASO 12 — Seed web_credential para clientes demo (partydb)
-- Contraseña inicial = cédula/RUC del cliente (bcrypt vía pgcrypto)
-- El cliente DEBE cambiarla en su primer ingreso (last_login IS NULL)
-- ══════════════════════════════════════════════════════════════════════════
\c partydb

CREATE EXTENSION IF NOT EXISTS pgcrypto;

INSERT INTO web_credential (customer_id, username, password_hash, status, creation_date)
SELECT
    c.id,
    c.identification,
    crypt(c.identification, gen_salt('bf', 10)),
    'ACTIVO',
    NOW()
FROM customer c
WHERE NOT EXISTS (
    SELECT 1 FROM web_credential wc WHERE wc.customer_id = c.id
);
