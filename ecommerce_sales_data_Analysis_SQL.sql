-- ============================================================
--   E-COMMERCE SALES ANALYTICS — MySQL Data Analyst Project
--   Author  : [Aleena Hanjgikar]
--   Database: ecommerce_db
--   Dataset : Indian E-Commerce Sales (Mar 2026)
--   GitHub  : github.com/[your-username]/ecommerce-mysql-analysis
-- ============================================================
 
-- ─────────────────────────────────────────────
--  SECTION 0 : DATABASE SETUP
-- ─────────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS ecommerce_db;
USE ecommerce_db;

-- ─────────────────────────────────────────────
--  SECTION 1 : TABLE SCHEMA
-- ─────────────────────────────────────────────

DROP TABLE IF EXISTS sales;

CREATE TABLE sales (
    order_id        INT            NOT NULL,
    customer_id     VARCHAR(10)    NOT NULL,
    customer_name   VARCHAR(100)   NOT NULL,
    customer_email  VARCHAR(150)   NOT NULL,
    customer_city   VARCHAR(80)    NOT NULL,
    customer_state  VARCHAR(80)    NOT NULL,
    customer_segment VARCHAR(50)   NOT NULL,
    order_date      DATE           NOT NULL,
    ship_date       DATE           NOT NULL,
    product_id      VARCHAR(10)    NOT NULL,
    product_name    VARCHAR(150)   NOT NULL,
    category        VARCHAR(60)    NOT NULL,
    sub_category    VARCHAR(60)    NOT NULL,
    quantity        INT            NOT NULL,
    unit_price      DECIMAL(10,2)  NOT NULL,
    discount        DECIMAL(4,2)   NOT NULL DEFAULT 0.00,
    shipping_cost   DECIMAL(8,2)   NOT NULL DEFAULT 0.00,
    payment_mode    VARCHAR(50)    NOT NULL,
    PRIMARY KEY (order_id)
);

-- ─────────────────────────────────────────────
--  SECTION 2 : LOAD DATA FROM CSV
--  Update the file path to match your local path
-- ─────────────────────────────────────────────

SHOW VARIABLES LIKE 'secure_file_priv';

LOAD DATA INFILE 'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/ecommerce_sales_data.csv'
INTO TABLE sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, customer_id, customer_name, customer_email,
 customer_city, customer_state, customer_segment,
 @order_date, @ship_date,
 product_id, product_name, category, sub_category,
 quantity, unit_price, discount, shipping_cost, payment_mode)
SET
    order_date = STR_TO_DATE(@order_date, '%d-%m-%Y'),
    ship_date  = STR_TO_DATE(@ship_date,  '%d-%m-%Y');

-- ─────────────────────────────────────────────
--  SECTION 3 : ADD COMPUTED COLUMNS (VIEWS)
-- ─────────────────────────────────────────────

-- Master enriched view used by most queries below
CREATE OR REPLACE VIEW v_sales AS
SELECT *,
    ROUND(unit_price * quantity * (1 - discount), 2)                    AS revenue,
    ROUND(unit_price * quantity * (1 - discount) - shipping_cost, 2)   AS net_revenue,
    DATEDIFF(ship_date, order_date)                                     AS delivery_days,
    YEAR(order_date)                                                    AS order_year,
    MONTH(order_date)                                                   AS order_month,
    MONTHNAME(order_date)                                               AS month_name,
    QUARTER(order_date)                                                 AS order_quarter
FROM sales;

-- ═══════════════════════════════════════════════════════════════
--  ANALYSIS SECTION — 12 BUSINESS QUESTIONS ANSWERED WITH SQL
-- ═══════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────
--  Q1. Overall Business Summary (KPIs)
-- ─────────────────────────────────────────────
SELECT
    COUNT(DISTINCT order_id)                        AS total_orders,
    COUNT(DISTINCT customer_id)                     AS unique_customers,
    COUNT(DISTINCT product_id)                      AS unique_products,
    SUM(quantity)                                   AS total_units_sold,
    ROUND(SUM(revenue), 2)                          AS total_revenue_INR,
    ROUND(AVG(revenue), 2)                          AS avg_order_value_INR,
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_id), 2) AS revenue_per_customer
FROM v_sales;

-- ─────────────────────────────────────────────
--  Q2. Monthly Revenue Trend (2023)
-- ─────────────────────────────────────────────
SELECT
    order_month,
    month_name,
    COUNT(DISTINCT order_id)            AS orders,
    ROUND(SUM(revenue), 2)              AS monthly_revenue,
    ROUND(SUM(revenue)
        - LAG(SUM(revenue)) OVER (ORDER BY order_month), 2)   AS mom_change,
    ROUND(
        (SUM(revenue) - LAG(SUM(revenue)) OVER (ORDER BY order_month))
        / NULLIF(LAG(SUM(revenue)) OVER (ORDER BY order_month), 0) * 100
    , 2)                                AS mom_growth_pct
FROM v_sales
GROUP BY order_month, month_name
ORDER BY order_month;

-- ─────────────────────────────────────────────
--  Q3. Quarterly Revenue Breakdown
-- ─────────────────────────────────────────────
SELECT
    order_quarter                       AS quarter,
    CONCAT('Q', order_quarter)          AS quarter_label,
    COUNT(DISTINCT order_id)            AS total_orders,
    ROUND(SUM(revenue), 2)              AS quarterly_revenue,
    ROUND(SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 2) AS revenue_share_pct
FROM v_sales
GROUP BY order_quarter
ORDER BY order_quarter;

-- ─────────────────────────────────────────────
--  Q4. Revenue by Product Category
-- ─────────────────────────────────────────────
SELECT
    category,
    COUNT(DISTINCT order_id)            AS total_orders,
    SUM(quantity)                       AS units_sold,
    ROUND(SUM(revenue), 2)              AS total_revenue,
    ROUND(AVG(unit_price), 2)           AS avg_product_price,
    ROUND(AVG(discount) * 100, 2)       AS avg_discount_pct,
    ROUND(SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 2) AS revenue_share_pct,
    RANK() OVER (ORDER BY SUM(revenue) DESC) AS revenue_rank
FROM v_sales
GROUP BY category
ORDER BY total_revenue DESC;

-- ─────────────────────────────────────────────
--  Q5. Top 10 Best-Selling Products by Revenue
-- ─────────────────────────────────────────────
SELECT
    product_id,
    product_name,
    category,
    sub_category,
    COUNT(DISTINCT order_id)            AS times_ordered,
    SUM(quantity)                       AS units_sold,
    ROUND(AVG(unit_price), 2)           AS avg_price,
    ROUND(SUM(revenue), 2)              AS total_revenue
FROM v_sales
GROUP BY product_id, product_name, category, sub_category
ORDER BY total_revenue DESC
LIMIT 10;

-- ─────────────────────────────────────────────
--  Q6. Customer Segment Performance
-- ─────────────────────────────────────────────
SELECT
    customer_segment,
    COUNT(DISTINCT customer_id)         AS customers,
    COUNT(DISTINCT order_id)            AS orders,
    ROUND(SUM(revenue), 2)              AS total_revenue,
    ROUND(AVG(revenue), 2)              AS avg_order_value,
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_id), 2) AS clv_estimate,
    ROUND(SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 2) AS revenue_share_pct
FROM v_sales
GROUP BY customer_segment
ORDER BY total_revenue DESC;

-- ─────────────────────────────────────────────
--  Q7. Top 10 High-Value Customers
-- ─────────────────────────────────────────────
SELECT
    customer_id,
    customer_name,
    customer_city,
    customer_state,
    customer_segment,
    COUNT(DISTINCT order_id)            AS total_orders,
    SUM(quantity)                       AS items_purchased,
    ROUND(SUM(revenue), 2)              AS lifetime_revenue,
    ROUND(AVG(revenue), 2)              AS avg_order_value,
    MIN(order_date)                     AS first_purchase,
    MAX(order_date)                     AS last_purchase,
    DATEDIFF(MAX(order_date), MIN(order_date)) AS customer_lifespan_days
FROM v_sales
GROUP BY customer_id, customer_name, customer_city, customer_state, customer_segment
ORDER BY lifetime_revenue DESC
LIMIT 10;

-- ─────────────────────────────────────────────
--  Q8. State-wise Revenue (Geographic Analysis)
-- ─────────────────────────────────────────────
SELECT
    customer_state,
    COUNT(DISTINCT customer_id)         AS customers,
    COUNT(DISTINCT order_id)            AS orders,
    ROUND(SUM(revenue), 2)              AS total_revenue,
    ROUND(AVG(revenue), 2)              AS avg_order_value,
    DENSE_RANK() OVER (ORDER BY SUM(revenue) DESC) AS state_rank
FROM v_sales
GROUP BY customer_state
ORDER BY total_revenue DESC;

-- ─────────────────────────────────────────────
--  Q9. Payment Mode Analysis
-- ─────────────────────────────────────────────
SELECT
    payment_mode,
    COUNT(DISTINCT order_id)            AS total_orders,
    ROUND(SUM(revenue), 2)              AS total_revenue,
    ROUND(AVG(revenue), 2)              AS avg_order_value,
    ROUND(COUNT(DISTINCT order_id) * 100.0 / SUM(COUNT(DISTINCT order_id)) OVER (), 2) AS order_share_pct
FROM v_sales
GROUP BY payment_mode
ORDER BY total_orders DESC;

-- ─────────────────────────────────────────────
--  Q10. Delivery Performance Analysis
-- ─────────────────────────────────────────────
SELECT
    CASE
        WHEN delivery_days <= 3  THEN '1-3 days (Fast)'
        WHEN delivery_days <= 5  THEN '4-5 days (Standard)'
        WHEN delivery_days <= 7  THEN '6-7 days (Slow)'
        ELSE '8+ days (Very Slow)'
    END                                             AS delivery_bucket,
    COUNT(DISTINCT order_id)                        AS orders,
    ROUND(AVG(delivery_days), 1)                    AS avg_delivery_days,
    ROUND(SUM(revenue), 2)                          AS revenue,
    ROUND(AVG(shipping_cost), 2)                    AS avg_shipping_cost
FROM v_sales
GROUP BY delivery_bucket
ORDER BY avg_delivery_days;

-- ─────────────────────────────────────────────
--  Q11. Discount Impact Analysis
-- ─────────────────────────────────────────────
SELECT
    CASE
        WHEN discount = 0           THEN 'No Discount'
        WHEN discount <= 0.05       THEN '1–5%'
        WHEN discount <= 0.10       THEN '6–10%'
        ELSE '11%+'
    END                                             AS discount_band,
    COUNT(DISTINCT order_id)                        AS orders,
    SUM(quantity)                                   AS units_sold,
    ROUND(SUM(unit_price * quantity), 2)            AS gross_revenue,
    ROUND(SUM(revenue), 2)                          AS net_revenue_after_discount,
    ROUND(SUM(unit_price * quantity) - SUM(revenue), 2) AS discount_amount_lost
FROM v_sales
GROUP BY discount_band
ORDER BY discount_band;

-- ─────────────────────────────────────────────
--  Q12. RFM Customer Segmentation
--  Recency · Frequency · Monetary
-- ─────────────────────────────────────────────
WITH rfm_base AS (
    SELECT
        customer_id,
        customer_name,
        customer_segment,
        DATEDIFF('2023-12-31', MAX(order_date))     AS recency_days,
        COUNT(DISTINCT order_id)                    AS frequency,
        ROUND(SUM(revenue), 2)                      AS monetary
    FROM v_sales
    GROUP BY customer_id, customer_name, customer_segment
),
rfm_scored AS (
    SELECT *,
        NTILE(5) OVER (ORDER BY recency_days ASC)   AS r_score,   -- lower recency = better
        NTILE(5) OVER (ORDER BY frequency DESC)     AS f_score,
        NTILE(5) OVER (ORDER BY monetary DESC)      AS m_score
    FROM rfm_base
),
rfm_final AS (
    SELECT *,
        ROUND((r_score + f_score + m_score) / 3.0, 2) AS rfm_avg,
        CASE
            WHEN (r_score + f_score + m_score) >= 13 THEN 'Champions'
            WHEN (r_score + f_score + m_score) >= 10 THEN 'Loyal Customers'
            WHEN (r_score + f_score + m_score) >= 7  THEN 'Potential Loyalists'
            WHEN (r_score + f_score + m_score) >= 4  THEN 'At Risk'
            ELSE 'Lost Customers'
        END AS rfm_segment
    FROM rfm_scored
)
SELECT
    customer_id,
    customer_name,
    customer_segment,
    recency_days,
    frequency,
    monetary,
    r_score, f_score, m_score,
    rfm_avg,
    rfm_segment
FROM rfm_final
ORDER BY rfm_avg DESC;

-- ─────────────────────────────────────────────
--  BONUS: Sub-category Deep-Dive
-- ─────────────────────────────────────────────
SELECT
    category,
    sub_category,
    COUNT(DISTINCT order_id)            AS orders,
    SUM(quantity)                       AS units_sold,
    ROUND(SUM(revenue), 2)              AS revenue,
    ROUND(AVG(discount) * 100, 2)       AS avg_discount_pct,
    ROUND(SUM(revenue) * 100.0
        / SUM(SUM(revenue)) OVER (PARTITION BY category), 2) AS pct_of_category
FROM v_sales
GROUP BY category, sub_category
ORDER BY category, revenue DESC;

-- ─────────────────────────────────────────────
--  END OF SCRIPT
-- ─────────────────────────────────────────────
