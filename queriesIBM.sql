--overall churn rate for the customers
SELECT
    COUNT(*) AS total_customers,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_percentage
FROM customers;

-- total revenue loss dure to churned customers
SELECT
    ROUND(SUM(monthlycharges), 2) AS monthly_revenue_lost,
    ROUND(SUM(totalcharges), 2) AS lifetime_revenue_lost
FROM customers
WHERE churn = 'Yes';

-- average tenure and monthly charges for churned vs retained customers
SELECT
    churn,
    ROUND(AVG(tenure), 1) AS avg_tenure_months,
    ROUND(AVG(monthlycharges), 2) AS avg_monthly_charges,
    COUNT(*) AS customer_count
FROM customers
GROUP BY churn;

--churn rate by contact type
SELECT
    contract,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_percentage,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthlycharges ELSE 0 END), 2) AS revenue_at_risk
FROM customers
GROUP BY contract
ORDER BY churn_percentage DESC;

--churn rate by internet service
SELECT
    internetservice,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_percentage
FROM customers
GROUP BY internetservice
ORDER BY churn_percentage DESC;

--churn rate by payment method
SELECT
    paymentmethod,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_percentage
FROM customers
GROUP BY paymentmethod
ORDER BY churn_percentage DESC;

--churn rate by gender
SELECT
    gender,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_percentage
FROM customers
GROUP BY gender
ORDER BY churn_percentage DESC;

--churn rate by senior citizen status
SELECT
    CASE WHEN seniorcitizen = 1 THEN 'Senior' ELSE 'Non-Senior' END AS segment,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_percentage
FROM customers
GROUP BY segment
ORDER BY churn_percentage DESC;

--churn by tenure 
SELECT
    CASE
        WHEN CAST(tenure AS INTEGER) BETWEEN 0  AND 12 THEN '0–12 months'
        WHEN CAST(tenure AS INTEGER) BETWEEN 13 AND 24 THEN '13–24 months'
        WHEN CAST(tenure AS INTEGER) BETWEEN 25 AND 48 THEN '25–48 months'
        ELSE '49+ months'
    END AS tenure_bucket,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2) AS churn_percentage,
    ROUND(AVG(monthlycharges), 2) AS avg_monthly_charges
FROM customers
GROUP BY tenure_bucket
ORDER BY MIN(tenure);



--high value customer analysis
WITH ranked AS (
    SELECT
        customerid,
        monthlycharges,
        totalcharges,
        tenure,
        contract,
        internetservice,
        churn,
        NTILE(4) OVER (ORDER BY monthlycharges) AS quartile
    FROM customers
)
SELECT
    customerid,
    monthlycharges,
    totalcharges,
    tenure,
    contract,
    internetservice,
    churn
FROM ranked
WHERE quartile = 4   -- top 25% (above 75th percentile)
  AND churn = 'Yes'
ORDER BY monthlycharges DESC;

-- 4.2 Revenue concentration — top 20% customers contribute what % of revenue?
WITH ranked AS (
    SELECT
        customerid,
        monthlycharges,
        NTILE(5) OVER (ORDER BY monthlycharges DESC) AS revenue_quintile
    FROM customers
)
SELECT
    revenue_quintile,
    COUNT(*) AS customer_count,
    ROUND(SUM(monthlycharges), 2)  AS total_monthly_revenue,
    ROUND(100.0 * SUM(monthlycharges) /SUM(SUM(monthlycharges)) OVER (), 2) AS revenue_percentage
FROM ranked
GROUP BY revenue_quintile
ORDER BY revenue_quintile;


--high risk, high value segment
SELECT
    contract,
    internetservice,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned,
    ROUND(AVG(monthlycharges), 2) AS avg_monthly_charges,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthlycharges ELSE 0 END), 2) AS revenue_at_risk
FROM customers
WHERE monthlycharges > 60   -- above-average charges
GROUP BY contract, internetservice
ORDER BY revenue_at_risk DESC;


--retention rate by contract and tenure
SELECT
    contract,
    CASE
        WHEN CAST(tenure AS INTEGER) BETWEEN 0  AND 12 THEN '0–12 months'
        WHEN CAST(tenure AS INTEGER) BETWEEN 13 AND 24 THEN '13–24 months'
        WHEN CAST(tenure AS INTEGER) BETWEEN 25 AND 48 THEN '25–48 months'
        ELSE '49+ months'
    END AS tenure_bucket,
    COUNT(*) AS total,
    SUM(CASE WHEN churn = 'No' THEN 1 ELSE 0 END) AS retained,
    ROUND(100.0 * SUM(CASE WHEN churn = 'No' THEN 1 ELSE 0 END) / COUNT(*), 2) AS retention_percentage,
    ROUND(AVG(monthlycharges), 2) AS avg_monthly_charges
FROM customers
GROUP BY contract,tenure_bucket
ORDER BY contract,MIN(tenure);


-- 5.2 Monthly revenue retained vs lost per tenure cohort
SELECT
    CASE
        WHEN CAST(tenure AS INTEGER) BETWEEN 0  AND 12 THEN '0–12 months'
        WHEN CAST(tenure AS INTEGER)  BETWEEN 13 AND 24 THEN '13–24 months'
        WHEN CAST(tenure AS INTEGER)  BETWEEN 25 AND 48 THEN '25–48 months'
        ELSE '49+ months'
    END                                                                       AS tenure_cohort,
    ROUND(SUM(CASE WHEN churn = 'No'  THEN monthlycharges ELSE 0 END), 2)   AS revenue_retained,
    ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthlycharges ELSE 0 END), 2)   AS revenue_lost,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN monthlycharges ELSE 0 END) /
        SUM(monthlycharges), 2
    ) AS precentage_revenue_lost
FROM customers
GROUP BY tenure_cohort
ORDER BY MIN(tenure);

--cumulative revenue at risk
SELECT
    customerid,
    monthlycharges,
    churn,
    SUM(CASE WHEN churn = 'Yes' THEN monthlycharges ELSE 0 END)
        OVER (ORDER BY monthlycharges DESC
              ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue_at_risk
FROM customers
ORDER BY monthlycharges DESC;

--customers within each contract type by monthly charges
SELECT
    customerid,
    contract,
    monthlycharges,
    churn,
    RANK()       OVER (PARTITION BY contract ORDER BY monthlycharges DESC) AS rank_in_contract,
    DENSE_RANK()       OVER (PARTITION BY contract ORDER BY monthlycharges DESC) AS denserank_in_contract,
    ROW_NUMBER()       OVER (PARTITION BY contract ORDER BY monthlycharges DESC) AS rownumber_in_contract,
    NTILE(4)     OVER (PARTITION BY contract ORDER BY monthlycharges DESC) AS charge_quartile,
    ROUND(AVG(monthlycharges) OVER (PARTITION BY contract), 2)            AS avg_charges_in_contract
FROM customers
ORDER BY contract, rownumber_in_contract;

--month over month churn trend simulation
SELECT
    tenure AS months_as_customer,
    COUNT(*) AS total_at_tenure,
    SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) AS churned_at_tenure,
    ROUND(
        100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2
    )                                                               AS churn_percentage,
    ROUND(
        AVG(
            100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*)
        ) OVER (ORDER BY tenure ROWS BETWEEN 2 PRECEDING AND CURRENT ROW), 2
    )                                                               AS rolling_3m_avg_churn_rate
FROM customers
GROUP BY tenure
ORDER BY tenure;


CREATE VIEW churn_summary AS
 
-- Metric 1: Overall churn rate
SELECT
    'Overall Churn Rate'                                             AS metric,
    CONCAT(
        ROUND(100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2),
        '%'
    )                                                                AS value
FROM customers
 
UNION ALL
 
-- Metric 2: Monthly revenue at risk from churned customers
SELECT
    'Monthly Revenue at Risk',
    CONCAT(
        '$',
        ROUND(SUM(CASE WHEN churn = 'Yes' THEN monthlycharges ELSE 0 END), 2)
    )
FROM customers
 
UNION ALL
 
-- Metric 3: Highest churn segment — dynamically derived from data
SELECT
    'Highest Churn Segment',
    contract
FROM (
    SELECT
        contract,
        ROUND(
            100.0 * SUM(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) / COUNT(*), 2
        ) AS churn_rate
    FROM customers
    GROUP BY contract
    ORDER BY churn_rate DESC
    LIMIT 1
) AS top_segment
 
UNION ALL
 
-- Metric 4: Average tenure before churn
SELECT
    'Avg Tenure Before Churn',
    CONCAT(
        ROUND(AVG(CASE WHEN churn = 'Yes' THEN tenure END), 1),
        ' months'
    )
FROM customers
 
UNION ALL
 
-- Metric 5: Total customers at churn risk (predicted high risk = monthly charges > 60 + month-to-month)
SELECT
    'High-Risk Customers (Month-to-Month + High Charges)',
    CAST(
        COUNT(*) AS TEXT
    )
FROM customers
WHERE contract = 'Month-to-month'
  AND monthlycharges > 60
  AND churn = 'No';   -- still active but high risk profile
 
-- Query the summary view
SELECT * FROM churn_summary;