-- 01_exploration.sql
-- Goal: Understand data structure, relationships, and data quality

-- ========================
-- 1. Dataset Overview
-- ========================

SELECT COUNT(*) AS total_orders
FROM read_csv_auto('data/raw/olist_orders_dataset.csv');

SELECT order_status, COUNT(*) AS num_orders
FROM read_csv_auto('data/raw/olist_orders_dataset.csv')
GROUP BY order_status;

-- ========================
-- 2. Primary Key Checks
-- ========================

-- Orders: should be unique
SELECT order_id, COUNT(*) AS cnt
FROM read_csv_auto('data/raw/olist_orders_dataset.csv')
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Order Items: composite key
SELECT order_id, order_item_id, COUNT(*) AS cnt
FROM read_csv_auto('data/raw/olist_order_items_dataset.csv')
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- ========================
-- 3. Relationship Checks
-- ========================

-- Missing Orders
SELECT COUNT(*) AS missing_orders
FROM read_csv_auto('data/raw/olist_order_items_dataset.csv') oi
LEFT JOIN read_csv_auto('data/raw/olist_orders_dataset.csv') o
ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- ========================
-- 4. Data Quality Checks
-- ========================

-- Delivered without delivery date
SELECT COUNT(*)
FROM read_csv_auto('data/raw/olist_orders_dataset.csv')
WHERE order_status = 'delivered'
AND order_delivered_customer_date IS NULL;

-- ========================
-- 5. Time Range
-- ========================

SELECT 
  MIN(order_purchase_timestamp) AS min_date,
  MAX(order_purchase_timestamp) AS max_date
FROM read_csv_auto('data/raw/olist_orders_dataset.csv');