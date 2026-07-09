-- =============================================================================
-- fact_order_items_tests.sql
-- Quality checks for warehouse.fact_order_items
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity between staging and the fact
-- (inner joins should neither drop rows nor fan out - order_items -> orders
-- is many-to-one, orders -> customers is one-to-one)
WITH staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_order_items`
),
fact_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.warehouse.fact_order_items`
)
SELECT
    staging_count.row_count                     AS staging_row_count,
    fact_count.row_count                        AS fact_row_count,
    staging_count.row_count = fact_count.row_count AS counts_match
FROM staging_count, fact_count;

-- 2. No null keys
SELECT COUNT(*) AS null_keys
FROM `ai-bi-pipeline.warehouse.fact_order_items`
WHERE order_id IS NULL
   OR product_id IS NULL
   OR seller_id IS NULL
   OR customer_unique_id IS NULL
   OR order_date_key IS NULL;

-- 3. No negative or zero prices
SELECT COUNT(*) AS bad_prices
FROM `ai-bi-pipeline.warehouse.fact_order_items`
WHERE price <= 0;

-- 4. No negative freight values
SELECT COUNT(*) AS negative_freight
FROM `ai-bi-pipeline.warehouse.fact_order_items`
WHERE freight_value < 0;

-- 5. total_amount equals price + freight_value
SELECT COUNT(*) AS bad_total_amounts
FROM `ai-bi-pipeline.warehouse.fact_order_items`
WHERE ROUND(total_amount, 2) != ROUND(price + freight_value, 2);

-- 6. order_date_key correctly encodes the purchase date as YYYYMMDD
SELECT COUNT(*) AS mismatched_date_keys
FROM `ai-bi-pipeline.warehouse.fact_order_items`
WHERE order_date_key != CAST(FORMAT_DATE('%Y%m%d', DATE(purchased_at)) AS INT64);

-- 7. order_date_key should always exist in dim_date
SELECT COUNT(*) AS orphaned_date_keys
FROM `ai-bi-pipeline.warehouse.fact_order_items` f
LEFT JOIN `ai-bi-pipeline.warehouse.dim_date` d
    ON f.order_date_key = d.date_key
WHERE d.date_key IS NULL;

-- 8. Distinct order statuses - eyeball check for unexpected values
SELECT DISTINCT order_status
FROM `ai-bi-pipeline.warehouse.fact_order_items`
ORDER BY order_status;