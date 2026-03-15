-- Migration: Create retail.retail_sales table
-- Story 6.2: RetailSale Extensions & Session Scoping
-- Depends on: 20260315120000_retail_schema_retail_products (retail schema already created)

CREATE TABLE retail.retail_sales (
  id             UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id UUID        NOT NULL UNIQUE REFERENCES shared.transactions(id) ON DELETE CASCADE,
  session_id     UUID        REFERENCES public.pos_sessions(id),
  receipt_number TEXT        NOT NULL,
  cashier_id     UUID        NOT NULL,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ON retail.retail_sales (session_id);
CREATE INDEX ON retail.retail_sales (cashier_id);
