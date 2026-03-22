ALTER TABLE kernel.tenants
  ADD COLUMN IF NOT EXISTS payment_methods JSONB DEFAULT '["CASH","MOBILE_MONEY"]'::jsonb;
