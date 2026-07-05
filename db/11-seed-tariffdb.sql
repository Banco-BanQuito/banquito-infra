-- ══════════════════════════════════════════════════════════════════════════
-- PASO 11 — Seed data tariffdb (Johan)
-- ══════════════════════════════════════════════════════════════════════════
\c tariffdb

-- ── Tipos de servicio ─────────────────────────────────────────────────────
INSERT INTO switch_service_type (id, name, max_amount_per_tx, status) VALUES
(1, 'NOMINA',       50000.00, 'ACTIVO'),
(2, 'PROVEEDORES',  99999.99, 'ACTIVO'),
(3, 'INTERBANCARIO',99999.99, 'ACTIVO');
SELECT setval('switch_service_type_id_seq', 3);

-- ── Tarifas escalonadas (comisión por transacción exitosa) ─────────────────
-- Johan: GET /api/v2/tariff/calculate?successful_tx=N
-- Busca el rango donde min_successful_tx <= N <= max_successful_tx
INSERT INTO payment_tariff (id, min_successful_tx, max_successful_tx, unit_fee, status, valid_from) VALUES
(1,    1,   100,  0.35, 'ACTIVO', '2026-01-01'),
(2,  101,   500,  0.70, 'ACTIVO', '2026-01-01'),
(3,  501,  1000,  0.60, 'ACTIVO', '2026-01-01'),
(4, 1001, 99999,  0.50, 'ACTIVO', '2026-01-01');
SELECT setval('payment_tariff_id_seq', 4);

-- ── Empresas habilitadas (los 500 corporativos de partydb, IDs 9001-9500) ──
INSERT INTO switch_customer_service (customer_id, service_type_id, default_main_account, status, max_annual_per_payment)
SELECT
    n,
    1,                                                     -- servicio NOMINA
    NULL,                                                  -- la app llena el account_id
    'ACTIVO',
    ROUND((random() * 900000 + 100000)::numeric, 2)
FROM generate_series(9001, 9500) AS n;
