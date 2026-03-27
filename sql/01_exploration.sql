-- 01_exploration.sql
-- Purpose:
-- Explore the raw dataset structure, validate key assumptions,
-- and perform initial quality checks before building metrics.

-- ========================
-- 1. Dataset Overview
-- ========================

-- Total number of orders
SELECT 
  COUNT(*) AS total_orders
FROM read_csv_auto('data/raw/olist_orders_dataset.csv');

-- Distribution of order status
SELECT 
  order_status,
  COUNT(*) AS num_orders
FROM read_csv_auto('data/raw/olist_orders_dataset.csv')
GROUP BY order_status
ORDER BY num_orders DESC;

-- ========================
-- 2. Primary Key Checks
-- ========================

-- Orders: order_id should be unique
SELECT 
  order_id,
  COUNT(*) AS cnt
FROM read_csv_auto('data/raw/olist_orders_dataset.csv')
GROUP BY order_id
HAVING COUNT(*) > 1;

-- Order Items: composite key (order_id, order_item_id) should be unique
SELECT 
  order_id,
  order_item_id,
  COUNT(*) AS cnt
FROM read_csv_auto('data/raw/olist_order_items_dataset.csv')
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;

-- ========================
-- 3. Relationship Checks
-- ========================

-- Order items without a matching order
SELECT 
  COUNT(*) AS missing_orders
FROM read_csv_auto('data/raw/olist_order_items_dataset.csv') oi
LEFT JOIN read_csv_auto('data/raw/olist_orders_dataset.csv') o
  ON oi.order_id = o.order_id
WHERE o.order_id IS NULL;

-- ========================
-- 4. Data Quality Checks
-- ========================

-- Delivered orders without a delivery timestamp
SELECT 
  COUNT(*) AS delivered_without_delivery_date
FROM read_csv_auto('data/raw/olist_orders_dataset.csv')
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NULL;

-- ========================
-- 5. Time Coverage
-- ========================

-- Purchase timestamp range covered by the dataset
SELECT 
  MIN(order_purchase_timestamp) AS min_date,
  MAX(order_purchase_timestamp) AS max_date
FROM read_csv_auto('data/raw/olist_orders_dataset.csv');