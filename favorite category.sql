WITH orders AS (
  SELECT
    customer_id,
    vertical,
    shop_cuisine,
    category_name,  -- Ensure this column exists in your data
    COUNT(order_id) AS orders
  FROM `nodal-talon-430216-q6.efood.df`
  GROUP BY customer_id, vertical, shop_cuisine, category_name
),

segment_categories AS (
  SELECT
    r.Segment,
    o.category_name,
    SUM(o.orders) AS category_orders
  FROM orders o
  LEFT JOIN `nodal-talon-430216-q6.efood.rfm_table_April` r
    ON o.customer_id = r.customer_id
  GROUP BY r.Segment, o.category_name
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

ranked_categories AS (
  SELECT
    sc.Segment,
    sc.category_name,
    sc.category_orders,
    ROW_NUMBER() OVER (PARTITION BY sc.Segment ORDER BY sc.category_orders DESC) AS rank
  FROM segment_categories sc
),

favorite_categories AS (
  SELECT
    rc.Segment,
    MAX(CASE WHEN rc.rank = 1 THEN rc.category_name END) AS favorite_category,
    MAX(CASE WHEN rc.rank = 1 THEN rc.category_orders END) AS favorite_category_orders,
    MAX(CASE WHEN rc.rank = 2 THEN rc.category_name END) AS second_favorite_category,
    MAX(CASE WHEN rc.rank = 2 THEN rc.category_orders END) AS second_favorite_category_orders,
    MAX(CASE WHEN rc.rank = 3 THEN rc.category_name END) AS third_favorite_category,
    MAX(CASE WHEN rc.rank = 3 THEN rc.category_orders END) AS third_favorite_category_orders
  FROM ranked_categories rc
  GROUP BY rc.Segment
)

SELECT
  fc.Segment,
  COUNT(DISTINCT r.customer_id) AS users,
  fc.favorite_category,
  fc.favorite_category_orders,
  (fc.favorite_category_orders / t.total_orders * 100) AS favorite_category_percentage,
  fc.second_favorite_category,
  fc.second_favorite_category_orders,
  (fc.second_favorite_category_orders / t.total_orders * 100) AS second_favorite_category_percentage,
  fc.third_favorite_category,
  fc.third_favorite_category_orders,
  (fc.third_favorite_category_orders / t.total_orders * 100) AS third_favorite_category_percentage
FROM favorite_categories fc
LEFT JOIN `nodal-talon-430216-q6.efood.rfm_table_April` r
  ON r.Segment = fc.Segment
LEFT JOIN total_orders_per_segment t
  ON fc.Segment = t.Segment
WHERE r.Segment IS NOT NULL
GROUP BY fc.Segment, fc.favorite_category, fc.favorite_category_orders, fc.second_favorite_category, fc.second_favorite_category_orders, fc.third_favorite_category, fc.third_favorite_category_orders, t.total_orders;
