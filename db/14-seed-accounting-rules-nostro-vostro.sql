-- =============================================================================
-- 14 - Reglas contables Nostro/Vostro para pagos interbancarios
-- =============================================================================
-- Crea las 4 reglas que account-core-service invoca y que hoy NO existen en
-- accounting_rule (la tabla llega hasta CORPORATE_REFUND_SAVINGS, id 17):
--
--   NOSTRO_SETTLEMENT_OUTBOUND            (saliente: BanQuito -> banco 003)
--   VOSTRO_SETTLEMENT_INBOUND             (entrante, pata 1: recepcion bruta)
--   VOSTRO_SETTLEMENT_DELIVERY_SAVINGS    (entrante, pata 2: entrega a ahorros)
--   VOSTRO_SETTLEMENT_DELIVERY_CHECKING   (entrante, pata 2: entrega a corriente)
--
-- Requiere 13-seed-correspondent-banks.sql aplicado antes (las cuentas
-- 1.1.1.01 y 2.3.0.01 deben existir).
--
-- Convencion tomada de las reglas ya existentes (ver rule_id 9, 12, 15):
--   - Cada regla lista sus lineas con line_order consecutivo desde 1.
--   - Cada componente (PRINCIPAL/COMMISSION/IVA_ON_COMMISSION) forma un par
--     DEBITO/CREDITO balanceado.
--   - skip_if_zero = true permite omitir la linea si el componente viene en 0.
--   - Estas 4 reglas solo mueven PRINCIPAL: la comision de un pago interbancario
--     se cobra en el flujo de lote (RF-04), no en la liquidacion.
--
-- Modelo de liquidacion: BILATERAL contra cuenta Nostro (no via camara de
-- compensacion). Requiere que 1.1.1.01 este fondeada -- ver 15-seed-nostro-funding.sql.
--
-- Cuentas involucradas:
--   1.1.0.01  ACTIVO   Banco Central / Camara de Compensacion
--   1.1.1.01  ACTIVO   Nostro Banco 003
--   2.1.0.01  PASIVO   Cuentas de Ahorros Clientes
--   2.1.0.02  PASIVO   Cuentas Corrientes Clientes
--   2.3.0.01  PASIVO   Vostro Banco 003
--   2.4.0.01  PASIVO   Transferencias Salientes por Liquidar (cuenta puente)
--
-- Idempotente: se puede re-ejecutar sin duplicar.
-- =============================================================================

-- =============================================================================
-- 1) NOSTRO_SETTLEMENT_OUTBOUND
-- -----------------------------------------------------------------------------
-- Liquidacion del pago que ya salio hacia el banco 003. El debito al cliente y
-- el credito a la cuenta puente ya ocurrieron en EXTERNAL_TRANSFER_*; esta regla
-- SOLO salda la cuenta puente contra la cuenta Nostro.
--
--   DEBITO  2.4.0.01  Transferencias por Liquidar  -> se cancela la obligacion
--   CREDITO 1.1.1.01  Nostro Banco 003             -> baja nuestro saldo alla
--
-- Modelo BILATERAL (decision del 2026-08-03): el pago se descuenta del saldo que
-- BanQuito mantiene depositado EN el banco 003, no se liquida via camara de
-- compensacion. Por eso se acredita 1.1.1.01 (Nostro, activo) y no 1.1.0.01.
--
-- REQUISITO OPERATIVO: la cuenta Nostro debe estar FONDEADA antes de enviar
-- pagos. Cada liquidacion la acredita (baja el activo); si el saldo llega a
-- cero, los siguientes pagos la dejan en NEGATIVO, lo que contablemente
-- significaria que el banco 003 nos debe a nosotros -- una inconsistencia que
-- ningun asiento posterior corrige solo. Ver 15-seed-nostro-funding.sql para el
-- fondeo inicial, y monitorear el saldo con:
--   SELECT current_balance FROM accounting.accounting_account
--    WHERE account_code = '1.1.1.01';
-- =============================================================================

INSERT INTO accounting.accounting_rule (description, effective_from, effective_to, operation_type)
SELECT 'Liquidacion Nostro saliente hacia banco corresponsal (bilateral)', DATE '2026-01-01', NULL, 'NOSTRO_SETTLEMENT_OUTBOUND'
WHERE NOT EXISTS (
    SELECT 1 FROM accounting.accounting_rule WHERE operation_type = 'NOSTRO_SETTLEMENT_OUTBOUND');

INSERT INTO accounting.accounting_rule_line (account_code, amount_component, line_order, movement_type, skip_if_zero, rule_id)
SELECT v.account_code, v.amount_component, v.line_order, v.movement_type, v.skip_if_zero, r.id
FROM accounting.accounting_rule r
CROSS JOIN (VALUES
    ('2.4.0.01', 'PRINCIPAL', 1, 'DEBITO',  true),
    ('1.1.1.01', 'PRINCIPAL', 2, 'CREDITO', true)
) AS v(account_code, amount_component, line_order, movement_type, skip_if_zero)
WHERE r.operation_type = 'NOSTRO_SETTLEMENT_OUTBOUND'
  AND NOT EXISTS (SELECT 1 FROM accounting.accounting_rule_line l WHERE l.rule_id = r.id);

-- Correccion para entornos donde esta regla ya se creo con la version anterior
-- del script, que acreditaba 1.1.0.01 (camara) en vez de 1.1.1.01 (Nostro). Los
-- INSERT de arriba llevan NOT EXISTS, asi que por si solos NO actualizan una
-- regla preexistente: sin este UPDATE, un entorno ya inicializado se quedaria
-- liquidando contra camara.
UPDATE accounting.accounting_rule_line l
   SET account_code = '1.1.1.01'
  FROM accounting.accounting_rule r
 WHERE r.id = l.rule_id
   AND r.operation_type = 'NOSTRO_SETTLEMENT_OUTBOUND'
   AND l.line_order = 2
   AND l.account_code = '1.1.0.01';


-- =============================================================================
-- 2) VOSTRO_SETTLEMENT_INBOUND
-- -----------------------------------------------------------------------------
-- Pata 1 del flujo entrante: recepcion BRUTA de fondos del banco 003, antes de
-- tocar la cuenta del cliente. account-core-service la ejecuta primero y es el
-- unico punto donde se valida el banco corresponsal.
--
--   DEBITO  1.1.0.01  Camara de Compensacion  -> entra el dinero al banco
--   CREDITO 2.3.0.01  Vostro Banco 003        -> nace la obligacion con ellos
--
-- Tras esta pata el dinero esta en el banco pero aun NO es del cliente: figura
-- como deuda hacia el banco corresponsal hasta que corra la pata DELIVERY.
-- =============================================================================

INSERT INTO accounting.accounting_rule (description, effective_from, effective_to, operation_type)
SELECT 'Recepcion bruta de fondos de banco corresponsal (Vostro)', DATE '2026-01-01', NULL, 'VOSTRO_SETTLEMENT_INBOUND'
WHERE NOT EXISTS (
    SELECT 1 FROM accounting.accounting_rule WHERE operation_type = 'VOSTRO_SETTLEMENT_INBOUND');

INSERT INTO accounting.accounting_rule_line (account_code, amount_component, line_order, movement_type, skip_if_zero, rule_id)
SELECT v.account_code, v.amount_component, v.line_order, v.movement_type, v.skip_if_zero, r.id
FROM accounting.accounting_rule r
CROSS JOIN (VALUES
    ('1.1.0.01', 'PRINCIPAL', 1, 'DEBITO',  true),
    ('2.3.0.01', 'PRINCIPAL', 2, 'CREDITO', true)
) AS v(account_code, amount_component, line_order, movement_type, skip_if_zero)
WHERE r.operation_type = 'VOSTRO_SETTLEMENT_INBOUND'
  AND NOT EXISTS (SELECT 1 FROM accounting.accounting_rule_line l WHERE l.rule_id = r.id);


-- =============================================================================
-- 3) VOSTRO_SETTLEMENT_DELIVERY_SAVINGS
-- -----------------------------------------------------------------------------
-- Pata 2 del flujo entrante cuando la cuenta destino es de AHORROS. Traslada la
-- obligacion desde el banco corresponsal hacia el cliente final.
--
--   DEBITO  2.3.0.01  Vostro Banco 003          -> se extingue la deuda con ellos
--   CREDITO 2.1.0.01  Cuentas de Ahorros        -> el cliente ya tiene el dinero
--
-- Neto de las dos patas: 1.1.0.01 debitada, 2.1.0.01 acreditada y Vostro en cero.
-- =============================================================================

INSERT INTO accounting.accounting_rule (description, effective_from, effective_to, operation_type)
SELECT 'Entrega al cliente de fondos recibidos (Vostro) -> cuenta de ahorros', DATE '2026-01-01', NULL, 'VOSTRO_SETTLEMENT_DELIVERY_SAVINGS'
WHERE NOT EXISTS (
    SELECT 1 FROM accounting.accounting_rule WHERE operation_type = 'VOSTRO_SETTLEMENT_DELIVERY_SAVINGS');

INSERT INTO accounting.accounting_rule_line (account_code, amount_component, line_order, movement_type, skip_if_zero, rule_id)
SELECT v.account_code, v.amount_component, v.line_order, v.movement_type, v.skip_if_zero, r.id
FROM accounting.accounting_rule r
CROSS JOIN (VALUES
    ('2.3.0.01', 'PRINCIPAL', 1, 'DEBITO',  true),
    ('2.1.0.01', 'PRINCIPAL', 2, 'CREDITO', true)
) AS v(account_code, amount_component, line_order, movement_type, skip_if_zero)
WHERE r.operation_type = 'VOSTRO_SETTLEMENT_DELIVERY_SAVINGS'
  AND NOT EXISTS (SELECT 1 FROM accounting.accounting_rule_line l WHERE l.rule_id = r.id);


-- =============================================================================
-- 4) VOSTRO_SETTLEMENT_DELIVERY_CHECKING
-- -----------------------------------------------------------------------------
-- Identica a la anterior pero contra cuentas CORRIENTES (2.1.0.02).
-- account-core-service elige entre SAVINGS y CHECKING segun el tipo de la cuenta
-- destino (getAccountingProductType).
-- =============================================================================

INSERT INTO accounting.accounting_rule (description, effective_from, effective_to, operation_type)
SELECT 'Entrega al cliente de fondos recibidos (Vostro) -> cuenta corriente', DATE '2026-01-01', NULL, 'VOSTRO_SETTLEMENT_DELIVERY_CHECKING'
WHERE NOT EXISTS (
    SELECT 1 FROM accounting.accounting_rule WHERE operation_type = 'VOSTRO_SETTLEMENT_DELIVERY_CHECKING');

INSERT INTO accounting.accounting_rule_line (account_code, amount_component, line_order, movement_type, skip_if_zero, rule_id)
SELECT v.account_code, v.amount_component, v.line_order, v.movement_type, v.skip_if_zero, r.id
FROM accounting.accounting_rule r
CROSS JOIN (VALUES
    ('2.3.0.01', 'PRINCIPAL', 1, 'DEBITO',  true),
    ('2.1.0.02', 'PRINCIPAL', 2, 'CREDITO', true)
) AS v(account_code, amount_component, line_order, movement_type, skip_if_zero)
WHERE r.operation_type = 'VOSTRO_SETTLEMENT_DELIVERY_CHECKING'
  AND NOT EXISTS (SELECT 1 FROM accounting.accounting_rule_line l WHERE l.rule_id = r.id);


-- =============================================================================
-- Verificacion: las 4 reglas con 2 lineas cada una, y cada par balanceado
-- =============================================================================
-- SELECT r.operation_type, l.line_order, l.movement_type, l.account_code
--   FROM accounting.accounting_rule r
--   JOIN accounting.accounting_rule_line l ON l.rule_id = r.id
--  WHERE r.operation_type LIKE '%STRO_SETTLEMENT%'
--  ORDER BY r.operation_type, l.line_order;
