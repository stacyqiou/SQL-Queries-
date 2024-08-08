-- Step 1: Calculate the total number of customers in each segment in April
WITH Total_Customers_April AS (
    SELECT
        Segment AS Segment_April,
        COUNT(customer_id) AS Total_Customers
    FROM
        nodal-talon-430216-q6.efood.rfm_table_April
    GROUP BY
        Segment
),

-- Step 2: Identify customers who were in April but not in May
Lost_Customers AS (
    SELECT
        a.Segment AS Segment_April,
        COUNT(a.customer_id) AS Lost_Customer_Count
    FROM
        nodal-talon-430216-q6.efood.rfm_table_April AS a
    LEFT JOIN
        nodal-talon-430216-q6.efood.rfm_table_May AS m
    ON
        a.customer_id = m.customer_id
    WHERE
        m.customer_id IS NULL
    GROUP BY
        a.Segment
)

-- Step 3: Calculate the percentage of lost customers relative to the total number of customers in each segment
SELECT
    t.Segment_April AS Segment,
    COALESCE(l.Lost_Customer_Count, 0) AS Lost_Customer_Count,
    t.Total_Customers,
    CASE
        WHEN t.Total_Customers > 0 THEN
            (COALESCE(l.Lost_Customer_Count, 0) * 100.0 / t.Total_Customers)
        ELSE
            0
    END AS Lost_Percentage
FROM
    Total_Customers_April AS t
LEFT JOIN
    Lost_Customers AS l
ON
    t.Segment_April = l.Segment_April
ORDER BY
    t.Segment_April;
