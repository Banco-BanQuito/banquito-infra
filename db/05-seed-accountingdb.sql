-- ══════════════════════════════════════════════════════════════════════════
-- PASO 5 — Plan de Cuentas inicial (Bryan)
-- Exactamente según el documento Core V2, sección 2.2
-- ══════════════════════════════════════════════════════════════════════════
\c accountingdb

INSERT INTO accounting_account (account_code, name, account_class, account_type, parent_account_code, current_balance) VALUES

-- ── ACTIVOS ───────────────────────────────────────────────────────────────
('1.0.0.00', 'ACTIVOS',                                'ACTIVO', 'ESTRUCTURAL', NULL,        0.00),
('1.1.0.00', 'Disponibilidades',                       'ACTIVO', 'ESTRUCTURAL', '1.0.0.00',  0.00),
('1.1.0.01', 'Banco Central / Cámara de Compensación', 'ACTIVO', 'DETALLE',     '1.1.0.00',  500000.00),
('1.1.0.02', 'Bóveda Central / Efectivo en Caja',      'ACTIVO', 'DETALLE',     '1.1.0.00',  1000000.00),

-- ── PASIVOS ───────────────────────────────────────────────────────────────
('2.0.0.00', 'PASIVOS',                                'PASIVO', 'ESTRUCTURAL', NULL,        0.00),
('2.1.0.00', 'Obligaciones con el Público',            'PASIVO', 'ESTRUCTURAL', '2.0.0.00',  0.00),
('2.1.0.01', 'Cuentas de Ahorros Clientes',            'PASIVO', 'DETALLE',     '2.1.0.00',  0.00),
('2.1.0.02', 'Cuentas Corrientes Clientes',            'PASIVO', 'DETALLE',     '2.1.0.00',  0.00),
('2.2.0.00', 'Retenciones e Impuestos',                'PASIVO', 'ESTRUCTURAL', '2.0.0.00',  0.00),
('2.2.0.01', 'IVA Retenido por Servicios',             'PASIVO', 'DETALLE',     '2.2.0.00',  0.00),

-- ── INGRESOS ──────────────────────────────────────────────────────────────
('4.0.0.00', 'INGRESOS',                               'INGRESO', 'ESTRUCTURAL', NULL,       0.00),
('4.1.0.00', 'Ingresos por Servicios',                 'INGRESO', 'ESTRUCTURAL', '4.0.0.00', 0.00),
('4.1.0.01', 'Comisiones por Pagos Masivos',           'INGRESO', 'DETALLE',     '4.1.0.00', 0.00);
