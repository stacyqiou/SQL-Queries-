WITH CuisineOrderCounts AS (
  SELECT
    shop_cuisine,
    COUNT(*) AS order_count
  FROM
    `nodal-talon-430216-q6.efood.df`
  GROUP BY
    shop_cuisine
),
Top10Cuisines AS (
  SELECT
    shop_cuisine
  FROM
    CuisineOrderCounts
  ORDER BY
    order_count DESC
  LIMIT
    10
)
SELECT
  t.shop_cuisine,
  AVG(t.order_value_numeric) AS avg_order_value
FROM
  `nodal-talon-430216-q6.efood.df` t
JOIN
  Top10Cuisines tc
ON
  t.shop_cuisine = tc.shop_cuisine
GROUP BY
  t.shop_cuisine
ORDER BY
  avg_order_value DESC;
