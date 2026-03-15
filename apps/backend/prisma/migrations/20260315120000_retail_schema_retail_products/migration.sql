-- Migration: Create retail schema and retail_products table
-- Story 6.1: Retail Schema & Product Extensions

CREATE SCHEMA IF NOT EXISTS retail;

CREATE TABLE retail.retail_products (
  id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  catalog_item_id UUID        NOT NULL UNIQUE REFERENCES shared.catalog_items(id) ON DELETE CASCADE,
  stock_quantity  DECIMAL(10,2) NOT NULL DEFAULT 0,
  weight_unit     TEXT,
  min_stock_level DECIMAL(10,2),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX ON retail.retail_products (catalog_item_id);
