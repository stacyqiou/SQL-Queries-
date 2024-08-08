WITH orders AS (
  SELECT
    customer_id,
    vertical,
    shop_cuisine,
    EXTRACT(HOUR FROM order_timestamp) AS order_hour,
    COUNT(order_id) AS orders
  FROM `nodal-talon-430216-q6.efood.df`
  GROUP BY customer_id, vertical, shop_cuisine, EXTRACT(HOUR FROM order_timestamp)
),
segment_orders AS (
  SELECT
    r.Segment,
    o.customer_id,
    shop_cuisine,
    SUM(CASE WHEN o.order_hour BETWEEN 5 AND 11 THEN o.orders ELSE 0 END) AS morning_orders,
    SUM(CASE WHEN o.order_hour BETWEEN 12 AND 17 THEN o.orders ELSE 0 END) AS afternoon_orders,
    SUM(CASE WHEN o.order_hour BETWEEN 18 AND 21 THEN o.orders ELSE 0 END) AS evening_orders,
    SUM(CASE WHEN o.order_hour BETWEEN 22 AND 23 OR o.order_hour BETWEEN 0 AND 4 THEN o.orders ELSE 0 END) AS night_orders,
    SUM(o.orders) AS total_orders
  FROM orders o
  LEFT JOIN `nodal-talon-430216-q6.efood.rfm_table_April` r
    ON o.customer_id = r.customer_id
  WHERE r.Segment IS NOT NULL
  GROUP BY r.Segment, o.customer_id, o.shop_cuisine
),
top_cuisines AS (
  SELECT
    Segment,
    shop_cuisine,
    SUM(morning_orders) AS morning_orders,
    SUM(afternoon_orders) AS afternoon_orders,
    SUM(evening_orders) AS evening_orders,
    SUM(night_orders) AS night_orders,
    ROW_NUMBER() OVER (PARTITION BY Segment ORDER BY SUM(morning_orders) DESC) AS morning_rank,
    ROW_NUMBER() OVER (PARTITION BY Segment ORDER BY SUM(afternoon_orders) DESC) AS afternoon_rank,
    ROW_NUMBER() OVER (PARTITION BY Segment ORDER BY SUM(evening_orders) DESC) AS evening_rank,
    ROW_NUMBER() OVER (PARTITION BY Segment ORDER BY SUM(night_orders) DESC) AS night_rank
  FROM segment_orders
  GROUP BY Segment, shop_cuisine
)
SELECT
  so.Segment,
  COUNT(DISTINCT so.customer_id) AS users,
  SUM(so.morning_orders) AS morning_orders,
  SUM(so.afternoon_orders) AS afternoon_orders,
  SUM(so.evening_orders) AS evening_orders,
  SUM(so.night_orders) AS night_orders,
  SUM(so.total_orders) AS total_orders,
  ROUND(SUM(so.morning_orders) / SUM(so.total_orders) * 100, 2) AS morning_percentage,
  ROUND(SUM(so.afternoon_orders) / SUM(so.total_orders) * 100, 2) AS afternoon_percentage,
  ROUND(SUM(so.evening_orders) / SUM(so.total_orders) * 100, 2) AS evening_percentage,
  ROUND(SUM(so.night_orders) / SUM(so.total_orders) * 100, 2) AS night_percentage,
  MAX(CASE WHEN tc.morning_rank = 1 THEN tc.shop_cuisine ELSE NULL END) AS top_morning_cuisine,
  MAX(CASE WHEN tc.afternoon_rank = 1 THEN tc.shop_cuisine ELSE NULL END) AS top_afternoon_cuisine,
  MAX(CASE WHEN tc.evening_rank = 1 THEN tc.shop_cuisine ELSE NULL END) AS top_evening_cuisine,
  MAX(CASE WHEN tc.night_rank = 1 THEN tc.shop_cuisine ELSE NULL END) AS top_night_cuisine
FROM segment_orders so
LEFT JOIN top_cuisines tc
  ON so.Segment = tc.Segment
GROUP BY so.Segment
ORDER BY so.Segment;
