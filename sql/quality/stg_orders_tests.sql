-- Quality checks for stg_orders

-- 0. Verify consistency
WITH raw_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.raw_olist.orders`
),
staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_orders`
)

SELECT
    raw_count.row_count         AS raw_row_count,
    staging_count.row_count     AS staging_row_count,
    raw_count.row_count = staging_count.row_count AS counts_match
FROM raw_count, staging_count;

-- 1. Row count should be > 0
SELECT COUNT(*) AS row_count
FROM `ai-bi-pipeline.staging.stg_orders`;

-- 2. No null order_ids (primary key)
SELECT COUNT(*) AS null_order_ids
FROM `ai-bi-pipeline.staging.stg_orders`
WHERE order_id IS NULL;

-- 3. No duplicate order_ids
SELECT order_id, COUNT(*) AS duplicates
FROM `ai-bi-pipeline.staging.stg_orders`
GROUP BY order_id
HAVING COUNT(*) > 1;

-- 4. Valid order_status values only
SELECT DISTINCT order_status
FROM `ai-bi-pipeline.staging.stg_orders`;

-- 5. Delivered date should never be before purchase date
SELECT COUNT(*) AS bad_dates
FROM `ai-bi-pipeline.staging.stg_orders`
WHERE delivered_to_customer_date < DATE(purchased_at);

-- 6. Late delivery flag should be consistent with delivery dates
SELECT COUNT(*) AS inconsistent_late_delivery
FROM `ai-bi-pipeline.staging.stg_orders`
WHERE is_late_delivery = TRUE
  AND (delivered_to_customer_date IS NULL
       OR estimated_delivery_date IS NULL
       OR delivered_to_customer_date <= estimated_delivery_date);

-- 7. Late delivery flag should be FALSE when delivery is on time
SELECT COUNT(*) AS inconsistent_late_delivery_false
FROM `ai-bi-pipeline.staging.stg_orders`
WHERE is_late_delivery = FALSE
  AND delivered_to_customer_date IS NOT NULL
  AND estimated_delivery_date IS NOT NULL
  AND delivered_to_customer_date > estimated_delivery_date;