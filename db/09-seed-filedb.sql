-- ══════════════════════════════════════════════════════════════════════════
-- PASO 9 — Seed data filedb (Alan)
-- Catálogo de routing codes para enrutamiento On-Us / Off-Us
-- ══════════════════════════════════════════════════════════════════════════
\c filedb

-- Routing codes del sistema financiero ecuatoriano
-- Código '001' = BanQuito → On-Us (se liquida en el Core interno)
-- Otros códigos válidos   → Off-Us (va a la Cámara de Compensación)
INSERT INTO switch_parameter (code, name, value_string, data_type, description) VALUES
('ROUTING_001', 'Banco BanQuito',           '001', 'ROUTING_CODE', 'BanQuito → On-Us, liquidación inmediata en Core'),
('ROUTING_002', 'Banco Pichincha',           '002', 'ROUTING_CODE', 'Off-Us → Cámara de Compensación'),
('ROUTING_010', 'Banco de Guayaquil',        '010', 'ROUTING_CODE', 'Off-Us → Cámara de Compensación'),
('ROUTING_017', 'Produbanco',                '017', 'ROUTING_CODE', 'Off-Us → Cámara de Compensación'),
('ROUTING_030', 'Banco Internacional',       '030', 'ROUTING_CODE', 'Off-Us → Cámara de Compensación'),
('ROUTING_034', 'Banco del Austro',          '034', 'ROUTING_CODE', 'Off-Us → Cámara de Compensación'),
('ROUTING_035', 'Banco Bolivariano',         '035', 'ROUTING_CODE', 'Off-Us → Cámara de Compensación'),
('ROUTING_037', 'Banco del Pacífico',        '037', 'ROUTING_CODE', 'Off-Us → Cámara de Compensación'),
('ROUTING_042', 'Banco General Rumiñahui',   '042', 'ROUTING_CODE', 'Off-Us → Cámara de Compensación'),
-- Parámetros operacionales
('SWITCH_CUT_OFF',        'Horario de Corte Switch',      '18:00',   'TIME',    'Archivos después de esta hora → siguiente día hábil'),
('ONBUS_BANK_CODE',       'Código Banco On-Us',            '001',     'STRING',  'Código que identifica transacción como interna'),
('MAX_FILE_SIZE_MB',      'Tamaño máximo archivo CSV',     '50',      'INTEGER', 'Tamaño máximo en MB'),
('MAX_RECORDS_PER_BATCH', 'Máximo registros por lote',     '10000',   'INTEGER', 'Máximo de líneas por archivo'),
('DUPLICATE_CHECK_DAYS',  'Días para detectar duplicados', '30',      'INTEGER', 'Ventana de días para verificar hash duplicado');
