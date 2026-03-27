-- 03_advanced_analysis.sql
-- Purpose:
-- Perform advanced analytical queries using window functions,
-- bucketing logic, and customer-level aggregation.

-- ========================
-- 1. Month-over-Month GMV Growth
-- ========================

WITH monthly_gmv AS (
  SELECT
    CAST(DATE_TRUNC('month', o.delivered_at) AS DATE) AS month_date,
    SUM(oi.price + oi.freight_value) AS gmv
  FROM stg_order_items oi
  JOIN stg_orders o
    ON o.order_id = oi.order_id
  WHERE o.order_status = 'delivered'
    AND o.delivered_at IS NOT NULL
  GROUP BY 1
),

gmv_with_prev AS (
  SELECT
    month_date,
    gmv,
    LAG(gmv) OVER (ORDER BY month_date) AS prev_gmv
  FROM monthly_gmv
)

SELECT
  month_date,
  gmv,
  prev_gmv,
  gmv - prev_gmv AS mom_change,
  CASE
    WHEN prev_gmv IS NOT NULL AND prev_gmv <> 0
    THEN ROUND((gmv - prev_gmv) / prev_gmv * 100, 2)
    ELSE NULL
  END AS mom_growth_pct
FROM gmv_with_prev
ORDER BY month_date;

-- ========================
-- 2. Seller Pareto Analysis
-- ========================

WITH seller_gmv AS (
  SELECT 
    oi.seller_id,
    SUM(oi.price + oi.freight_value) AS total_gmv
  FROM stg_order_items oi
  JOIN stg_orders o
    ON o.order_id = oi.order_id
  WHERE o.order_status = 'delivered'
    AND o.delivered_at IS NOT NULL
  GROUP BY oi.seller_id
),

ranked_sellers AS (
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
FROM ranked_sellers
ORDER BY seller_rank;

-- ========================
-- 3. Review Score by Delivery Time
-- ========================

WITH ranked_reviews AS (
  SELECT
    order_id,
    review_score,
    ROW_NUMBER() OVER (
      PARTITION BY order_id
      ORDER BY review_created_at DESC
    ) AS review_recency_rank
  FROM stg_order_reviews
),

delivery_time AS (
  SELECT 
    order_id,
    DATE_DIFF('day', purchased_at, delivered_at) AS delivery_days
  FROM stg_orders
  WHERE order_status = 'delivered'
    AND purchased_at IS NOT NULL
    AND delivered_at IS NOT NULL
),

delivery_buckets AS (
  SELECT
    order_id,
    CASE
      WHEN delivery_days <= 3 THEN '0-3 days'
      WHEN delivery_days <= 7 THEN '4-7 days'
      WHEN delivery_days <= 14 THEN '8-14 days'
      ELSE '15+ days'
    END AS delivery_bucket,
    CASE
      WHEN delivery_days <= 3 THEN 1
      WHEN delivery_days <= 7 THEN 2
      WHEN delivery_days <= 14 THEN 3
      ELSE 4
    END AS bucket_order
  FROM delivery_time
)

SELECT
  b.bucket_order,
  b.delivery_bucket,
  AVG(r.review_score) AS avg_review_score,
  COUNT(*) AS num_orders
FROM ranked_reviews r
JOIN delivery_buckets b
  ON r.order_id = b.order_id
WHERE r.review_recency_rank = 1
GROUP BY b.bucket_order, b.delivery_bucket
ORDER BY b.bucket_order;

-- ========================
-- 4. Customer Retention
-- ========================

WITH delivered_orders AS (
  SELECT 
    o.order_id,
    c.customer_unique_id
  FROM stg_orders o
  JOIN stg_customers c
    ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
    AND o.delivered_at IS NOT NULL
),

customer_orders AS (
  SELECT 
    customer_unique_id,
    COUNT(*) AS num_orders
  FROM delivered_orders
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