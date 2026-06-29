-- =============================================================================
-- stg_order_items_checks.sql
-- Quality checks for staging.stg_order_items
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity between raw and staging
WITH raw_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.raw_olist.order_items`
),
staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_order_items`
)
SELECT
    raw_count.row_count                             AS raw_row_count,
    staging_count.row_count                         AS staging_row_count,
    raw_count.row_count = staging_count.row_count   AS counts_match
FROM raw_count, staging_count;

-- 2. No null foreign keys
SELECT COUNT(*) AS null_foreign_keys
FROM `ai-bi-pipeline.staging.stg_order_items`
WHERE order_id IS NULL
   OR product_id IS NULL
   OR seller_id IS NULL;

-- 3. No negative or zero prices
-- min observed price is 0.85 so anything <= 0 is suspicious
SELECT COUNT(*) AS bad_prices
FROM `ai-bi-pipeline.staging.stg_order_items`
WHERE price <= 0;

-- 4. No negative freight values
-- 0.0 is valid (free shipping exists in the data)
SELECT COUNT(*) AS negative_freight
FROM `ai-bi-pipeline.staging.stg_order_items`
WHERE freight_value < 0;

-- 5. Price within observed bounds (flag anything above known max for review)
-- Max observed: 6735.00 — flag anything significantly above this
SELECT COUNT(*) AS price_outliers
FROM `ai-bi-pipeline.staging.stg_order_items`
WHERE price > 7000;

-- 6. Freight within observed bounds
-- Max observed: 409.68 — flag anything significantly above this
SELECT COUNT(*) AS freight_outliers
FROM `ai-bi-pipeline.staging.stg_order_items`
WHERE freight_value > 500;

-- 7. total_amount equals price + freight_value
-- Verifies the derived column is calculated correctly
SELECT COUNT(*) AS bad_total_amounts
FROM `ai-bi-pipeline.staging.stg_order_items`
WHERE ROUND(total_amount, 2) != ROUND(price + freight_value, 2);

-- 8. Item sequence number always starts at 1 and never exceeds observed max
-- Min observed: 1, Max observed: 21
SELECT COUNT(*) AS bad_sequence_numbers
FROM `ai-bi-pipeline.staging.stg_order_items`
WHERE item_sequence_number < 1
   OR item_sequence_number > 21;

-- 9. No null shipping limit dates
SELECT COUNT(*) AS null_shipping_dates
FROM `ai-bi-pipeline.staging.stg_order_items`
WHERE shipping_limit_date IS NULL;

-- 10. Shipping limit date should be a reasonable date range
-- Olist data covers 2016-2018
SELECT COUNT(*) AS bad_shipping_dates
FROM `ai-bi-pipeline.staging.stg_order_items`
WHERE shipping_limit_date < '2016-01-01'
   OR shipping_limit_date > '2019-12-31';

-- 11. Eyeball check — order item counts per order
-- Most orders should have 1-2 items; anything above 10 is worth reviewing
SELECT item_sequence_number, COUNT(*) AS order_count
FROM `ai-bi-pipeline.staging.stg_order_items`
GROUP BY item_sequence_number
ORDER BY item_sequence_number;