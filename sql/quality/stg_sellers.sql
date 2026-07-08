-- =============================================================================
-- stg_sellers_tests.sql
-- Quality checks for staging.stg_sellers
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity between raw and staging
WITH raw_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.raw_olist.sellers`
),
staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_sellers`
)
SELECT
    raw_count.row_count         AS raw_row_count,
    staging_count.row_count     AS staging_row_count,
    raw_count.row_count = staging_count.row_count AS counts_match
FROM raw_count, staging_count;

-- 2. No null seller_ids (primary key)
SELECT COUNT(*) AS null_seller_ids
FROM `ai-bi-pipeline.staging.stg_sellers`
WHERE seller_id IS NULL;

-- 3. No duplicate seller_ids
SELECT seller_id, COUNT(*) AS duplicates
FROM `ai-bi-pipeline.staging.stg_sellers`
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- 4. Zip code prefix is always 5 characters after LPAD
SELECT COUNT(*) AS bad_zip_codes
FROM `ai-bi-pipeline.staging.stg_sellers`
WHERE LENGTH(zip_code_prefix) != 5;

-- 5. State values are always 2 characters (Brazilian state codes)
SELECT COUNT(*) AS bad_state_codes
FROM `ai-bi-pipeline.staging.stg_sellers`
WHERE LENGTH(state) != 2;

-- 6. No null cities or states
SELECT COUNT(*) AS null_locations
FROM `ai-bi-pipeline.staging.stg_sellers`
WHERE city IS NULL OR state IS NULL;

-- 7. Distinct states - eyeball check for unexpected values
SELECT DISTINCT state
FROM `ai-bi-pipeline.staging.stg_sellers`
ORDER BY state;