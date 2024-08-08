WITH item_orders AS (
  SELECT
    customer_id,
    vertical,
    item_name,
    COUNT(order_id) AS orders
  FROM `nodal-talon-430216-q6.efood.df`
  GROUP BY customer_id, vertical, item_name
),

segment_item_orders AS (
  SELECT
    r.Segment,
    io.item_name,
    SUM(io.orders) AS item_orders
  FROM item_orders io
  LEFT JOIN `nodal-talon-430216-q6.efood.rfm_table_April` r
    ON io.customer_id = r.customer_id
  GROUP BY r.Segment, io.item_name
),

total_orders_per_segment AS (
  SELECT
    r.Segment,
    SUM(io.orders) AS total_orders
  FROM item_orders io
  LEFT JOIN `nodal-talon-430216-q6.efood.rfm_table_April` r
    ON io.customer_id = r.customer_id
  GROUP BY r.Segment
),

ranked_items AS (
  SELECT
    sio.Segment,
    sio.item_name,
    sio.item_orders,
    ROW_NUMBER() OVER (PARTITION BY sio.Segment ORDER BY sio.item_orders DESC) AS rank
  FROM segment_item_orders sio
),

favorite_items AS (
  SELECT
    ri.Segment,
    MAX(CASE WHEN ri.rank = 1 THEN ri.item_name END) AS favorite_item,
    MAX(CASE WHEN ri.rank = 1 THEN ri.item_orders END) AS favorite_item_orders,
    MAX(CASE WHEN ri.rank = 2 THEN ri.item_name END) AS second_favorite_item,
    MAX(CASE WHEN ri.rank = 2 THEN ri.item_orders END) AS second_favorite_item_orders,
    MAX(CASE WHEN ri.rank = 3 THEN ri.item_name END) AS third_favorite_item,
    MAX(CASE WHEN ri.rank = 3 THEN ri.item_orders END) AS third_favorite_item_orders
  FROM ranked_items ri
  GROUP BY ri.Segment
)

SELECT
  fi.Segment,
  COUNT(DISTINCT r.customer_id) AS users,
  fi.favorite_item,
  fi.favorite_item_orders,
  (fi.favorite_item_orders / t.total_orders * 100) AS favorite_item_percentage,
  fi.second_favorite_item,
  fi.second_favorite_item_orders,
  (fi.second_favorite_item_orders / t.total_orders * 100) AS second_favorite_item_percentage,
  fi.third_favorite_item,
  fi.third_favorite_item_orders,
  (fi.third_favorite_item_orders / t.total_orders * 100) AS third_favorite_item_percentage
FROM favorite_items fi
LEFT JOIN `nodal-talon-430216-q6.efood.rfm_table_April` r
  ON r.Segment = fi.Segment
LEFT JOIN total_orders_per_segment t
  ON fi.Segment = t.Segment
WHERE r.Segment IS NOT NULL
GROUP BY fi.Segment, fi.favorite_item, fi.favorite_item_orders, fi.second_favorite_item, fi.second_favorite_item_orders, fi.third_favorite_item, fi.third_favorite_item_orders, t.total_orders;
