-- 02_core_metrics.sql
-- Purpose:
-- Calculate core business KPIs using the staging layer.
-- Focus: foundational metrics without advanced window functions or segmentation.

-- ========================
-- 1. Monthly GMV and Delivered Orders
-- ========================

SELECT 
  CAST(DATE_TRUNC('month', o.delivered_at) AS DATE) AS month_date,
  SUM(oi.price + oi.freight_value) AS gmv,
  COUNT(DISTINCT o.order_id) AS delivered_orders
FROM stg_order_items oi
JOIN stg_orders o
  ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.delivered_at IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- ========================
-- 2. Average Order Value (AOV)
-- ========================

SELECT 
  CAST(DATE_TRUNC('month', o.delivered_at) AS DATE) AS month_date,
  SUM(oi.price + oi.freight_value) * 1.0 / COUNT(DISTINCT o.order_id) AS aov
FROM stg_order_items oi
JOIN stg_orders o
  ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.delivered_at IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- ========================
-- 3. Items per Order (IPO)
-- ========================

SELECT
  CAST(DATE_TRUNC('month', o.delivered_at) AS DATE) AS month_date,
  COUNT(oi.order_item_id) * 1.0 / COUNT(DISTINCT o.order_id) AS items_per_order
FROM stg_order_items oi
JOIN stg_orders o
  ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
  AND o.delivered_at IS NOT NULL
GROUP BY 1
ORDER BY 1;

-- ========================
-- 4. Seller GMV Overview
-- ========================

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
GROUP BY oi.seller_id
ORDER BY total_gmv DESC;