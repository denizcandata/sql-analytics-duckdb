# Data Overview

## Table Inventory

| table | grain | primary key (assumed) | main join keys | notes |
|-------|--------|----------------------|----------------|-------|
| olist_customers_dataset | 1 row = 1 customer | customer_id | customer_id | customer location info |
| olist_geolocation_dataset | 1 row = 1 geolocation entry (zip_code_prefix + lat/long) | none (zip_code not unique) | geolocation_zip_code_prefix | geolocation info |
| olist_order_items_dataset | 1 row = 1 item in order | (order_id, order_item_id) | order_id | contains price & freight |
| olist_order_payments_dataset | 1 row = 1 payment transaction per order | (order_id, payment_sequential) | order_id | orders can have multiple payments |
| olist_order_reviews_dataset | 1 row = 1 review | none (not unique) | order_id | multiple reviews per order possible|
| olist_orders_dataset | 1 row = 1 order | order_id | customer_id | order status & timestamps |
| olist_products_dataset | 1 row = 1 product | product_id | product_id | product info|
| olist_sellers_dataset | 1 row = 1 seller | seller_id | seller_id | seller info |
| product_category_name_translation | 1 row = 1 product category | - | product_category_name | english translation product category |

### Observations – olist_order_reviews_dataset

- order_id is not unique
- review_id is expected to be unique, but duplicates exist in the dataset
- some orders have multiple review rows
- not every order has a review

## Table Relationships (Conceptual)

customers (1) ---- (n) orders  
orders (1) ---- (n) order_items  
orders (1) ---- (n) payments  
orders (1) ---- (n) reviews  
products (1) ---- (n) order_items  
sellers (1) ---- (n) order_items  
products (n) ---- (1) product_category_name_translation  
customers (n) ---- (1) geolocation