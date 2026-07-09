-- =============================================================================
-- fact_order_payments_tests.sql
-- Quality checks for warehouse.fact_order_payments
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity between staging and the fact
WITH staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_order_payments`
),
fact_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.warehouse.fact_order_payments`
)
SELECT
    staging_count.row_count                     AS staging_row_count,
    fact_count.row_count                        AS fact_row_count,
    staging_count.row_count = fact_count.row_count AS counts_match
FROM staging_count, fact_count;

-- 2. No null keys
SELECT COUNT(*) AS null_keys
FROM `ai-bi-pipeline.warehouse.fact_order_payments`
WHERE order_id IS NULL
   OR customer_unique_id IS NULL
   OR order_date_key IS NULL;

-- 3. No negative payment_value
SELECT COUNT(*) AS negative_payment_values
FROM `ai-bi-pipeline.warehouse.fact_order_payments`
WHERE payment_value < 0;

-- 4. No negative payment_installments
SELECT COUNT(*) AS negative_installments
FROM `ai-bi-pipeline.warehouse.fact_order_payments`
WHERE payment_installments < 0;

-- 5. order_date_key should always exist in dim_date
SELECT COUNT(*) AS orphaned_date_keys
FROM `ai-bi-pipeline.warehouse.fact_order_payments` f
LEFT JOIN `ai-bi-pipeline.warehouse.dim_date` d
    ON f.order_date_key = d.date_key
WHERE d.date_key IS NULL;

-- 6. Distinct payment types - eyeball check for unexpected values
SELECT DISTINCT payment_type
FROM `ai-bi-pipeline.warehouse.fact_order_payments`
ORDER BY payment_type;