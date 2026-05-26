-- daily_kpis: CA, marge, transactions, pertes par jour
-- @params { tenant_id: UUID, date: DATE }
-- @access [OWNER, MANAGER]

SELECT
  COALESCE(SUM(s.amount), 0) as ca_total,
  COUNT(s.id) as nb_transactions,
  COALESCE(SUM(s.amount - (s.quantity * p.cost_price)), 0) as marge_brute,
  COUNT(DISTINCT s.cashier_id) as vendeurs_actifs
FROM sales s
JOIN products p ON s.product_id = p.id
WHERE s.tenant_id = :tenant_id
  AND DATE(s.timestamp) = :date
  AND s.deleted_at IS NULL;
