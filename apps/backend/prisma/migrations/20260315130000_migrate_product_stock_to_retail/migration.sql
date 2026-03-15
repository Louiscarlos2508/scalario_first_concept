-- Data Migration: public.products → retail.retail_products
-- Story 6.1: Retail Schema & Product Extensions
--
-- For each CatalogItem that has a matching Product (by name + tenantId),
-- create a RetailProduct with stock_quantity and min_stock_level.
-- Products without a CatalogItem match are skipped (no catalog entry yet).

DO $$
DECLARE
  migrated_count INTEGER := 0;
  skipped_count  INTEGER := 0;
BEGIN
  -- Insert a RetailProduct for each CatalogItem that matches a public.products row
  -- Match by (name, tenantId) since Product.id != CatalogItem.id (different UUIDs)
  INSERT INTO retail.retail_products (catalog_item_id, stock_quantity, min_stock_level, created_at, updated_at)
  SELECT
    ci.id                         AS catalog_item_id,
    COALESCE(p.stock_quantity, 0) AS stock_quantity,
    NULL                          AS min_stock_level,  -- no min_stock_level in old Product model
    now()                         AS created_at,
    now()                         AS updated_at
  FROM shared.catalog_items ci
  JOIN public.products p
    ON p.name = ci.name
   AND p.tenant_id = ci.tenant_id
   AND p.is_deleted = false
  WHERE ci.is_deleted = false
    AND NOT EXISTS (
      SELECT 1 FROM retail.retail_products rp WHERE rp.catalog_item_id = ci.id
    );

  GET DIAGNOSTICS migrated_count = ROW_COUNT;

  -- Count CatalogItems without a matching product (no RetailProduct created)
  SELECT COUNT(*) INTO skipped_count
  FROM shared.catalog_items ci
  WHERE ci.is_deleted = false
    AND NOT EXISTS (
      SELECT 1 FROM retail.retail_products rp WHERE rp.catalog_item_id = ci.id
    );

  RAISE NOTICE 'Data migration complete: % RetailProduct records created, % CatalogItems have no matching Product (skipped)',
    migrated_count, skipped_count;
END;
$$;
