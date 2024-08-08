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

-- Calculate orders and Pinata order usage before the upgrade (April)
Order_Pinata_April AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders_april,
        SUM(CASE WHEN order_from_pinata THEN 1 ELSE 0 END) AS pinata_orders_april
    FROM
        nodal-talon-430216-q6.efood.df
    WHERE
        customer_id IN (SELECT customer_id FROM Segment_Rank WHERE Rank_April IS NOT NULL)
    GROUP BY
        customer_id
),

-- Calculate orders and Pinata order usage after the upgrade (May)
Order_Pinata_May AS (
    SELECT
        customer_id,
        COUNT(order_id) AS total_orders_may,
        SUM(CASE WHEN order_from_pinata THEN 1 ELSE 0 END) AS pinata_orders_may
    FROM
        nodal-talon-430216-q6.efood.df_May
    WHERE
        customer_id IN (SELECT customer_id FROM Segment_Rank WHERE Rank_May IS NOT NULL)
    GROUP BY
        customer_id
),

-- Calculate percentage of Pinata orders before and after the upgrade
Pinata_Percentage AS (
    SELECT
        sr.customer_id,
        sr.Segment_April,
        sr.Segment_May,
        od_a.total_orders_april,
        od_a.pinata_orders_april,
        (od_a.pinata_orders_april / od_a.total_orders_april) * 100 AS pinata_percentage_april,
        od_m.total_orders_may,
        od_m.pinata_orders_may,
        (od_m.pinata_orders_may / od_m.total_orders_may) * 100 AS pinata_percentage_may
    FROM
        Segment_Rank AS sr
    LEFT JOIN
        Order_Pinata_April AS od_a
    ON
        sr.customer_id = od_a.customer_id
    LEFT JOIN
        Order_Pinata_May AS od_m
    ON
        sr.customer_id = od_m.customer_id
),

-- Combine the results to get the count of upgrades and compare Pinata percentages
Upgrade_Cuisine_Comparison AS (
    SELECT
        uc.Segment_April,
        uc.Segment_May AS Upgraded_Segment,
        uc.Upgraded_Count,
        AVG(dp.pinata_percentage_april) AS avg_pinata_percentage_april,
        AVG(dp.pinata_percentage_may) AS avg_pinata_percentage_may
    FROM
        Upgraded_Customers AS uc
    JOIN
        Pinata_Percentage AS dp
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
    avg_pinata_percentage_april AS Pinata_Percentage_April,
    avg_pinata_percentage_may AS Pinata_Percentage_May
FROM
    Upgrade_Cuisine_Comparison
ORDER BY
    Segment_April,
    Upgraded_Segment;
