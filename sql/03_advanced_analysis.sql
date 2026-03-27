-- 03_advanced_analysis.sql
-- Goal: Advanced insights using window functions & segmentation

-- ========================
-- 1. MoM GMV Growth
-- ========================

WITH monthly_gmv AS (
  SELECT
    CAST(DATE_TRUNC('month', o.delivered_at) AS DATE) AS date_month,
    SUM(oi.price + oi.freight_value) AS gmv
  FROM stg_order_items oi
  JOIN stg_orders o
    ON o.order_id = oi.order_id
  WHERE o.order_status = 'delivered'
    AND o.delivered_at IS NOT NULL
  GROUP BY 1
)

SELECT
  date_month,
  gmv,
  LAG(gmv) OVER (ORDER BY date_month) AS prev_gmv,
  gmv - LAG(gmv) OVER (ORDER BY date_month) AS mom_change,
  ROUND(
    (gmv - LAG(gmv) OVER (ORDER BY date_month)) 
    / LAG(gmv) OVER (ORDER BY date_month) * 100, 
    2
  ) AS mom_growth_pct
FROM monthly_gmv
ORDER BY date_month;

-- ========================
-- 2. Seller Pareto Analysis
-- ========================

WITH seller_gmv AS (
  SELECT 
    seller_id,
    SUM(oi.price + oi.freight_value) AS total_gmv
  FROM stg_order_items oi
  JOIN stg_orders o
    ON o.order_id = oi.order_id
  WHERE o.order_status = 'delivered'
    AND o.delivered_at IS NOT NULL
  GROUP BY seller_id
),

ranked AS (
  SELECT
    seller_id,
    total_gmv,
    RANK() OVER (ORDER BY total_gmv DESC) AS seller_rank,
    SUM(total_gmv) OVER (ORDER BY total_gmv DESC) AS cumulative_gmv,
    SUM(total_gmv) OVER () AS total_gmv_all
  FROM seller_gmv
)

SELECT
  seller_id,
  seller_rank,
  total_gmv,
  ROUND(cumulative_gmv * 100.0 / total_gmv_all, 2) AS cumulative_gmv_pct
FROM ranked
ORDER BY seller_rank;

-- ========================
-- 3. Review Score vs Delivery Time
-- ========================

WITH ranked_reviews AS (
  SELECT
    order_id,
    review_score,
    ROW_NUMBER() OVER (
      PARTITION BY order_id
      ORDER BY review_created_at DESC
    ) AS rn
  FROM stg_order_reviews
),

delivery_time AS (
  SELECT 
    order_id,
    DATE_DIFF('day', purchased_at, delivered_at) AS delivery_days
  FROM stg_orders
  WHERE order_status = 'delivered'
),

bucketed AS (
  SELECT
    order_id,
    CASE
      WHEN delivery_days <= 3 THEN '0-3 days'
      WHEN delivery_days <= 7 THEN '4-7 days'
      WHEN delivery_days <= 14 THEN '8-14 days'
      ELSE '15+ days'
    END AS delivery_bucket
  FROM delivery_time
)

SELECT
  delivery_bucket,
  AVG(review_score) AS avg_review_score,
  COUNT(*) AS num_orders
FROM ranked_reviews r
JOIN bucketed b ON r.order_id = b.order_id
WHERE rn = 1
GROUP BY delivery_bucket;

-- ========================
-- 4. Customer Retention
-- ========================

WITH orders AS (
  SELECT 
    o.order_id,
    c.customer_unique_id
  FROM stg_orders o
  JOIN stg_customers c
    ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
),

customer_orders AS (
  SELECT 
    customer_unique_id,
    COUNT(*) AS num_orders
  FROM orders
  GROUP BY customer_unique_id
)

SELECT 
  SUM(CASE WHEN num_orders = 1 THEN 1 ELSE 0 END) AS single_order_customers,
  SUM(CASE WHEN num_orders >= 2 THEN 1 ELSE 0 END) AS repeat_customers,
  COUNT(*) AS total_customers,
  ROUND(
    SUM(CASE WHEN num_orders >= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 
    2
  ) AS repeat_customer_rate
FROM customer_orders;