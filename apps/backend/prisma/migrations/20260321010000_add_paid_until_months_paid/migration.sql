-- FIX 8: Add paid_until to tenants and months_paid to billing_events
ALTER TABLE kernel.tenants
  ADD COLUMN IF NOT EXISTS paid_until TIMESTAMPTZ;

ALTER TABLE kernel.billing_events
  ADD COLUMN IF NOT EXISTS months_paid INTEGER;
