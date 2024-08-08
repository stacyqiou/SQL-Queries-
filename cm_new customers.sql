-- First, create a subquery to identify customers who are only in May but not in April
WITH New_Customers AS (
    SELECT
        m.customer_id,
        m.Segment
    FROM
        nodal-talon-430216-q6.efood.rfm_table_May AS m
    LEFT JOIN
        nodal-talon-430216-q6.efood.rfm_table_April AS a
    ON
        m.customer_id = a.customer_id
    WHERE
        a.customer_id IS NULL
)

-- Then, count the number of new customers in each segment
SELECT
    Segment,
    COUNT(customer_id) AS New_Customer_Count
FROM
    New_Customers
GROUP BY
    Segment
ORDER BY
    Segment;

