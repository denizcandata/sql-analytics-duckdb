# Data Overview

This document provides an overview of the dataset structure, table granularity, and key relationships.

---

## Table Inventory

| table | grain | primary key (assumed) | main join keys | notes |
|-------|--------|----------------------|----------------|-------|
| olist_customers_dataset | 1 row per customer | customer_id | customer_id | includes location data (city, state) |
| olist_geolocation_dataset | 1 row per geolocation entry | none | geolocation_zip_code_prefix | zip code prefix is not unique |
| olist_order_items_dataset | 1 row per order item | (order_id, order_item_id) | order_id, product_id, seller_id | contains price and freight value |
| olist_order_payments_dataset | 1 row per payment transaction | (order_id, payment_sequential) | order_id | multiple payments per order possible |
| olist_order_reviews_dataset | 1 row per review | none | order_id | multiple reviews per order possible |
| olist_orders_dataset | 1 row per order | order_id | customer_id | includes order status and timestamps |
| olist_products_dataset | 1 row per product | product_id | product_id | product attributes |
| olist_sellers_dataset | 1 row per seller | seller_id | seller_id | seller metadata |
| product_category_name_translation | 1 row per category | none | product_category_name | maps category names to English |

---

## Key Observations

### olist_order_reviews_dataset

- `order_id` is not unique  
- `review_id` is expected to be unique, but duplicates exist  
- some orders contain multiple review entries  
- not all orders have an associated review  

**Implication:**

- Reviews must be aggregated or deduplicated before joining to order-level data  
- A window function (e.g. `ROW_NUMBER()`) is required to select a single review per order  

---

## Table Relationships (Conceptual)

The dataset follows a typical e-commerce star-like structure:

```
customers (1) ──── (n) orders  
orders (1) ──── (n) order_items  
orders (1) ──── (n) payments  
orders (1) ──── (n) reviews  
products (1) ──── (n) order_items  
sellers (1) ──── (n) order_items  
products (n) ──── (1) product_category_name_translation  
customers (n) ──── (1) geolocation  
```

---

## Analytical Considerations

- **Grain awareness is critical:**  
  Metrics such as GMV must be calculated at the `order_items` level, not `orders`

- **Customer identification:**  
  `customer_id` is not stable → use `customer_unique_id` for retention analysis

- **Review handling:**  
  Multiple reviews per order require deduplication before aggregation

- **Join logic:**  
  Most business analyses require combining:
  - orders (status, timestamps)
  - order_items (revenue)
  - customers (identity)
  - reviews (satisfaction)

---

This data structure enables analysis across the full e-commerce funnel, from transaction-level revenue to customer behavior and satisfaction.