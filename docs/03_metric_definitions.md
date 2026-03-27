## Metric Definitions

### Delivered Orders

Definition:
Unique orders successfully delivered to the customer.

Calculation:
- COUNT(DISTINCT order_id)

Filters:
- order_status = 'delivered'
- order_delivered_customer_date IS NOT NULL

Rationale:
Combining order status with a valid delivery timestamp ensures only completed deliveries are included, excluding inconsistent records.

---

### GMV (Gross Merchandise Value)

Definition:
Total value of delivered order items, including product price and shipping.

Calculation:
- SUM(price + freight_value)

Grain:
- Calculated at order item level, then aggregated (e.g. monthly)

Filters:
- order_status = 'delivered'
- order_delivered_customer_date IS NOT NULL

Rationale:
Item-level calculation captures the full order value, as orders may contain multiple items with individual prices and shipping costs.

---

### Month-over-Month (MoM) GMV Growth

Definition:
Measures the change in GMV compared to the previous month.

Calculation:
- Previous month GMV:
  - LAG(gmv) OVER (ORDER BY date_month)
- Absolute change:
  - gmv - prev_gmv
- Percentage change:
  - (gmv - prev_gmv) / prev_gmv * 100

Edge Cases:
- Growth is not calculated if previous GMV is NULL or 0.

Rationale:
Provides insight into short-term revenue trends and business momentum.