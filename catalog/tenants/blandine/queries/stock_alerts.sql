-- stock_alerts: produits sous le seuil minimum
-- @params { tenant_id: UUID }
-- @access [OWNER, MANAGER]

SELECT
  p.name,
  p.stock_quantity,
  p.min_threshold,
  p.category,
  (p.stock_quantity - p.min_threshold) as deficit
FROM products p
WHERE p.tenant_id = :tenant_id
  AND p.stock_quantity < p.min_threshold
  AND p.deleted_at IS NULL
ORDER BY deficit ASC;
