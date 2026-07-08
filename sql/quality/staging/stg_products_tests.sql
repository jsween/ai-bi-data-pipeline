-- =============================================================================
-- stg_products_tests.sql
-- Quality checks for staging.stg_products
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity between raw and staging
--    (guards against the translation join fanning out rows if the translation
--    table ever contains duplicate product_category_name values)
WITH raw_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.raw_olist.products`
),
staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_products`
)
SELECT
    raw_count.row_count         AS raw_row_count,
    staging_count.row_count     AS staging_row_count,
    raw_count.row_count = staging_count.row_count AS counts_match
FROM raw_count, staging_count;

-- 2. No null product_ids (primary key)
SELECT COUNT(*) AS null_product_ids
FROM `ai-bi-pipeline.staging.stg_products`
WHERE product_id IS NULL;

-- 3. No duplicate product_ids
SELECT product_id, COUNT(*) AS duplicates
FROM `ai-bi-pipeline.staging.stg_products`
GROUP BY product_id
HAVING COUNT(*) > 1;

-- 4. Category name should never be null (coalesced to 'unknown' as a fallback)
SELECT COUNT(*) AS null_category_names
FROM `ai-bi-pipeline.staging.stg_products`
WHERE category_name IS NULL;

-- 5. Categories that fell through to 'unknown' - eyeball check on volume
SELECT COUNT(*) AS unknown_category_count
FROM `ai-bi-pipeline.staging.stg_products`
WHERE category_name = 'unknown';

-- 6. No negative weights or dimensions (nulls are OK, negatives are not)
SELECT COUNT(*) AS bad_dimension_values
FROM `ai-bi-pipeline.staging.stg_products`
WHERE weight_g < 0 OR length_cm < 0 OR height_cm < 0 OR width_cm < 0;

-- 7. Distinct category names - eyeball check for unexpected values
SELECT DISTINCT category_name
FROM `ai-bi-pipeline.staging.stg_products`
ORDER BY category_name;