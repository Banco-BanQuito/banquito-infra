-- =============================================================================
-- 15 - Fondeo inicial de la cuenta Nostro del banco 003
-- =============================================================================
-- Requerido por el modelo de liquidacion BILATERAL adoptado el 2026-08-03:
-- NOSTRO_SETTLEMENT_OUTBOUND acredita 1.1.1.01 en cada pago saliente, o sea que
-- CONSUME el saldo que BanQuito mantiene depositado en el banco 003.
--
-- Si esa cuenta arranca en cero, el primer pago saliente la deja en negativo. Un
-- activo negativo significa contablemente lo contrario de la realidad ("el banco
-- 003 nos debe"), y ningun asiento posterior lo corrige solo: hay que fondearla
-- ANTES de enviar pagos.
--
-- Este asiento representa la transferencia real de fondos que BanQuito hace a su
-- cuenta en el banco 003:
--
--   DEBITO  1.1.1.01  Nostro Banco 003        -> aumenta nuestro saldo alla
--   CREDITO 1.1.0.01  Camara de Compensacion  -> sale el dinero de aca
--
-- Ambas son cuentas de ACTIVO: no cambia el patrimonio, solo mueve fondos de un
-- activo a otro. El asiento cuadra (un debito = un credito).
--
-- MONTO: 200000.00. Al aplicarse (2026-08-03) la cuenta ya estaba en -14351.38
-- porque hubo pagos salientes ANTES de fondearla, asi que el monto tuvo que
-- cubrir ese negativo mas un colchon operativo. Para produccion real lo define
-- tesoreria segun el volumen esperado.
--
-- Idempotente: entry_uuid es UNIQUE. Un segundo intento falla con
-- "duplicate key value violates unique constraint" -- eso es correcto y
-- deliberado: evita fondear dos veces. NO cambiar el entry_uuid para forzarlo.
--
-- Saldos: verificado en la BD que accounting_account.current_balance SI se
-- mantiene por asiento (saldo_guardado = saldo_calculado en las cuentas de
-- activo), por lo que la seccion de UPDATE de abajo es necesaria y no duplica.
--
-- Nota sobre cuentas de PASIVO: al comparar saldos, la formula es
-- (CREDITO - DEBITO), inversa a la de activo. Una consulta que use la formula de
-- activo sobre 2.4.0.01 o 2.3.0.01 devuelve el signo invertido y aparenta un
-- descuadre que no existe.
-- =============================================================================

-- --- Asiento de fondeo -------------------------------------------------------
-- Todo en una transaccion: si algo falla no queda un asiento sin lineas ni
-- saldos movidos sin asiento que los respalde.

BEGIN;

INSERT INTO accounting.journal_entry
    (entry_uuid, description, entry_date, status)
VALUES
    ('NOSTRO-FUNDING-003-INITIAL',
     'Fondeo inicial cuenta Nostro Banco 003 (liquidacion bilateral)',
     NOW(), 'REGISTRADO');

INSERT INTO accounting.journal_entry_line
    (journal_entry_id, account_code, movement_type, amount, reference)
SELECT e.id, v.account_code, v.movement_type, v.amount, v.reference
FROM accounting.journal_entry e
CROSS JOIN (VALUES
    ('1.1.1.01', 'DEBITO',  200000.00, 'Fondeo inicial Nostro Banco 003'),
    ('1.1.0.01', 'CREDITO', 200000.00, 'Fondeo inicial Nostro Banco 003')
) AS v(account_code, movement_type, amount, reference)
WHERE e.entry_uuid = 'NOSTRO-FUNDING-003-INITIAL';

UPDATE accounting.accounting_account
   SET current_balance = current_balance + 200000.00
 WHERE account_code = '1.1.1.01';

UPDATE accounting.accounting_account
   SET current_balance = current_balance - 200000.00
 WHERE account_code = '1.1.0.01';

COMMIT;


-- --- Verificacion ------------------------------------------------------------
-- El asiento debe cuadrar y el Nostro quedar en 100000.00:
--
-- SELECT l.account_code, l.movement_type, l.amount
--   FROM accounting.journal_entry e
--   JOIN accounting.journal_entry_line l ON l.journal_entry_id = e.id
--  WHERE e.entry_uuid = 'NOSTRO-FUNDING-003-INITIAL';
--
-- SELECT account_code, name, current_balance
--   FROM accounting.accounting_account
--  WHERE account_code IN ('1.1.1.01','1.1.0.01');
