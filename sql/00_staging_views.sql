-- 00_staging_views.sql
-- Minimal staging layer: types + naming, no business filters.

CREATE OR REPLACE VIEW stg_orders AS
SELECT
  order_id,
  customer_id,
  order_status,
  try_cast(order_purchase_timestamp AS TIMESTAMP) AS purchased_at,
  try_cast(order_delivered_customer_date AS TIMESTAMP) AS delivered_at,
  try_cast(order_estimated_delivery_date AS TIMESTAMP) AS estimated_delivery_at
FROM read_csv_auto('data/raw/olist_orders_dataset.csv');

CREATE OR REPLACE VIEW stg_order_items AS
SELECT
  order_id,
  order_item_id,
  product_id,
  seller_id,
  try_cast(shipping_limit_date AS TIMESTAMP) AS shipping_limit_at,
  try_cast(price AS DOUBLE) AS price,
  try_cast(freight_value AS DOUBLE) AS freight_value
FROM read_csv_auto('data/raw/olist_order_items_dataset.csv');

CREATE OR REPLACE VIEW stg_order_reviews AS
SELECT
  order_id,
  review_id,
  review_score,
  review_comment_message,
  try_cast(review_creation_date AS TIMESTAMP) AS review_created_at,
  try_cast(review_answer_timestamp AS TIMESTAMP) AS review_answered_at
FROM read_csv_auto('data/raw/olist_order_reviews_dataset.csv');

CREATE OR REPLACE VIEW stg_customers AS
SELECT
  customer_id,
  customer_unique_id,
  customer_city,
  customer_state
FROM read_csv_auto('data/raw/olist_customers_dataset.csv');

--Check the staging views:
SELECT * FROM stg_orders LIMIT 5;
SELECT * FROM stg_order_items LIMIT 5;
SELECT * FROM stg_order_reviews LIMIT 5;
SELECT * FROM stg_customers LIMIT 5;