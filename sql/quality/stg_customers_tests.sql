-- =============================================================================
-- stg_customers_checks.sql
-- Quality checks for staging.stg_customers
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity between raw and staging
WITH raw_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.raw_olist.customers`
),
staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_customers`
)
SELECT
    raw_count.row_count         AS raw_row_count,
    staging_count.row_count     AS staging_row_count,
    raw_count.row_count = staging_count.row_count AS counts_match
FROM raw_count, staging_count;

-- 2. No null customer_ids (primary key)
SELECT COUNT(*) AS null_customer_ids
FROM `ai-bi-pipeline.staging.stg_customers`
WHERE customer_id IS NULL;

-- 3. No duplicate customer_ids (should be unique per order)
SELECT customer_id, COUNT(*) AS duplicates
FROM `ai-bi-pipeline.staging.stg_customers`
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- 4. No null unique customer ids
SELECT COUNT(*) AS null_unique_customer_ids
FROM `ai-bi-pipeline.staging.stg_customers`
WHERE customer_unique_id IS NULL;

-- 5. Zip code prefix is always 5 characters after LPAD
SELECT COUNT(*) AS bad_zip_codes
FROM `ai-bi-pipeline.staging.stg_customers`
WHERE LENGTH(zip_code_prefix) != 5;

-- 6. State values are always 2 characters (Brazilian state codes)
SELECT COUNT(*) AS bad_state_codes
FROM `ai-bi-pipeline.staging.stg_customers`
WHERE LENGTH(state) != 2;

-- 7. No null cities or states
SELECT COUNT(*) AS null_locations
FROM `ai-bi-pipeline.staging.stg_customers`
WHERE city IS NULL OR state IS NULL;

-- 8. Distinct states - eyeball check for unexpected values
SELECT DISTINCT state
FROM `ai-bi-pipeline.staging.stg_customers`
ORDER BY state;