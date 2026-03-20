-- Epic 28: Plans Tarifaires & Facturation (FR100–FR103)
-- Migration: add billing fields to tenants + plan_definitions + billing_events tables

-- Add billing fields to kernel.tenants
ALTER TABLE kernel.tenants
  ADD COLUMN IF NOT EXISTS plan                   TEXT          NOT NULL DEFAULT 'free',
  ADD COLUMN IF NOT EXISTS max_users              INTEGER       NOT NULL DEFAULT 1,
  ADD COLUMN IF NOT EXISTS installation_fee       DECIMAL(10,0),
  ADD COLUMN IF NOT EXISTS installation_paid      BOOLEAN       NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS training_fee           DECIMAL(10,0),
  ADD COLUMN IF NOT EXISTS training_paid          BOOLEAN       NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS billing_start_date     TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS billing_status         TEXT          NOT NULL DEFAULT 'trial',
  ADD COLUMN IF NOT EXISTS trial_ends_at          TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS overdue_at             TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS notes                  TEXT;

-- Create kernel.plan_definitions
CREATE TABLE IF NOT EXISTS kernel.plan_definitions (
  id                          UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  code                        TEXT          NOT NULL UNIQUE,
  name                        TEXT          NOT NULL,
  monthly_price               DECIMAL(10,0) NOT NULL,
  max_users                   INTEGER       NOT NULL,
  included_modules            TEXT[]        NOT NULL DEFAULT '{}',
  suggested_installation_fee  DECIMAL(10,0),
  suggested_training_fee      DECIMAL(10,0),
  is_active                   BOOLEAN       NOT NULL DEFAULT true,
  created_at                  TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

-- Create kernel.billing_events
CREATE TABLE IF NOT EXISTS kernel.billing_events (
  id              UUID          NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  tenant_id       UUID          NOT NULL REFERENCES kernel.tenants(id),
  type            TEXT          NOT NULL,
  amount          DECIMAL(10,0) NOT NULL,
  description     TEXT,
  paid_at         TIMESTAMPTZ,
  due_date        TIMESTAMPTZ,
  status          TEXT          NOT NULL DEFAULT 'pending',
  payment_method  TEXT,
  payment_ref     TEXT,
  created_at      TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS billing_events_tenant_status_idx ON kernel.billing_events (tenant_id, status);
