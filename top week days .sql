WITH orders AS (
  SELECT
    customer_id,
    vertical,
    shop_cuisine,
    EXTRACT(DAYOFWEEK FROM order_timestamp) AS order_day_of_week,
    COUNT(order_id) AS orders
  FROM `nodal-talon-430216-q6.efood.df`
  GROUP BY customer_id, vertical, shop_cuisine, EXTRACT(DAYOFWEEK FROM order_timestamp)
),
segment_orders AS (
  SELECT
    r.Segment,
    o.order_day_of_week,
    SUM(o.orders) AS total_orders_per_day
  FROM orders o
  LEFT JOIN `nodal-talon-430216-q6.efood.rfm_table_April` r
    ON o.customer_id = r.customer_id
  WHERE r.Segment IS NOT NULL
  GROUP BY r.Segment, o.order_day_of_week
),
ranked_days AS (
  SELECT
    Segment,
    order_day_of_week,
    total_orders_per_day,
    RANK() OVER (PARTITION BY Segment ORDER BY total_orders_per_day DESC) AS day_rank
  FROM segment_orders
),
top_days AS (
  SELECT
    Segment,
    MAX(CASE WHEN day_rank = 1 THEN order_day_of_week END) AS top_1st_week_day,
    MAX(CASE WHEN day_rank = 1 THEN total_orders_per_day END) AS top_1st_day_orders,
    MAX(CASE WHEN day_rank = 2 THEN order_day_of_week END) AS top_2nd_week_day,
    MAX(CASE WHEN day_rank = 2 THEN total_orders_per_day END) AS top_2nd_day_orders,
    MAX(CASE WHEN day_rank = 3 THEN order_day_of_week END) AS top_3rd_week_day,
    MAX(CASE WHEN day_rank = 3 THEN total_orders_per_day END) AS top_3rd_day_orders
  FROM ranked_days
  WHERE day_rank <= 3
  GROUP BY Segment
),
total_orders_per_segment AS (
  SELECT
    Segment,
    SUM(total_orders_per_day) AS segment_total_orders
  FROM segment_orders
  GROUP BY Segment
)

SELECT
  t.Segment,
  CASE t.top_1st_week_day
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
  END AS `top 1st week day`,
  ROUND(t.top_1st_day_orders / o.segment_total_orders * 100, 2) AS `percentage of orders on this day 1`,
  CASE t.top_2nd_week_day
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
  END AS `top 2nd week day`,
  ROUND(t.top_2nd_day_orders / o.segment_total_orders * 100, 2) AS `percentage of orders on this day 2`,
  CASE t.top_3rd_week_day
    WHEN 1 THEN 'Sunday'
    WHEN 2 THEN 'Monday'
    WHEN 3 THEN 'Tuesday'
    WHEN 4 THEN 'Wednesday'
    WHEN 5 THEN 'Thursday'
    WHEN 6 THEN 'Friday'
    WHEN 7 THEN 'Saturday'
  END AS `top 3rd week day`,
  ROUND(t.top_3rd_day_orders / o.segment_total_orders * 100, 2) AS `percentage of orders on this day 3`
FROM top_days t
JOIN total_orders_per_segment o
  ON t.Segment = o.Segment;
