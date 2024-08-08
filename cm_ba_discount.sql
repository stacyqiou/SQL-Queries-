WITH Customer_Segments AS (
    SELECT
        a.customer_id,
        a.Segment AS Segment_April,
        m.Segment AS Segment_May
    FROM
        nodal-talon-430216-q6.efood.rfm_table_April AS a
    LEFT JOIN
        nodal-talon-430216-q6.efood.rfm_table_May AS m
    ON
        a.customer_id = m.customer_id
),

Segment_Rank AS (
    SELECT
        customer_id,
        Segment_April,
        Segment_May,
        CASE Segment_April
            WHEN 'Platinum' THEN 1
            WHEN 'Gold' THEN 2
            WHEN 'Silver' THEN 3
            WHEN 'Loyal' THEN 4
            WHEN 'Common' THEN 5
        END AS Rank_April,
        CASE Segment_May
            WHEN 'Platinum' THEN 1
            WHEN 'Gold' THEN 2
            WHEN 'Silver' THEN 3
            WHEN 'Loyal' THEN 4
            WHEN 'Common' THEN 5
        END AS Rank_May
    FROM
        Customer_Segments
),

Upgraded_Customers AS (
    SELECT
        Segment_April,
        Segment_May,
        COUNT(customer_id) AS Upgraded_Count
    FROM
        Segment_Rank
    WHERE
        Rank_May < Rank_April  -- Indicates an upgrade
    GROUP BY
        Segment_April, Segment_May
),

-- Calculate orders and discount coupon usage before the upgrade (April)
Order_Discount_April AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders_april,
        SUM(CASE WHEN order_has_discount_coupon THEN 1 ELSE 0 END) AS discount_orders_april
    FROM
        nodal-talon-430216-q6.efood.df
    WHERE
        customer_id IN (SELECT customer_id FROM Segment_Rank WHERE Rank_April IS NOT NULL)
    GROUP BY
        customer_id
),

-- Calculate orders and discount coupon usage after the upgrade (May)
Order_Discount_May AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders_may,
        SUM(CASE WHEN order_has_discount_coupon THEN 1 ELSE 0 END) AS discount_orders_may
    FROM
        nodal-talon-430216-q6.efood.df_May
    WHERE
        customer_id IN (SELECT customer_id FROM Segment_Rank WHERE Rank_May IS NOT NULL)
    GROUP BY
        customer_id
),

-- Calculate percentage of orders with discount coupons before and after the upgrade
Discount_Percentage AS (
    SELECT
        sr.customer_id,
        sr.Segment_April,
        sr.Segment_May,
        od_a.total_orders_april,
        od_a.discount_orders_april,
        (od_a.discount_orders_april / od_a.total_orders_april) * 100 AS discount_percentage_april,
        od_m.total_orders_may,
        od_m.discount_orders_may,
        (od_m.discount_orders_may / od_m.total_orders_may) * 100 AS discount_percentage_may
    FROM
        Segment_Rank AS sr
    LEFT JOIN
        Order_Discount_April AS od_a
    ON
        sr.customer_id = od_a.customer_id
    LEFT JOIN
        Order_Discount_May AS od_m
    ON
        sr.customer_id = od_m.customer_id
),

-- Combine the results to get the count of upgrades and compare discount percentages
Upgrade_Cuisine_Comparison AS (
    SELECT
        uc.Segment_April,
        uc.Segment_May AS Upgraded_Segment,
        uc.Upgraded_Count,
        AVG(dp.discount_percentage_april) AS avg_discount_percentage_april,
        AVG(dp.discount_percentage_may) AS avg_discount_percentage_may
    FROM
        Upgraded_Customers AS uc
    JOIN
        Discount_Percentage AS dp
    ON
        uc.Segment_April = dp.Segment_April
    AND
        uc.Segment_May = dp.Segment_May
    GROUP BY
        uc.Segment_April, uc.Segment_May, uc.Upgraded_Count
)

-- Output the results
SELECT
    Segment_April,
    Upgraded_Segment,
    Upgraded_Count,
    avg_discount_percentage_april AS Discount_Percentage_April,
    avg_discount_percentage_may AS Discount_Percentage_May
FROM
    Upgrade_Cuisine_Comparison
ORDER BY
    Segment_April,
    Upgraded_Segment;
