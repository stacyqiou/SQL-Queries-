WITH Lost_Customers AS (
    SELECT
        a.Frequency_Segment,
        COUNT(a.customer_id) AS Lost_Customer_Count
    FROM
        nodal-talon-430216-q6.efood.rfm_table_April AS a
    LEFT JOIN
        nodal-talon-430216-q6.efood.rfm_table_May AS m
    ON
        a.customer_id = m.customer_id
    WHERE
        m.customer_id IS NULL
    AND
        a.Segment = 'Common'
    GROUP BY
        a.Frequency_Segment
),

New_Customers AS (
    SELECT
        m.Frequency_Segment,
        COUNT(m.customer_id) AS New_Customer_Count
    FROM
        nodal-talon-430216-q6.efood.rfm_table_May AS m
    LEFT JOIN
        nodal-talon-430216-q6.efood.rfm_table_April AS a
    ON
        m.customer_id = a.customer_id
    WHERE
        a.customer_id IS NULL
    AND
        m.Segment = 'Common'
    GROUP BY
        m.Frequency_Segment
)

SELECT
    COALESCE(l.Frequency_Segment, n.Frequency_Segment) AS Frequency_Segment,
    COALESCE(n.New_Customer_Count, 0) AS New_Common,
    COALESCE(l.Lost_Customer_Count, 0) AS Lost_Common
FROM
    New_Customers n
FULL OUTER JOIN
    Lost_Customers l
ON
    n.Frequency_Segment = l.Frequency_Segment
ORDER BY
    Frequency_Segment;
