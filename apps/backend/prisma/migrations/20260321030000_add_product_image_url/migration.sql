-- Add image_url to catalog_items for product photo support
ALTER TABLE shared.catalog_items
  ADD COLUMN IF NOT EXISTS image_url TEXT;
