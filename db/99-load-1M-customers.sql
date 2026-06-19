-- ══════════════════════════════════════════════════════════════════════════
-- CARGA DE DATOS — ~950,000 clientes adicionales para pruebas de carga
--
-- Formato de número de cuenta (igual que 03-seed-accountdb.sql):
--   product_code(2 dígitos) + customer_id(8 dígitos) = 10 caracteres
--   22=Ahorros Personal 23=Corriente Personal 30=Corriente Operativa
--   31=Ahorros Nómina   32=Ahorros Impuestos
--   branch_id se guarda en su propia columna (no en el número de cuenta)
--
-- Rango de customer_id nuevo (no pisa los 9,500 existentes):
--   Individuales : 9501   → 900000  (890,500 personas naturales)
--   Corporativos : 900001 → 950000  ( 49,999 empresas)
--
-- Tiempo estimado: 1-3 minutos
-- ══════════════════════════════════════════════════════════════════════════

\c accountdb
SET synchronous_commit = OFF;

-- ── Individuales 9501-900000 ─────────────────────────────────────────────
-- Cuenta de Ahorros Personal (subtype 1) — 1 cuenta por cliente
INSERT INTO account (account_number, customer_id, branch_id, account_subtype_id,
                     accounting_balance, available_balance, status, opening_date)
SELECT
    '22' || LPAD(n::text, 8, '0'),
    n,
    ((n - 1) % 5) + 1,
    1,
    ROUND((random() * 9900 + 100)::numeric, 2),
    ROUND((random() * 9900 + 100)::numeric, 2),
    'ACTIVA',
    CURRENT_DATE - (random() * 1825)::int
FROM generate_series(9501, 900000) AS n;

-- Cuenta Corriente Personal (subtype 2) — solo 20% de individuales
INSERT INTO account (account_number, customer_id, branch_id, account_subtype_id,
                     accounting_balance, available_balance, status, opening_date)
SELECT
    '23' || LPAD(n::text, 8, '0'),
    n,
    ((n - 1) % 5) + 1,
    2,
    ROUND((random() * 4900 + 500)::numeric, 2),
    ROUND((random() * 4900 + 500)::numeric, 2),
    'ACTIVA',
    CURRENT_DATE - (random() * 730)::int
FROM generate_series(9501, 900000) AS n
WHERE n % 5 = 0;

-- ── Corporativos 900001-950000 ────────────────────────────────────────────
-- Cada empresa obtiene sus 3 cuentas a partir de su propio customer_id —
-- no hace falta desplazar la secuencia porque el prefijo de producto (30/31/32)
-- ya distingue cada cuenta del mismo cliente.

-- Corriente Operativa (subtype 3)
INSERT INTO account (account_number, customer_id, branch_id, account_subtype_id,
                     accounting_balance, available_balance, status, opening_date)
SELECT
    '30' || LPAD(n::text, 8, '0'),
    n,
    ((n - 900001) % 5) + 1,
    3,
    ROUND((random() * 90000 + 10000)::numeric, 2),
    ROUND((random() * 90000 + 10000)::numeric, 2),
    'ACTIVA',
    CURRENT_DATE - (random() * 1825)::int
FROM generate_series(900001, 950000) AS n;

-- Ahorros Nómina (subtype 4)
INSERT INTO account (account_number, customer_id, branch_id, account_subtype_id,
                     accounting_balance, available_balance, status, opening_date)
SELECT
    '31' || LPAD(n::text, 8, '0'),
    n,
    ((n - 900001) % 5) + 1,
    4,
    ROUND((random() * 50000 + 5000)::numeric, 2),
    ROUND((random() * 50000 + 5000)::numeric, 2),
    'ACTIVA',
    CURRENT_DATE - (random() * 1825)::int
FROM generate_series(900001, 950000) AS n;

-- Ahorros Impuestos (subtype 5)
INSERT INTO account (account_number, customer_id, branch_id, account_subtype_id,
                     accounting_balance, available_balance, status, opening_date)
SELECT
    '32' || LPAD(n::text, 8, '0'),
    n,
    ((n - 900001) % 5) + 1,
    5,
    ROUND((random() * 20000 + 1000)::numeric, 2),
    ROUND((random() * 20000 + 1000)::numeric, 2),
    'ACTIVA',
    CURRENT_DATE - (random() * 1825)::int
FROM generate_series(900001, 950000) AS n;

SET synchronous_commit = ON;

-- Resumen accountdb
SELECT
    st.name              AS tipo_cuenta,
    b.branch_id          AS sucursal,
    COUNT(*)             AS total,
    ROUND(AVG(a.available_balance), 2) AS saldo_promedio
FROM account a
JOIN account_subtype st ON st.id = a.account_subtype_id
JOIN (SELECT DISTINCT branch_id FROM account) b ON b.branch_id = a.branch_id
WHERE a.customer_id > 9500
GROUP BY st.name, b.branch_id
ORDER BY st.name, b.branch_id
LIMIT 20;

SELECT COUNT(*) AS total_cuentas_nuevas FROM account WHERE customer_id > 9500;
SELECT COUNT(*) AS total_cuentas_bd FROM account;

-- ── tariffdb ──────────────────────────────────────────────────────────────
\c tariffdb
SET synchronous_commit = OFF;

-- Corporativos 900001-950000: NOMINA
INSERT INTO switch_customer_service (customer_id, service_type_id, default_main_account, status, max_annual_per_payment)
SELECT n, 1, NULL, 'ACTIVO', ROUND((random() * 900000 + 100000)::numeric, 2)
FROM generate_series(900001, 950000) AS n;

-- Corporativos 900001-950000: PROVEEDORES
INSERT INTO switch_customer_service (customer_id, service_type_id, default_main_account, status, max_annual_per_payment)
SELECT n, 2, NULL, 'ACTIVO', ROUND((random() * 500000 + 50000)::numeric, 2)
FROM generate_series(900001, 950000) AS n;

SET synchronous_commit = ON;

SELECT
    s.name AS servicio,
    COUNT(*) AS empresas_habilitadas
FROM switch_customer_service scs
JOIN switch_service_type s ON s.id = scs.service_type_id
GROUP BY s.name;
