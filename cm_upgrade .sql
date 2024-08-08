-- Common Table Expression (CTE) to join April and May data
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

-- Define a ranking order for the segments
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

-- Identify customers who have upgraded their segment
Upgraded_Customers AS (
    SELECT
        Segment_April,
        COUNT(customer_id) AS Upgraded_Count
    FROM
        Segment_Rank
    WHERE
        Rank_May < Rank_April  -- Rank_May is less (better) than Rank_April, indicating an upgrade
    GROUP BY
        Segment_April
),

-- Count all customers in each segment in April (even those who are not in May)
Total_Customers_April AS (
    SELECT
        Segment_April AS Segment,
        COUNT(DISTINCT customer_id) AS Total_Count_April
    FROM
        Segment_Rank
    GROUP BY
        Segment_April
)

-- Combine the results to get the percentage of customers upgrading
SELECT
    t.Segment AS Segment_April,
    COALESCE(u.Upgraded_Count, 0) AS Upgraded_Count,
    t.Total_Count_April,
    ROUND((COALESCE(u.Upgraded_Count, 0) / t.Total_Count_April) * 100, 2) AS Upgrade_Percentage
FROM
    Total_Customers_April AS t
LEFT JOIN
    Upgraded_Customers AS u
ON
    t.Segment = u.Segment_April
ORDER BY
    CASE t.Segment
        WHEN 'Platinum' THEN 1
        WHEN 'Gold' THEN 2
        WHEN 'Silver' THEN 3
        WHEN 'Loyal' THEN 4
        WHEN 'Common' THEN 5
    END;
