-- ══════════════════════════════════════════════════════════════════════════
-- PASO 7 — Seed data partydb (Santiago)
-- 9000 clientes individuales + 500 corporativos = 9500 clientes
-- ══════════════════════════════════════════════════════════════════════════
\c partydb

-- ── Customer subtypes ─────────────────────────────────────────────────────
INSERT INTO customer_subtype (id, customer_type, name, description) VALUES
(1, 'NATURAL',  'Persona Natural',  'Cliente individual cuentahabiente'),
(2, 'JURIDICO', 'Persona Jurídica', 'Empresa emisora o corporativo');
SELECT setval('customer_subtype_id_seq', 2);

-- ── 5 Sucursales ──────────────────────────────────────────────────────────
INSERT INTO branch (id, branch_code, name, city) VALUES
(1, 'NORTE',   'Quito Norte',         'Quito'),
(2, 'SUR',     'Quito Sur',           'Quito'),
(3, 'CENTRO',  'Centro Histórico',    'Quito'),
(4, 'VALLES',  'Los Chillos',         'Sangolquí'),
(5, 'DIGITAL', 'Sucursal Virtual',    'Nacional');
SELECT setval('branch_id_seq', 5);

-- ── Feriados (misma data que accountdb) ───────────────────────────────────
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
('2026-12-25', 'Navidad',                       FALSE);

-- ── Core parameter (horario de corte Switch) ──────────────────────────────
INSERT INTO core_parameter (code, name, value_string, data_type, description) VALUES
('SWITCH_CUT_OFF', 'Horario de Corte Switch', '18:00', 'TIME', 'Cut-off del Switch para compensación');

-- ══════════════════════════════════════════════════════════════════════════
-- 9000 clientes individuales (IDs 1-9000)
-- ══════════════════════════════════════════════════════════════════════════
INSERT INTO customer (
    id, customer_subtype_id, customer_type, identification_type, identification,
    first_name, last_name, email, mobile_phone, address, status, birth_date, registration_date
)
SELECT
    n,
    1,
    'NATURAL',
    'CEDULA',
    LPAD(n::text, 10, '0'),
    (ARRAY['María','Juan','Carlos','Ana','Luis','Rosa','Pedro','Carmen','Jorge','Elena',
           'Diego','Sofía','Andrés','Valeria','Pablo','Gabriela','Sebastián','Daniela','Felipe','Isabella']
    )[ ((n-1) % 20) + 1 ],
    (ARRAY['García','López','Martínez','González','Rodríguez','Pérez','Sánchez','Torres','Flores','Morales',
           'Vega','Ortiz','Castro','Romero','Herrera','Medina','Suárez','Ramos','Díaz','Reyes']
    )[ ((n-1) % 20) + 1 ],
    'cliente' || n || '@banquito.ec',
    '09' || LPAD(((n * 7 + 1000000) % 100000000)::text, 8, '0'),
    'Calle ' || n || ', Quito',
    'ACTIVO',
    ('1970-01-01'::date + (random() * 18000)::int),
    NOW() - (random() * 730)::int * INTERVAL '1 day'
FROM generate_series(1, 9000) AS n;

-- ══════════════════════════════════════════════════════════════════════════
-- 500 clientes corporativos (IDs 9001-9500)
-- ══════════════════════════════════════════════════════════════════════════
INSERT INTO customer (
    id, customer_subtype_id, customer_type, identification_type, identification,
    legal_name, email, mobile_phone, address, status, constitution_date, registration_date
)
SELECT
    n,
    2,
    'JURIDICO',
    'RUC',
    LPAD(n::text, 10, '0') || '001',
    (ARRAY['Industrias','Corporación','Grupo','Empresa','Compañía','Distribuidora','Importadora','Exportadora']
    )[ ((n-9001) % 8) + 1 ]
    || ' '
    || (ARRAY['BanQuito','Andina','Pacífico','Ecuador','Nacional','Quiteña','Guayaquileña','Sierra']
    )[ ((n-9001) % 8) + 1 ]
    || ' S.A.',
    'empresa' || (n - 9000) || '@corporativo.ec',
    '02' || LPAD(((n * 3 + 2000000) % 10000000)::text, 7, '0'),
    'Av. Principal ' || (n - 9000) || ', Quito',
    'ACTIVO',
    ('2000-01-01'::date + (random() * 8000)::int),
    NOW() - (random() * 1095)::int * INTERVAL '1 day'
FROM generate_series(9001, 9500) AS n;

SELECT setval('customer_id_seq', 9500);

-- ── Web credentials para individuales (login Banca Web Personas) ──────────
-- Username: cliente{id} | Password: banquito2026 (hash bcrypt)
INSERT INTO web_credential (customer_id, username, password_hash, status)
SELECT
    n,
    'cliente' || n,
    '$2a$10$xRXEwH3kDMNhIV3k5XKXB.3oUUQZkzK7pqQ0KSmvn7mF8dXhqHGVe',
    'ACTIVO'
FROM generate_series(1, 9000) AS n;

-- ── Web credentials para corporativos (login Banca Web Empresas) ──────────
-- Username: empresa{n-9000} | Password: banquito2026
INSERT INTO web_credential (customer_id, username, password_hash, status)
SELECT
    n,
    'empresa' || (n - 9000),
    '$2a$10$xRXEwH3kDMNhIV3k5XKXB.3oUUQZkzK7pqQ0KSmvn7mF8dXhqHGVe',
    'ACTIVO'
FROM generate_series(9001, 9500) AS n;
