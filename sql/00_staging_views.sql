-- 00_staging_views.sql
-- Purpose:
-- Create a minimal staging layer on top of the raw CSV files.
-- This layer standardizes data types, column naming, and basic readability.
-- No business filters are applied at this stage.

-- ========================
-- Orders
-- ========================

CREATE OR REPLACE VIEW stg_orders AS
SELECT
  order_id,
  customer_id,
  order_status,
  TRY_CAST(order_purchase_timestamp AS TIMESTAMP) AS purchased_at,
  TRY_CAST(order_delivered_customer_date AS TIMESTAMP) AS delivered_at,
  TRY_CAST(order_estimated_delivery_date AS TIMESTAMP) AS estimated_delivery_at
FROM read_csv_auto('data/raw/olist_orders_dataset.csv');

-- ========================
-- Order Items
-- ========================

CREATE OR REPLACE VIEW stg_order_items AS
SELECT
  order_id,
  order_item_id,
  product_id,
  seller_id,
  TRY_CAST(shipping_limit_date AS TIMESTAMP) AS shipping_limit_at,
  TRY_CAST(price AS DOUBLE) AS price,
  TRY_CAST(freight_value AS DOUBLE) AS freight_value
FROM read_csv_auto('data/raw/olist_order_items_dataset.csv');

-- ========================
-- Order Reviews
-- ========================

CREATE OR REPLACE VIEW stg_order_reviews AS
SELECT
  order_id,
  review_id,
  review_score,
  review_comment_message,
  TRY_CAST(review_creation_date AS TIMESTAMP) AS review_created_at,
  TRY_CAST(review_answer_timestamp AS TIMESTAMP) AS review_answered_at
FROM read_csv_auto('data/raw/olist_order_reviews_dataset.csv');

-- ========================
-- Customers
-- ========================

CREATE OR REPLACE VIEW stg_customers AS
SELECT
  customer_id,
  customer_unique_id,
  customer_city,
  customer_state
FROM read_csv_auto('data/raw/olist_customers_dataset.csv');