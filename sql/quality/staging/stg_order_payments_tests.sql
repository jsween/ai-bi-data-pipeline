-- =============================================================================
-- stg_order_payments_tests.sql
-- Quality checks for staging.stg_order_payments
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity between raw and staging
WITH raw_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.raw_olist.order_payments`
),
staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_order_payments`
)
SELECT
    raw_count.row_count                             AS raw_row_count,
    staging_count.row_count                         AS staging_row_count,
    raw_count.row_count = staging_count.row_count   AS counts_match
FROM raw_count, staging_count;

-- 2. No null order_ids (foreign key)
SELECT COUNT(*) AS null_order_ids
FROM `ai-bi-pipeline.staging.stg_order_payments`
WHERE order_id IS NULL;

-- 3. No null payment_type
SELECT COUNT(*) AS null_payment_types
FROM `ai-bi-pipeline.staging.stg_order_payments`
WHERE payment_type IS NULL;

-- 4. No negative payment_value
-- 0.00 is valid (e.g. a voucher-only leg of a split payment)
SELECT COUNT(*) AS negative_payment_values
FROM `ai-bi-pipeline.staging.stg_order_payments`
WHERE payment_value < 0;

-- 5. Payment value within observed bounds (flag anything above known max for review)
-- Max observed: ~13,664.08 — flag anything significantly above this
SELECT COUNT(*) AS payment_value_outliers
FROM `ai-bi-pipeline.staging.stg_order_payments`
WHERE payment_value > 15000;

-- 6. Payment installments should never be negative
SELECT COUNT(*) AS negative_installments
FROM `ai-bi-pipeline.staging.stg_order_payments`
WHERE payment_installments < 0;

-- 7. Payment sequence number always starts at 1
SELECT COUNT(*) AS bad_sequence_numbers
FROM `ai-bi-pipeline.staging.stg_order_payments`
WHERE payment_sequence_number < 1;

-- 8. Distinct payment types - eyeball check for unexpected values
SELECT DISTINCT payment_type
FROM `ai-bi-pipeline.staging.stg_order_payments`
ORDER BY payment_type;