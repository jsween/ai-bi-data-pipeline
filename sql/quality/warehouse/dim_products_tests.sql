-- =============================================================================
-- dim_products_tests.sql
-- Quality checks for warehouse.dim_products
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity between staging and the dimension (straight materialization)
WITH staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_products`
),
dim_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.warehouse.dim_products`
)
SELECT
    staging_count.row_count                     AS staging_row_count,
    dim_count.row_count                         AS dim_row_count,
    staging_count.row_count = dim_count.row_count AS counts_match
FROM staging_count, dim_count;

-- 2. No null product_id (key)
SELECT COUNT(*) AS null_product_ids
FROM `ai-bi-pipeline.warehouse.dim_products`
WHERE product_id IS NULL;

-- 3. No duplicate product_id
SELECT product_id, COUNT(*) AS duplicates
FROM `ai-bi-pipeline.warehouse.dim_products`
GROUP BY product_id
HAVING COUNT(*) > 1;

-- 4. Category name should never be null
SELECT COUNT(*) AS null_category_names
FROM `ai-bi-pipeline.warehouse.dim_products`
WHERE category_name IS NULL;

-- 5. No negative weights or dimensions
SELECT COUNT(*) AS bad_dimension_values
FROM `ai-bi-pipeline.warehouse.dim_products`
WHERE weight_g < 0 OR length_cm < 0 OR height_cm < 0 OR width_cm < 0;