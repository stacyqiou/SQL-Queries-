WITH orders AS (
  SELECT
    customer_id,
    vertical,
    shop_cuisine,
    COUNT(order_id) AS orders
  FROM `nodal-talon-430216-q6.efood.df`
  GROUP BY customer_id, vertical, shop_cuisine
),

segment_orders AS (
  SELECT
    r.Segment,
    o.shop_cuisine,
    SUM(o.orders) AS cuisine_orders
  FROM orders o
  LEFT JOIN `nodal-talon-430216-q6.efood.rfm_table_April` r
    ON o.customer_id = r.customer_id
  GROUP BY r.Segment, o.shop_cuisine
),

total_orders_per_segment AS (
  SELECT
    r.Segment,
    SUM(o.orders) AS total_orders
  FROM orders o
  LEFT JOIN `nodal-talon-430216-q6.efood.rfm_table_April` r
    ON o.customer_id = r.customer_id
  GROUP BY r.Segment
),

ranked_cuisines AS (
  SELECT
    so.Segment,
    so.shop_cuisine,
    so.cuisine_orders,
    ROW_NUMBER() OVER (PARTITION BY so.Segment ORDER BY so.cuisine_orders DESC) AS rank
  FROM segment_orders so
),

favorite_cuisines AS (
  SELECT
    rc.Segment,
    MAX(CASE WHEN rc.rank = 1 THEN rc.shop_cuisine END) AS favorite_cuisine,
    MAX(CASE WHEN rc.rank = 1 THEN rc.cuisine_orders END) AS favorite_cuisine_orders,
    MAX(CASE WHEN rc.rank = 2 THEN rc.shop_cuisine END) AS second_favorite_cuisine,
    MAX(CASE WHEN rc.rank = 2 THEN rc.cuisine_orders END) AS second_favorite_cuisine_orders,
    MAX(CASE WHEN rc.rank = 3 THEN rc.shop_cuisine END) AS third_favorite_cuisine,
    MAX(CASE WHEN rc.rank = 3 THEN rc.cuisine_orders END) AS third_favorite_cuisine_orders
  FROM ranked_cuisines rc
  GROUP BY rc.Segment
)

SELECT
  fc.Segment,
  COUNT(DISTINCT r.customer_id) AS users,
  fc.favorite_cuisine,
  fc.favorite_cuisine_orders,
  (fc.favorite_cuisine_orders / t.total_orders * 100) AS favorite_cuisine_percentage,
  fc.second_favorite_cuisine,
  fc.second_favorite_cuisine_orders,
  (fc.second_favorite_cuisine_orders / t.total_orders * 100) AS second_favorite_cuisine_percentage,
  fc.third_favorite_cuisine,
  fc.third_favorite_cuisine_orders,
  (fc.third_favorite_cuisine_orders / t.total_orders * 100) AS third_favorite_cuisine_percentage
FROM favorite_cuisines fc
LEFT JOIN `nodal-talon-430216-q6.efood.rfm_table_April` r
  ON r.Segment = fc.Segment
LEFT JOIN total_orders_per_segment t
  ON fc.Segment = t.Segment
WHERE r.Segment IS NOT NULL
GROUP BY fc.Segment, fc.favorite_cuisine, fc.favorite_cuisine_orders, fc.second_favorite_cuisine, fc.second_favorite_cuisine_orders, fc.third_favorite_cuisine, fc.third_favorite_cuisine_orders, t.total_orders;
