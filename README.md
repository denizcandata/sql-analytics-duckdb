# SQL Analytics Project – E-Commerce (DuckDB)

This project analyzes an e-commerce dataset using SQL (DuckDB) to answer real-world business questions across sales performance, customer behavior, and operational efficiency.

The focus is on building a clean analytical workflow using SQL-first principles, including data exploration, metric definition, and advanced OLAP-style queries.

---

## Objective

The goal of this project is to:

- Use SQL as the primary analysis tool  
- Build a structured analytics workflow (staging → metrics → insights)  
- Answer key business questions such as:
  - How is revenue distributed across sellers?
  - Does delivery time impact customer satisfaction?
  - How strong is customer retention?

---

## Dataset

The dataset is based on the Olist e-commerce dataset, containing:

- Orders  
- Order items  
- Customers  
- Payments  
- Reviews  
- Sellers  
- Products  

The dataset represents real-world transactional e-commerce activity, enabling realistic business analysis scenarios.

---

## Data Model

Key tables and relationships:

- `orders` → 1 row per order  
- `order_items` → 1 row per item in an order  
- `customers` → contains `customer_unique_id` (true customer identifier)  
- `reviews` → multiple reviews per order possible  

Important note:

- `customer_id` is not a stable customer identifier  
- `customer_unique_id` is used for customer-level analysis  

---

## Core Metrics

- GMV (Gross Merchandise Value)  
- Delivered Orders  
- AOV (Average Order Value)  
- Items per Order (IPO)  
- Month-over-Month (MoM) Growth  

---

## Key Insights

### Seller Performance

Revenue is moderately distributed across sellers:

- Top 10 sellers → 13% of GMV  
- Top 20 sellers → 21% of GMV  
- Top 132 sellers (~14%) → 50% of GMV  

This indicates a relatively broad revenue distribution rather than a strong 80/20 Pareto concentration.

---

### Delivery Time Impact

Customer satisfaction decreases with longer delivery times:

- 0–3 days → 4.46 avg review score  
- 4–7 days → 4.40  
- 8–14 days → 4.30  
- 15+ days → 3.67  

A clear drop occurs beyond 14 days, indicating a critical threshold.

Over 27,000 orders fall into the 15+ day category, representing a major opportunity for improvement.

---

### Customer Retention

Customer retention is very low:

- Only ~3% of customers place more than one order  
- Over 90,000 customers purchase only once  

This suggests a strong dependency on new customer acquisition rather than customer retention.

---

## Key Business Impact

- Identified low customer retention (~3%)  
- Highlighted delivery time as a key driver of customer satisfaction  
- Showed that revenue is broadly distributed across sellers  

---

## Tech Stack

- SQL (DuckDB)  
- VS Code  
- CSV-based data processing  

---

## Project Structure

sql/
- 00_staging_views.sql  
- 01_exploration.sql  
- 02_core_metrics.sql  
- 03_advanced_analysis.sql  

docs/
- 01_data_overview.md  
- 02_data_quality.md  
- 03_metric_definitions.md  

---

## How to Run

1. Open the project in VS Code  
2. Ensure DuckDB is installed  
3. Run SQL files sequentially:
   - staging → exploration → metrics → analysis  

Note: Raw data files are not included in this repository.

---

## Key Learnings

- Understanding data grain is critical for correct aggregation  
- Data modeling (e.g. correct customer identifier) significantly impacts results  
- SQL alone is sufficient to perform advanced business analysis  
- Clear metric definitions are essential for consistent reporting  