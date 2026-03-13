/* ============================================================
   SALES ADVANCED ANALYTICS — SQL ANALYSIS QUERIES
   Database: SQLite / PostgreSQL / MySQL compatible*
   Dataset : cleaned_sales_data.csv  (loaded as table: sales)
   Author  : Data Analytics Portfolio Project
   
   * Minor syntax differences may apply between dialects.
     Window functions require SQLite ≥ 3.25, MySQL ≥ 8.0,
     or any version of PostgreSQL.
   ============================================================ */


-- ============================================================
-- 0. TABLE STRUCTURE REFERENCE
-- ============================================================
/*
   order_id        TEXT          Unique order identifier
   order_date      DATE          Date of purchase
   ship_date       DATE          Date of shipment
   customer_id     TEXT          Unique customer ID
   customer_name   TEXT          Full name
   region          TEXT          Sales region
   category        TEXT          Product category
   product_name    TEXT          Product name
   quantity        INTEGER       Units ordered
   unit_price      REAL          Price per unit (post-discount)
   unit_cost       REAL          Cost per unit
   discount        REAL          Discount rate 0–0.5
   revenue         REAL          = unit_price * quantity * (1 - discount)
   total_cost      REAL          = unit_cost * quantity
   profit          REAL          = revenue - total_cost
   profit_margin   REAL          = profit / revenue * 100
   year            INTEGER
   quarter         TEXT          Q1 / Q2 / Q3 / Q4
   month           INTEGER       1–12
   month_name      TEXT          Jan / Feb / ...
   month_year      TEXT          YYYY-MM
   customer_segment TEXT         RFM segment label
*/


-- ============================================================
-- 1. EXECUTIVE KPI OVERVIEW
-- ============================================================
SELECT
    COUNT(DISTINCT order_id)                    AS total_orders,
    COUNT(DISTINCT customer_id)                 AS unique_customers,
    ROUND(SUM(revenue),       2)                AS total_revenue,
    ROUND(SUM(profit),        2)                AS total_profit,
    ROUND(SUM(profit) * 100.0 / SUM(revenue), 2) AS overall_margin_pct,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    ROUND(SUM(revenue) / COUNT(DISTINCT customer_id), 2) AS avg_customer_value,
    MIN(order_date)                             AS first_order_date,
    MAX(order_date)                             AS last_order_date
FROM sales;


-- ============================================================
-- 2. REVENUE & PROFIT BY YEAR AND QUARTER
-- ============================================================
SELECT
    year,
    quarter,
    COUNT(DISTINCT order_id)                    AS total_orders,
    COUNT(DISTINCT customer_id)                 AS active_customers,
    ROUND(SUM(revenue),       2)                AS total_revenue,
    ROUND(SUM(total_cost),    2)                AS total_cost,
    ROUND(SUM(profit),        2)                AS total_profit,
    ROUND(AVG(profit_margin), 2)                AS avg_margin_pct,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2) AS avg_order_value
FROM sales
GROUP BY year, quarter
ORDER BY year, quarter;


-- ============================================================
-- 3. MONTHLY REVENUE TREND WITH MONTH-OVER-MONTH GROWTH
-- ============================================================
WITH monthly AS (
    SELECT
        month_year,
        year,
        month,
        ROUND(SUM(revenue),  2)                 AS monthly_revenue,
        ROUND(SUM(profit),   2)                 AS monthly_profit,
        COUNT(DISTINCT order_id)                AS order_count,
        COUNT(DISTINCT customer_id)             AS active_customers,
        ROUND(AVG(profit_margin), 2)            AS avg_margin
    FROM sales
    GROUP BY month_year, year, month
)
SELECT
    *,
    ROUND(
        monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY year, month), 2
    ) AS mom_revenue_change,
    ROUND(
        (monthly_revenue - LAG(monthly_revenue) OVER (ORDER BY year, month))
        * 100.0
        / NULLIF(LAG(monthly_revenue) OVER (ORDER BY year, month), 0), 2
    ) AS mom_growth_pct
FROM monthly
ORDER BY year, month;


-- ============================================================
-- 4. REGIONAL SALES PERFORMANCE
-- ============================================================
SELECT
    region,
    COUNT(DISTINCT order_id)                    AS total_orders,
    COUNT(DISTINCT customer_id)                 AS unique_customers,
    ROUND(SUM(revenue),       2)                AS total_revenue,
    ROUND(SUM(profit),        2)                AS total_profit,
    ROUND(AVG(profit_margin), 2)                AS avg_margin_pct,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    ROUND(
        SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 2
    )                                           AS revenue_share_pct
FROM sales
GROUP BY region
ORDER BY total_revenue DESC;


-- ============================================================
-- 5. PRODUCT-LEVEL PERFORMANCE ANALYSIS
-- ============================================================
SELECT
    product_name,
    category,
    COUNT(DISTINCT order_id)                    AS total_orders,
    SUM(quantity)                               AS units_sold,
    ROUND(SUM(revenue),       2)                AS total_revenue,
    ROUND(SUM(profit),        2)                AS total_profit,
    ROUND(AVG(profit_margin), 2)                AS avg_margin_pct,
    ROUND(AVG(unit_price),    2)                AS avg_unit_price,
    ROUND(
        SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 2
    )                                           AS revenue_pct_of_total
FROM sales
GROUP BY product_name, category
ORDER BY total_revenue DESC;


-- ============================================================
-- 6. TOP 10 PRODUCTS — WINDOW FUNCTION RANKING
-- ============================================================
WITH product_ranked AS (
    SELECT
        product_name,
        category,
        ROUND(SUM(revenue),       2)            AS total_revenue,
        ROUND(SUM(profit),        2)            AS total_profit,
        ROUND(AVG(profit_margin), 2)            AS avg_margin_pct,
        SUM(quantity)                           AS units_sold,
        RANK() OVER (ORDER BY SUM(revenue) DESC)  AS revenue_rank,
        RANK() OVER (ORDER BY SUM(profit)  DESC)  AS profit_rank,
        RANK() OVER (ORDER BY SUM(quantity) DESC) AS volume_rank
    FROM sales
    GROUP BY product_name, category
)
SELECT *
FROM   product_ranked
WHERE  revenue_rank <= 10
ORDER  BY revenue_rank;


-- ============================================================
-- 7. CATEGORY PROFITABILITY ANALYSIS
-- ============================================================
SELECT
    category,
    COUNT(DISTINCT product_name)               AS num_products,
    COUNT(DISTINCT order_id)                   AS total_orders,
    SUM(quantity)                              AS units_sold,
    ROUND(SUM(revenue),       2)               AS total_revenue,
    ROUND(SUM(profit),        2)               AS total_profit,
    ROUND(AVG(profit_margin), 2)               AS avg_margin_pct,
    CASE
        WHEN AVG(profit_margin) >= 40 THEN 'High Margin'
        WHEN AVG(profit_margin) >= 20 THEN 'Medium Margin'
        WHEN AVG(profit_margin) >= 0  THEN 'Low Margin'
        ELSE                               'Loss Making'
    END                                        AS margin_tier,
    ROUND(
        SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 2
    )                                          AS revenue_share_pct
FROM sales
GROUP BY category
ORDER BY total_profit DESC;


-- ============================================================
-- 8. CUSTOMER PURCHASE FREQUENCY & LIFETIME VALUE
-- ============================================================
SELECT
    customer_id,
    customer_name,
    customer_segment,
    COUNT(DISTINCT order_id)                   AS total_orders,
    ROUND(SUM(revenue),                 2)     AS lifetime_value,
    ROUND(AVG(revenue),                 2)     AS avg_order_value,
    ROUND(SUM(profit),                  2)     AS total_profit,
    MIN(DATE(order_date))                      AS first_purchase_date,
    MAX(DATE(order_date))                      AS last_purchase_date,
    ROUND(
        JULIANDAY(MAX(order_date)) - JULIANDAY(MIN(order_date))
    )                                          AS customer_lifespan_days
FROM sales
GROUP BY customer_id, customer_name, customer_segment
ORDER BY lifetime_value DESC;


-- ============================================================
-- 9. TOP 10 CUSTOMERS BY LIFETIME VALUE (WINDOW RANKS)
-- ============================================================
WITH customer_metrics AS (
    SELECT
        customer_id,
        customer_name,
        customer_segment,
        COUNT(DISTINCT order_id)               AS total_orders,
        ROUND(SUM(revenue), 2)                 AS lifetime_value,
        ROUND(SUM(profit),  2)                 AS total_profit,
        RANK() OVER (ORDER BY SUM(revenue) DESC) AS ltv_rank,
        NTILE(4) OVER (ORDER BY SUM(revenue) DESC) AS ltv_quartile
    FROM sales
    GROUP BY customer_id, customer_name, customer_segment
)
SELECT *
FROM   customer_metrics
WHERE  ltv_rank <= 10
ORDER  BY ltv_rank;


-- ============================================================
-- 10. CUSTOMER SEGMENT PERFORMANCE SUMMARY
-- ============================================================
SELECT
    customer_segment,
    COUNT(DISTINCT customer_id)                AS customer_count,
    COUNT(DISTINCT order_id)                   AS total_orders,
    ROUND(SUM(revenue),       2)               AS total_revenue,
    ROUND(AVG(revenue),       2)               AS avg_order_revenue,
    ROUND(SUM(profit),        2)               AS total_profit,
    ROUND(AVG(profit_margin), 2)               AS avg_margin_pct,
    ROUND(
        SUM(revenue) * 100.0 / SUM(SUM(revenue)) OVER (), 2
    )                                          AS revenue_share_pct
FROM sales
GROUP BY customer_segment
ORDER BY total_revenue DESC;


-- ============================================================
-- 11. REGIONAL PERFORMANCE BY CATEGORY (CROSS-ANALYSIS)
-- ============================================================
SELECT
    region,
    category,
    COUNT(DISTINCT order_id)                   AS total_orders,
    ROUND(SUM(revenue), 2)                     AS total_revenue,
    ROUND(SUM(profit),  2)                     AS total_profit,
    ROUND(AVG(profit_margin), 2)               AS avg_margin_pct,
    RANK() OVER (
        PARTITION BY region ORDER BY SUM(revenue) DESC
    )                                          AS rank_within_region
FROM sales
GROUP BY region, category
ORDER BY region, rank_within_region;


-- ============================================================
-- 12. YEAR-OVER-YEAR GROWTH ANALYSIS
-- ============================================================
WITH yearly AS (
    SELECT
        year,
        ROUND(SUM(revenue), 2)                 AS annual_revenue,
        ROUND(SUM(profit),  2)                 AS annual_profit,
        COUNT(DISTINCT order_id)               AS total_orders,
        COUNT(DISTINCT customer_id)            AS unique_customers
    FROM sales
    GROUP BY year
)
SELECT
    year,
    annual_revenue,
    annual_profit,
    total_orders,
    unique_customers,
    ROUND(
        (annual_revenue - LAG(annual_revenue) OVER (ORDER BY year))
        * 100.0
        / NULLIF(LAG(annual_revenue) OVER (ORDER BY year), 0), 2
    ) AS yoy_revenue_growth_pct,
    ROUND(
        (annual_profit - LAG(annual_profit) OVER (ORDER BY year))
        * 100.0
        / NULLIF(LAG(annual_profit) OVER (ORDER BY year), 0), 2
    ) AS yoy_profit_growth_pct
FROM yearly
ORDER BY year;


-- ============================================================
-- 13. SALES SEASONALITY — DAY-OF-WEEK ANALYSIS
-- ============================================================
SELECT
    day_of_week,
    COUNT(DISTINCT order_id)                   AS total_orders,
    ROUND(SUM(revenue) / COUNT(DISTINCT order_id), 2) AS avg_order_value,
    ROUND(SUM(revenue), 2)                     AS total_revenue,
    ROUND(AVG(profit_margin), 2)               AS avg_margin_pct
FROM sales
GROUP BY day_of_week
ORDER BY
    CASE day_of_week
        WHEN 'Monday'    THEN 1 WHEN 'Tuesday'   THEN 2
        WHEN 'Wednesday' THEN 3 WHEN 'Thursday'  THEN 4
        WHEN 'Friday'    THEN 5 WHEN 'Saturday'  THEN 6
        WHEN 'Sunday'    THEN 7
    END;


-- ============================================================
-- 14. SHIPPING PERFORMANCE ANALYSIS
-- ============================================================
SELECT
    region,
    ROUND(AVG(days_to_ship), 1)                AS avg_days_to_ship,
    MIN(days_to_ship)                          AS min_days,
    MAX(days_to_ship)                          AS max_days,
    COUNT(CASE WHEN days_to_ship <= 2 THEN 1 END) AS same_2day_orders,
    COUNT(CASE WHEN days_to_ship >  5 THEN 1 END) AS slow_ship_orders,
    COUNT(*)                                   AS total_orders
FROM sales
GROUP BY region
ORDER BY avg_days_to_ship;


-- ============================================================
-- 15. DISCOUNT IMPACT ON REVENUE AND MARGIN
-- ============================================================
SELECT
    CASE
        WHEN discount = 0          THEN 'No Discount'
        WHEN discount <= 0.05      THEN '1–5%'
        WHEN discount <= 0.10      THEN '6–10%'
        WHEN discount <= 0.20      THEN '11–20%'
        ELSE                            '21–50%'
    END                                        AS discount_band,
    COUNT(DISTINCT order_id)                   AS order_count,
    ROUND(AVG(revenue),       2)               AS avg_order_revenue,
    ROUND(AVG(profit_margin), 2)               AS avg_margin_pct,
    ROUND(SUM(revenue),       2)               AS total_revenue,
    ROUND(SUM(profit),        2)               AS total_profit
FROM sales
GROUP BY discount_band
ORDER BY MIN(discount);
