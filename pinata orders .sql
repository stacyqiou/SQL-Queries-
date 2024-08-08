WITH orders AS (
  SELECT
    customer_id,
    vertical,
    shop_cuisine,
    order_from_pinata,
    COUNT(order_id) AS orders
  FROM nodal-talon-430216-q6.efood.df
  GROUP BY customer_id, vertical, shop_cuisine, order_from_pinata
)

SELECT
  r.Segment,
  COUNT(DISTINCT o.customer_id) AS users,
  SUM(CASE WHEN o.order_from_pinata = TRUE THEN o.orders ELSE 0 END) AS pinata_orders_true,
  SUM(CASE WHEN o.order_from_pinata = FALSE THEN o.orders ELSE 0 END) AS pinata_orders_false,
  SUM(o.orders) AS total_orders,
  -- Calculate percentages
  ROUND(
    (SUM(CASE WHEN o.order_from_pinata = TRUE THEN o.orders ELSE 0 END) * 100.0) / NULLIF(SUM(o.orders), 0), 
    2
  ) AS pinata_orders_true_percentage,
  ROUND(
    (SUM(CASE WHEN o.order_from_pinata = FALSE THEN o.orders ELSE 0 END) * 100.0) / NULLIF(SUM(o.orders), 0), 
    2
  ) AS pinata_orders_false_percentage
FROM orders o
LEFT JOIN nodal-talon-430216-q6.efood.rfm_table_April r
  ON o.customer_id = r.customer_id
WHERE r.Segment IS NOT NULL
GROUP BY r.Segment;
