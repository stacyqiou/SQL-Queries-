WITH orders AS (
  SELECT
    customer_id,
    vertical,
    shop_cuisine,
    order_has_discount_coupon,
    COUNT(order_id) AS orders
  FROM nodal-talon-430216-q6.efood.df
  GROUP BY customer_id, vertical, shop_cuisine, order_has_discount_coupon
)

SELECT
  r.Segment,
  COUNT(DISTINCT o.customer_id) AS users,
  SUM(CASE WHEN o.order_has_discount_coupon = TRUE THEN o.orders ELSE 0 END) AS discount_coupon_true,
  SUM(CASE WHEN o.order_has_discount_coupon = FALSE THEN o.orders ELSE 0 END) AS discount_coupon_false,
  SUM(o.orders) AS total_orders,
  -- Calculate percentages
  ROUND(
    (SUM(CASE WHEN o.order_has_discount_coupon = TRUE THEN o.orders ELSE 0 END) * 100.0) / NULLIF(SUM(o.orders), 0), 
    2
  ) AS discount_coupon_true_percentage,
  ROUND(
    (SUM(CASE WHEN o.order_has_discount_coupon = FALSE THEN o.orders ELSE 0 END) * 100.0) / NULLIF(SUM(o.orders), 0), 
    2
  ) AS discount_coupon_false_percentage
FROM orders o
LEFT JOIN nodal-talon-430216-q6.efood.rfm_table_April r
  ON o.customer_id = r.customer_id
WHERE r.Segment IS NOT NULL
GROUP BY r.Segment;

