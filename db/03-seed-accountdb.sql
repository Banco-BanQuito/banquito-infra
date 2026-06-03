-- ══════════════════════════════════════════════════════════════════════════
-- PASO 3 — Seed data accountdb (Oscar)
-- ══════════════════════════════════════════════════════════════════════════
\c accountdb

-- ── Subtipos de cuenta ────────────────────────────────────────────────────
INSERT INTO account_subtype (id, super_type, name, description, status) VALUES
(1, 'AHORROS',   'Ahorros Personal',         'Cuenta de ahorros persona natural',    'ACTIVO'),
(2, 'CORRIENTE', 'Corriente Personal',        'Cuenta corriente persona natural',     'ACTIVO'),
(3, 'CORRIENTE', 'Corriente Operativa',       'Cuenta operativa empresarial',         'ACTIVO'),
(4, 'AHORROS',   'Ahorros Nómina',            'Cuenta de dispersión de nómina',       'ACTIVO'),
(5, 'AHORROS',   'Ahorros Impuestos',         'Cuenta de retención de impuestos',     'ACTIVO');
SELECT setval('account_subtype_id_seq', 5);

-- ── Subtipos de transacción ───────────────────────────────────────────────
INSERT INTO transaction_subtype (id, code, name) VALUES
(1,  'DEP_VEN',   'Depósito Ventanilla'),
(2,  'RET_VEN',   'Retiro Ventanilla'),
(3,  'TRF_P2P_S', 'Transferencia P2P Salida'),
(4,  'TRF_P2P_E', 'Transferencia P2P Entrada'),
(5,  'PAG_NOM_C', 'Pago Nómina Crédito On-Us'),
(6,  'DEB_EMP',   'Débito Corporativo Nómina'),
(7,  'COM_SWT',   'Comisión Switch Pagos Masivos'),
(8,  'CLR_OFUS',  'Liquidación Off-Us Banco Central');
SELECT setval('transaction_subtype_id_seq', 8);

-- ── Cuentas institucionales del banco ────────────────────────────────────
INSERT INTO institutional_account (id, account_number, name, accounting_balance) VALUES
(1, '9900000001', 'Bóveda Central / Efectivo en Caja',       1000000.00),
(2, '9900000002', 'Banco Central / Cámara de Compensación',   500000.00),
(3, '9900000003', 'IVA Retenido por Servicios',                    0.00),
(4, '9900000004', 'Ingresos por Servicios Masivos',                0.00);
SELECT setval('institutional_account_id_seq', 4);

-- ── Feriados Ecuador 2026 ─────────────────────────────────────────────────
INSERT INTO holiday (holiday_date, name, is_weekend) VALUES
('2026-01-01', 'Año Nuevo',                     FALSE),
('2026-02-16', 'Carnaval',                      FALSE),
('2026-02-17', 'Carnaval',                      FALSE),
('2026-04-02', 'Jueves Santo',                  FALSE),
('2026-04-03', 'Viernes Santo',                 FALSE),
('2026-05-01', 'Día del Trabajo',               FALSE),
('2026-05-24', 'Batalla de Pichincha',          FALSE),
('2026-07-24', 'Muerte de Simón Bolívar',       FALSE),
('2026-08-10', 'Primer Grito de Independencia', FALSE),
('2026-10-09', 'Independencia de Guayaquil',    FALSE),
('2026-11-02', 'Día de Difuntos',               FALSE),
('2026-11-03', 'Independencia de Cuenca',       FALSE),
('2026-12-25', 'Navidad',                       FALSE),
-- Fines de semana de referencia (algunos feriados puente)
('2026-01-03', 'Sábado',  TRUE),
('2026-01-04', 'Domingo', TRUE);

-- ── Parámetros del Core ───────────────────────────────────────────────────
INSERT INTO core_parameter (code, name, value_string, data_type, description) VALUES
('FECHA_CONTABLE_ACTIVA', 'Fecha Contable Activa',     '2026-05-30', 'DATE',    'Fecha contable actual del banco. El EOD la avanza.'),
('CUT_OFF_TIME',          'Horario de Corte',           '20:00',      'TIME',    'Transacciones después de esta hora → ACCOUNTING_DATE = T+1'),
('IVA_RATE',              'Tasa IVA Servicios',         '0.15',       'DECIMAL', 'IVA aplicado a comisiones del Switch (15%)'),
('BANCO_CODE',            'Código Banco BanQuito',      '001',        'STRING',  'Código de institución para routing On-Us'),
('EOD_STATUS',            'Estado del proceso EOD',     'PENDIENTE',  'STRING',  'PENDIENTE | EN_PROCESO | COMPLETADO | ERROR');

-- ── Usuarios del sistema de Ventanilla ────────────────────────────────────
-- Contraseña para todos: "banquito2026" (hash bcrypt)
INSERT INTO core_user (id, username, password_hash, full_name, role, status) VALUES
(1, 'admin',      '$2a$10$xRXEwH3kDMNhIV3k5XKXB.3oUUQZkzK7pqQ0KSmvn7mF8dXhqHGVe', 'Administrador Sistema', 'ADMIN',  'ACTIVO'),
(2, 'cajero.norte',   '$2a$10$xRXEwH3kDMNhIV3k5XKXB.3oUUQZkzK7pqQ0KSmvn7mF8dXhqHGVe', 'Carlos Ruiz',      'CAJERO', 'ACTIVO'),
(3, 'cajero.sur',     '$2a$10$xRXEwH3kDMNhIV3k5XKXB.3oUUQZkzK7pqQ0KSmvn7mF8dXhqHGVe', 'Ana Mora',         'CAJERO', 'ACTIVO'),
(4, 'cajero.centro',  '$2a$10$xRXEwH3kDMNhIV3k5XKXB.3oUUQZkzK7pqQ0KSmvn7mF8dXhqHGVe', 'Luis Torres',      'CAJERO', 'ACTIVO'),
(5, 'cajero.valles',  '$2a$10$xRXEwH3kDMNhIV3k5XKXB.3oUUQZkzK7pqQ0KSmvn7mF8dXhqHGVe', 'Rosa Vega',        'CAJERO', 'ACTIVO'),
(6, 'cajero.digital', '$2a$10$xRXEwH3kDMNhIV3k5XKXB.3oUUQZkzK7pqQ0KSmvn7mF8dXhqHGVe', 'Pedro Salinas',    'CAJERO', 'ACTIVO');
SELECT setval('core_user_id_seq', 6);

-- ── Cuentas de clientes (referencia a customer IDs de partydb) ───────────
-- Individuales 1-7200: 1 cuenta ahorros
INSERT INTO account (account_number, customer_id, branch_id, account_subtype_id, accounting_balance, available_balance, status, opening_date)
SELECT
    '22' || LPAD(n::text, 8, '0'),
    n,
    ((n - 1) % 5) + 1,          -- branch_id 1-5 distribuido
    1,                            -- AHORROS personal
    ROUND((random() * 9000 + 100)::numeric, 2),
    ROUND((random() * 9000 + 100)::numeric, 2),
    'ACTIVA',
    CURRENT_DATE - (random() * 730)::int
FROM generate_series(1, 7200) AS n;

-- Individuales 7201-9000: cuenta ahorros (primera cuenta)
INSERT INTO account (account_number, customer_id, branch_id, account_subtype_id, accounting_balance, available_balance, status, opening_date)
SELECT
    '22' || LPAD(n::text, 8, '0'),
    n,
    ((n - 1) % 5) + 1,
    1,
    ROUND((random() * 9000 + 100)::numeric, 2),
    ROUND((random() * 9000 + 100)::numeric, 2),
    'ACTIVA',
    CURRENT_DATE - (random() * 730)::int
FROM generate_series(7201, 9000) AS n;

-- Individuales 7201-9000: cuenta corriente (segunda cuenta, el 20%)
INSERT INTO account (account_number, customer_id, branch_id, account_subtype_id, accounting_balance, available_balance, status, opening_date)
SELECT
    '23' || LPAD(n::text, 8, '0'),
    n,
    ((n - 1) % 5) + 1,
    2,                            -- CORRIENTE personal
    ROUND((random() * 5000 + 500)::numeric, 2),
    ROUND((random() * 5000 + 500)::numeric, 2),
    'ACTIVA',
    CURRENT_DATE - (random() * 365)::int
FROM generate_series(7201, 9000) AS n;

-- Corporativos 9001-9500: cuenta operativa
INSERT INTO account (account_number, customer_id, branch_id, account_subtype_id, accounting_balance, available_balance, status, opening_date)
SELECT
    '30' || LPAD(n::text, 8, '0'),
    n,
    ((n - 9001) % 5) + 1,
    3,                            -- CORRIENTE operativa
    ROUND((random() * 90000 + 10000)::numeric, 2),
    ROUND((random() * 90000 + 10000)::numeric, 2),
    'ACTIVA',
    CURRENT_DATE - (random() * 730)::int
FROM generate_series(9001, 9500) AS n;

-- Corporativos 9001-9500: cuenta nómina
INSERT INTO account (account_number, customer_id, branch_id, account_subtype_id, accounting_balance, available_balance, status, opening_date)
SELECT
    '31' || LPAD(n::text, 8, '0'),
    n,
    ((n - 9001) % 5) + 1,
    4,                            -- AHORROS nómina
    ROUND((random() * 50000 + 5000)::numeric, 2),
    ROUND((random() * 50000 + 5000)::numeric, 2),
    'ACTIVA',
    CURRENT_DATE - (random() * 730)::int
FROM generate_series(9001, 9500) AS n;

-- Corporativos 9001-9500: cuenta impuestos
INSERT INTO account (account_number, customer_id, branch_id, account_subtype_id, accounting_balance, available_balance, status, opening_date)
SELECT
    '32' || LPAD(n::text, 8, '0'),
    n,
    ((n - 9001) % 5) + 1,
    5,                            -- AHORROS impuestos
    ROUND((random() * 20000 + 1000)::numeric, 2),
    ROUND((random() * 20000 + 1000)::numeric, 2),
    'ACTIVA',
    CURRENT_DATE - (random() * 730)::int
FROM generate_series(9001, 9500) AS n;

-- Total cuentas creadas: 7200 + 1800 + 1800 + 500 + 500 + 500 = 12300
