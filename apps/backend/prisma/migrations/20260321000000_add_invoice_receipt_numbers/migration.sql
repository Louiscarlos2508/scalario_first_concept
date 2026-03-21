-- Epic 28 / FIX 7: Add invoice_number and receipt_number to billing_events
ALTER TABLE kernel.billing_events
  ADD COLUMN IF NOT EXISTS invoice_number TEXT,
  ADD COLUMN IF NOT EXISTS receipt_number TEXT;
