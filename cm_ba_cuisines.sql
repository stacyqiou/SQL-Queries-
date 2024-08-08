-- Identify customers who upgraded from one segment to another
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

-- Determine the top cuisines for each segment in April
Customer_Cuisines_April AS (
    SELECT
        customer_id,
        shop_cuisine,
        COUNT(*) AS frequency
    FROM
        nodal-talon-430216-q6.efood.df
    WHERE
        customer_id IN (SELECT customer_id FROM Segment_Rank WHERE Rank_April IS NOT NULL)
    GROUP BY
        customer_id,
        shop_cuisine
),

Favorite_Cuisines_April AS (
    SELECT
        sr.Segment_April AS Segment,
        cc.shop_cuisine,
        SUM(cc.frequency) AS total_frequency
    FROM
        Segment_Rank AS sr
    JOIN
        Customer_Cuisines_April AS cc
    ON
        sr.customer_id = cc.customer_id
    GROUP BY
        sr.Segment_April,
        cc.shop_cuisine
),

Ranked_Cuisines_April AS (
    SELECT
        Segment,
        shop_cuisine,
        total_frequency,
        RANK() OVER (PARTITION BY Segment ORDER BY total_frequency DESC) AS rank
    FROM
        Favorite_Cuisines_April
),

Top_Cuisines_April AS (
    SELECT
        Segment,
        shop_cuisine
    FROM
        Ranked_Cuisines_April
    WHERE
        rank <= 3  -- Top 3 cuisines for each segment
),

-- Determine the top cuisines for each segment in May
Customer_Cuisines_May AS (
    SELECT
        customer_id,
        shop_cuisine,
        COUNT(*) AS frequency
    FROM
        nodal-talon-430216-q6.efood.df_May
    WHERE
        customer_id IN (SELECT customer_id FROM Segment_Rank WHERE Rank_May IS NOT NULL)
    GROUP BY
        customer_id,
        shop_cuisine
),

Favorite_Cuisines_May AS (
    SELECT
        sr.Segment_May AS Segment,
        cc.shop_cuisine,
        SUM(cc.frequency) AS total_frequency
    FROM
        Segment_Rank AS sr
    JOIN
        Customer_Cuisines_May AS cc
    ON
        sr.customer_id = cc.customer_id
    GROUP BY
        sr.Segment_May,
        cc.shop_cuisine
),

Ranked_Cuisines_May AS (
    SELECT
        Segment,
        shop_cuisine,
        total_frequency,
        RANK() OVER (PARTITION BY Segment ORDER BY total_frequency DESC) AS rank
    FROM
        Favorite_Cuisines_May
),

Top_Cuisines_May AS (
    SELECT
        Segment,
        shop_cuisine
    FROM
        Ranked_Cuisines_May
    WHERE
        rank <= 3  -- Top 3 cuisines for each segment
),

-- Combine the results to get the count of upgrades and compare top cuisines
Upgrade_Cuisine_Comparison AS (
    SELECT
        uc.Segment_April,
        uc.Segment_May AS Upgraded_Segment,
        tc_a.shop_cuisine AS Favorite_Cuisine_April,
        tc_m.shop_cuisine AS Favorite_Cuisine_Now,
        uc.Upgraded_Count
    FROM
        Upgraded_Customers AS uc
    JOIN
        Top_Cuisines_April AS tc_a
    ON
        uc.Segment_April = tc_a.Segment
    JOIN
        Top_Cuisines_May AS tc_m
    ON
        uc.Segment_May = tc_m.Segment
)
-- Output the results
SELECT
    Segment_April,
    STRING_AGG(DISTINCT Favorite_Cuisine_April) AS Favorite_Cuisines_April,
    Upgraded_Segment AS Upgraded_Segment,
    STRING_AGG(DISTINCT Favorite_Cuisine_Now) AS Favorite_Cuisines_Now,
    Upgraded_Count AS Count_of_Upgrades
FROM
    Upgrade_Cuisine_Comparison
GROUP BY
    Segment_April,
    Upgraded_Segment,
    Upgraded_Count
ORDER BY
    Segment_April,
    Upgraded_Segment;
