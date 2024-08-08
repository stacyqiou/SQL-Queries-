WITH orders AS (
  SELECT
    customer_id,
    vertical,
    shop_cuisine,
    EXTRACT(HOUR FROM order_timestamp) AS order_hour,
    COUNT(order_id) AS orders,
    SUM(order_value_numeric) AS total_order_value
  FROM `nodal-talon-430216-q6.efood.df`
  GROUP BY customer_id, vertical, shop_cuisine, EXTRACT(HOUR FROM order_timestamp)
),
segment_orders AS (
  SELECT
    r.Segment,
    o.customer_id,
    SUM(CASE WHEN o.order_hour BETWEEN 5 AND 11 THEN o.orders ELSE 0 END) AS morning_orders,
    SUM(CASE WHEN o.order_hour BETWEEN 12 AND 17 THEN o.orders ELSE 0 END) AS afternoon_orders,
    SUM(CASE WHEN o.order_hour BETWEEN 18 AND 21 THEN o.orders ELSE 0 END) AS evening_orders,
    SUM(CASE WHEN o.order_hour BETWEEN 22 AND 23 OR o.order_hour BETWEEN 0 AND 4 THEN o.orders ELSE 0 END) AS night_orders,
    SUM(o.orders) AS total_orders,
    SUM(CASE WHEN o.order_hour BETWEEN 5 AND 11 THEN o.total_order_value ELSE 0 END) AS morning_order_value,
    SUM(CASE WHEN o.order_hour BETWEEN 12 AND 17 THEN o.total_order_value ELSE 0 END) AS afternoon_order_value,
    SUM(CASE WHEN o.order_hour BETWEEN 18 AND 21 THEN o.total_order_value ELSE 0 END) AS evening_order_value,
    SUM(CASE WHEN o.order_hour BETWEEN 22 AND 23 OR o.order_hour BETWEEN 0 AND 4 THEN o.total_order_value ELSE 0 END) AS night_order_value
  FROM orders o
  LEFT JOIN `nodal-talon-430216-q6.efood.rfm_table_April` r
    ON o.customer_id = r.customer_id
  WHERE r.Segment IS NOT NULL
  GROUP BY r.Segment, o.customer_id
)

SELECT
  Segment,
  COUNT(DISTINCT customer_id) AS users,
  SUM(morning_orders) AS morning_orders,
  SUM(afternoon_orders) AS afternoon_orders,
  SUM(evening_orders) AS evening_orders,
  SUM(night_orders) AS night_orders,
  SUM(total_orders) AS total_orders,
  ROUND(SUM(morning_orders) / SUM(total_orders) * 100, 2) AS morning_percentage,
  ROUND(SUM(afternoon_orders) / SUM(total_orders) * 100, 2) AS afternoon_percentage,
  ROUND(SUM(evening_orders) / SUM(total_orders) * 100, 2) AS evening_percentage,
  ROUND(SUM(night_orders) / SUM(total_orders) * 100, 2) AS night_percentage,
  ROUND(SUM(morning_order_value) / NULLIF(SUM(morning_orders), 0), 2) AS avg_morning_order_value,
  ROUND(SUM(afternoon_order_value) / NULLIF(SUM(afternoon_orders), 0), 2) AS avg_afternoon_order_value,
  ROUND(SUM(evening_order_value) / NULLIF(SUM(evening_orders), 0), 2) AS avg_evening_order_value,
  ROUND(SUM(night_order_value) / NULLIF(SUM(night_orders), 0), 2) AS avg_night_order_value
FROM segment_orders
GROUP BY Segment;
