WITH orders AS (
  SELECT
    customer_id,
    vertical,
    shop_cuisine,
    COUNT(order_id) AS orders
  FROM nodal-talon-430216-q6.efood.df
  GROUP BY customer_id, vertical, shop_cuisine
)

SELECT
  r.Segment,
  COUNT(DISTINCT o.customer_id) AS users,
  AVG(r.Monetary) AS avg_order_value,
  AVG(r.Frequency) AS avg_order_frequency
FROM orders o
LEFT JOIN nodal-talon-430216-q6.efood.rfm_table_April r
  ON o.customer_id = r.customer_id
WHERE r.Segment IS NOT NULL
GROUP BY r.Segment;

