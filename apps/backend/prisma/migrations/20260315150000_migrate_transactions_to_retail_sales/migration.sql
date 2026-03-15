-- Data Migration: shared.transactions → retail.retail_sales
-- Story 6.2: RetailSale Extensions & Session Scoping
--
-- Orders were migrated to Transactions in Story 4.2.
-- Transactions that had a sessionId (formerly Order.sessionId) are retail sales.
-- receiptNumber was not preserved in Transaction model — generate a synthetic one.
-- cashierId is not in Transaction model — use a placeholder UUID; real value
-- will be set going forward by the RetailSaleService.

DO $$
DECLARE
  migrated_count INTEGER := 0;
  placeholder_cashier UUID := gen_random_uuid();
BEGIN
  INSERT INTO retail.retail_sales (transaction_id, session_id, receipt_number, cashier_id, created_at)
  SELECT
    t.id                                              AS transaction_id,
    t.session_id                                      AS session_id,
    'LEGACY-' || UPPER(SUBSTRING(t.id::TEXT, 1, 8))  AS receipt_number,
    placeholder_cashier                               AS cashier_id,
    t.created_at                                      AS created_at
  FROM shared.transactions t
  WHERE t.session_id IS NOT NULL
    AND NOT EXISTS (
      SELECT 1 FROM retail.retail_sales rs WHERE rs.transaction_id = t.id
    );

  GET DIAGNOSTICS migrated_count = ROW_COUNT;

  RAISE NOTICE 'Data migration complete: % RetailSale records created from existing Transactions with sessionId',
    migrated_count;
END;
$$;
