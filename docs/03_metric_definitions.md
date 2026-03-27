# Metric Definitions

This document defines the key business metrics used throughout the analysis, including their calculation logic, filters, and analytical rationale.

---

## Delivered Orders

**Definition**  
Number of unique orders successfully delivered to customers.

**Calculation**  
- `COUNT(DISTINCT order_id)`

**Filters**  
- `order_status = 'delivered'`  
- `order_delivered_customer_date IS NOT NULL`

**Rationale**  
Combining order status with a valid delivery timestamp ensures that only completed and consistent transactions are included.  
This avoids counting orders with incomplete or inconsistent delivery information.

---

## GMV (Gross Merchandise Value)

**Definition**  
Total monetary value of delivered orders, including product price and shipping costs.

**Calculation**  
- `SUM(price + freight_value)`

**Grain**  
- Calculated at the **order item level**, then aggregated (e.g. by month)

**Filters**  
- `order_status = 'delivered'`  
- `order_delivered_customer_date IS NOT NULL`

**Rationale**  
GMV must be calculated at the order item level to accurately capture total revenue, as orders may contain multiple items with individual prices and shipping costs.

---

## Month-over-Month (MoM) GMV Growth

**Definition**  
Measures the relative change in GMV compared to the previous month.

**Calculation**

- Previous month GMV:  
  - `LAG(gmv) OVER (ORDER BY date_month)`

- Absolute change:  
  - `gmv - prev_gmv`

- Percentage change:  
  - `(gmv - prev_gmv) / prev_gmv * 100`

**Edge Cases**  
- Growth is not calculated when:
  - `prev_gmv IS NULL`  
  - `prev_gmv = 0`

**Rationale**  
MoM growth provides insight into short-term revenue trends and business momentum.  
It enables identification of growth phases, slowdowns, and potential seasonality effects.

---

## Analytical Considerations

- **Consistent filtering is critical:**  
  All revenue-related metrics are restricted to delivered orders to ensure comparability

- **Grain awareness:**  
  Metrics derived from `order_items` must not be aggregated at the `orders` level prematurely

- **Time-based metrics:**  
  Use delivery date (not purchase date) when analyzing realized revenue

---

These metric definitions ensure consistency, reproducibility, and alignment with real-world business logic.