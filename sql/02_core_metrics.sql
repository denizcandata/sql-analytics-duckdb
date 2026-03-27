SELECT * FROM stg_orders LIMIT 5;
SELECT * FROM stg_order_items LIMIT 5;

-- GMV (delivered_month), AOV (delivered_month)
SELECT 
  CAST(DATE_TRUNC('month', o.delivered_at) AS DATE) AS month_date,
  SUM(oi.price + oi.freight_value) AS gmv,
  COUNT(DISTINCT o.order_id) AS delivered_orders,
  SUM(oi.price + oi.freight_value) * 1.0 / COUNT(DISTINCT o.order_id) AS aov
FROM stg_order_items oi
JOIN stg_orders o
  ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.delivered_at IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- Items per Order (IPO)
SELECT
  CAST(DATE_TRUNC('month', o.delivered_at) AS DATE) AS month_date,
  COUNT(DISTINCT o.order_id) AS delivered_orders,
  COUNT(oi.order_item_id) AS total_items,
  ROUND(COUNT(oi.order_item_id) * 1.0 / COUNT(DISTINCT o.order_id), 2) AS items_per_order
FROM stg_order_items oi
JOIN stg_orders o
  ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.delivered_at IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- Top Seller nach Umsatz analysieren
SELECT 
  oi.seller_id,
  SUM(oi.price + oi.freight_value) AS total_gmv,
  COUNT(DISTINCT o.order_id) AS total_orders,
  SUM(oi.price + oi.freight_value) * 1.0 / COUNT(DISTINCT o.order_id) AS avg_order_value
FROM stg_order_items oi
JOIN stg_orders o
  ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.delivered_at IS NOT NULL
GROUP BY oi.seller_id;

-- Seller Pareto (GMV Contribution)
WITH 
  seller_gmv AS (
  SELECT 
    seller_id,
    SUM(oi.price + oi.freight_value) AS total_gmv,
    COUNT(DISTINCT o.order_id) AS total_orders,
    SUM(oi.price + oi.freight_value) * 1.0 / COUNT(DISTINCT o.order_id) AS avg_order_value
  FROM stg_order_items oi
  JOIN stg_orders o
    ON o.order_id = oi.order_id
  WHERE o.order_status = 'delivered'
    AND o.delivered_at IS NOT NULL
  GROUP BY oi.seller_id
  ),

  seller_ranked AS (
  SELECT
    seller_id,
    total_gmv,
    total_orders,
    avg_order_value,
    RANK() OVER (ORDER BY total_gmv DESC) AS seller_rank,
    SUM(total_gmv) OVER (ORDER BY total_gmv DESC) AS cumulative_gmv,
    SUM(total_gmv) OVER () AS total_gmv_all_sellers
  FROM seller_gmv
  ),

  seller_with_pct AS (
  SELECT
    seller_id,
    total_gmv,
    total_orders,
    avg_order_value,
    seller_rank,
    cumulative_gmv,
    total_gmv_all_sellers,
    ROUND(cumulative_gmv * 100.0 / total_gmv_all_sellers, 2) AS cumulative_gmv_percentage
  FROM seller_ranked
  )

SELECT 
  seller_id,
  total_gmv,
  total_orders,
  avg_order_value,
  seller_rank,
  cumulative_gmv,
  cumulative_gmv_percentage,
  CASE
    WHEN cumulative_gmv_percentage <= 10 THEN 'Top 10% of GMV sellers'
    WHEN cumulative_gmv_percentage <= 20 THEN 'Top 20% of GMV sellers'
    ELSE 'Other Sellers'
  END AS seller_category
FROM seller_with_pct
ORDER BY seller_rank;

-- Top 50% of GMV sellers analyzing

WITH 
  seller_gmv AS (
  SELECT 
    seller_id,
    SUM(oi.price + oi.freight_value) AS total_gmv
  FROM stg_order_items oi
  JOIN stg_orders o
    ON o.order_id = oi.order_id
  WHERE o.order_status = 'delivered'
    AND o.delivered_at IS NOT NULL
  GROUP BY oi.seller_id
  ),

  seller_ranked AS (
  SELECT
    seller_id,
    total_gmv,
    RANK() OVER (ORDER BY total_gmv DESC) AS seller_rank,
    SUM(total_gmv) OVER (ORDER BY total_gmv DESC) AS cumulative_gmv,
    SUM(total_gmv) OVER () AS total_gmv_all_sellers
  FROM seller_gmv
  ),

  seller_with_pct AS (
  SELECT
    seller_id,
    total_gmv,
    seller_rank,
    cumulative_gmv,
    total_gmv_all_sellers,
    ROUND(cumulative_gmv * 100.0 / total_gmv_all_sellers, 2) AS cumulative_gmv_percentage
  FROM seller_ranked
  )

SELECT 
  MIN(seller_rank) AS sellers_needed_for_50pct_gmv
FROM seller_with_pct
WHERE cumulative_gmv_percentage >= 50;