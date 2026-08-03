-- =============================================================================
-- 13 - Cuentas contables y catalogo de bancos corresponsales (Nostro/Vostro)
-- =============================================================================
-- Contexto:
--   El 2026-08-02 se crearon las cabeceras ESTRUCTURAL "Cuentas Nostro"
--   (1.1.1.00) y "Cuentas Vostro" (2.3.0.00), pero nunca se crearon las cuentas
--   hoja DETALLE que cuelgan de ellas ni se poblo correspondent_bank. Sin eso
--   ningun pago interbancario puede contabilizarse: accounting-service resuelve
--   el asiento contra cuentas DETALLE y no encuentra ninguna.
--
-- Modelo de cuentas (una pareja por banco corresponsal):
--   1.1.1.0X  ACTIVO  DETALLE  Nostro <banco>  = nuestro dinero depositado alla
--   2.3.0.0X  PASIVO  DETALLE  Vostro <banco>  = su dinero depositado aca
--
-- IMPORTANTE - codigos de cuenta fijos, no dinamicos:
--   correspondent_bank tiene columnas nostro_account_code / vostro_account_code
--   que sugieren resolucion dinamica por banco, PERO AccountingRulesService
--   (linea 103) usa line.getAccountCode() literal: no existe ningun resolver que
--   lea esas columnas. Por eso las reglas del script 14 llevan el codigo de
--   cuenta fijo del banco 003. Al dar de alta otro banco corresponsal hay que
--   crear su pareja de cuentas Y un juego de reglas propio, hasta que se
--   implemente el resolver dinamico en accounting-service.
--
-- Idempotente: se puede re-ejecutar sin duplicar.
-- =============================================================================

-- --- Cuentas hoja para el banco 003 -----------------------------------------
-- account_class/account_type siguen la convencion de las cuentas ya existentes
-- (ver 1.1.0.01 / 2.1.0.01). current_balance arranca en 0.

INSERT INTO accounting.accounting_account
    (account_code, account_class, account_type, creation_date, current_balance, name, parent_account_code)
VALUES
    ('1.1.1.01', 'ACTIVO', 'DETALLE', NOW(), 0.00,
     'Nostro Banco 003', '1.1.1.00'),
    ('2.3.0.01', 'PASIVO', 'DETALLE', NOW(), 0.00,
     'Vostro Banco 003', '2.3.0.00')
ON CONFLICT (account_code) DO NOTHING;


-- --- Catalogo de bancos corresponsales --------------------------------------
-- bank_code 003 es el codigo numerico acordado con la contraparte el 2026-08-03
-- (001 = BanQuito, 003 = banco externo). Debe coincidir EXACTAMENTE con el
-- sourceRoutingCode que ellos envian en el pago entrante: account-core-service
-- lo pasa tal cual como originBankCode.

INSERT INTO accounting.correspondent_bank
    (bank_code, bank_name, nostro_account_code, vostro_account_code, currency, status, creation_date)
VALUES
    ('003', 'Banco Corresponsal 003', '1.1.1.01', '2.3.0.01', 'USD', 'ACTIVO', NOW())
ON CONFLICT (bank_code) DO NOTHING;


-- --- Verificacion ------------------------------------------------------------
-- SELECT * FROM accounting.correspondent_bank;
-- SELECT account_code, name, account_type, parent_account_code
--   FROM accounting.accounting_account
--  WHERE account_code IN ('1.1.1.01','2.3.0.01');
