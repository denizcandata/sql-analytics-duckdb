-- MoM Growth for GMV (delivered_month)

WITH monthly_gmv AS (
  SELECT
    CAST(DATE_TRUNC('month', o.delivered_at) AS DATE) AS date_month,
    SUM(oi.price + oi.freight_value) AS gmv
  FROM stg_order_items oi
  JOIN stg_orders o
    ON o.order_id = oi.order_id
  WHERE o.order_status = 'delivered'
    AND o.delivered_at IS NOT NULL
  GROUP BY 1
),

prev_monthly_gmv AS (
  SELECT
    date_month,
    gmv,
    LAG(gmv) OVER (ORDER BY date_month) AS prev_gmv
  FROM monthly_gmv
)

SELECT
  date_month,
  gmv,
  prev_gmv,
  gmv - prev_gmv AS mom_change,
  CASE
    WHEN prev_gmv IS NOT NULL AND prev_gmv <> 0
    THEN ROUND((gmv - prev_gmv) / prev_gmv * 100, 2)
    ELSE NULL
  END AS mom_change_percentage
FROM prev_monthly_gmv
ORDER BY date_month;

-- Review Score vs Delivery Time

/*
1️⃣ Delivery Time berechnen
2️⃣ Reviews sauber auf Order-Level bringen
3️⃣ Beides verbinden
4️⃣ Aggregieren
*/

SELECT *
FROM stg_order_reviews
WHERE order_id IN (
  SELECT order_id
  FROM stg_order_reviews
  GROUP BY order_id
  HAVING COUNT(*) > 1
)
ORDER BY order_id;




WITH ranked_reviews AS (
  SELECT
    order_id,
    review_score,
    review_created_at,
    ROW_NUMBER() OVER (
      PARTITION BY order_id
      ORDER BY review_created_at DESC
    ) AS review_recency_rank
  FROM stg_order_reviews
),

delivery_time AS (
  SELECT 
    order_id,
    customer_id,
    DATE_DIFF('day', purchased_at, delivered_at) AS delivery_days
  FROM stg_orders
  WHERE order_status = 'delivered'
  AND delivered_at IS NOT NULL
  AND purchased_at IS NOT NULL
),

delivery_buckets AS (
  SELECT
    order_id,
    CASE
      WHEN delivery_days <= 3 THEN '0-3 days'
      WHEN delivery_days <= 7 THEN '4-7 days'
      WHEN delivery_days <= 14 THEN '8-14 days'
      ELSE '15+ days'
    END AS delivery_bucket,
    CASE
      WHEN delivery_days <= 3 THEN 1
      WHEN delivery_days <= 7 THEN 2
      WHEN delivery_days <= 14 THEN 3
      ELSE 4
    END AS bucket_order
  FROM delivery_time
)

SELECT
  db.bucket_order,
  db.delivery_bucket,
  AVG(rr.review_score) AS avg_review_score,
  COUNT(*) AS num_orders 
FROM ranked_reviews rr
JOIN delivery_buckets db
  ON rr.order_id = db.order_id
WHERE rr.review_recency_rank = 1
GROUP BY db.bucket_order, db.delivery_bucket
ORDER BY db.bucket_order;



/*
Repeat Customers
1️⃣ Orders auf Customer-Level bringen
2️⃣ Orders pro Customer zählen
3️⃣ Verteilung analysieren
*/

WITH orders AS (
  SELECT 
    o.order_id,
    c.customer_unique_id
  FROM stg_orders o
  JOIN stg_customers c
    ON o.customer_id = c.customer_id
  WHERE o.order_status = 'delivered'
    AND o.delivered_at IS NOT NULL
),
customer_orders AS (
  SELECT 
    customer_unique_id,
    COUNT(order_id) AS num_orders
  FROM orders
  GROUP BY customer_unique_id
)
SELECT 
  SUM(CASE WHEN num_orders = 1 THEN 1 ELSE 0 END) AS single_order_customers,
  SUM(CASE WHEN num_orders >= 2 THEN 1 ELSE 0 END) AS repeat_customers,
  COUNT(*) AS total_customers,
  SUM(CASE WHEN num_orders >= 2 THEN 1 ELSE 0 END) * 100.0 / COUNT(*) AS repeat_customer_rate
FROM customer_orders;
