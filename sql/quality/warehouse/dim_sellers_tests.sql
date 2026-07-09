-- =============================================================================
-- dim_sellers_tests.sql
-- Quality checks for warehouse.dim_sellers
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity between staging and the dimension
-- (geolocation join cannot fan out - stg_geolocation is unique per zip_code_prefix)
WITH staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_sellers`
),
dim_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.warehouse.dim_sellers`
)
SELECT
    staging_count.row_count                     AS staging_row_count,
    dim_count.row_count                         AS dim_row_count,
    staging_count.row_count = dim_count.row_count AS counts_match
FROM staging_count, dim_count;

-- 2. No null seller_id (key)
SELECT COUNT(*) AS null_seller_ids
FROM `ai-bi-pipeline.warehouse.dim_sellers`
WHERE seller_id IS NULL;

-- 3. No duplicate seller_id
SELECT seller_id, COUNT(*) AS duplicates
FROM `ai-bi-pipeline.warehouse.dim_sellers`
GROUP BY seller_id
HAVING COUNT(*) > 1;

-- 4. Zip code prefix is always 5 characters
SELECT COUNT(*) AS bad_zip_codes
FROM `ai-bi-pipeline.warehouse.dim_sellers`
WHERE LENGTH(zip_code_prefix) != 5;

-- 5. State values are always 2 characters
SELECT COUNT(*) AS bad_state_codes
FROM `ai-bi-pipeline.warehouse.dim_sellers`
WHERE LENGTH(state) != 2;

-- 6. Non-null lat/lng should always fall within Brazil's bounding box
SELECT COUNT(*) AS bad_coordinates
FROM `ai-bi-pipeline.warehouse.dim_sellers`
WHERE (lat IS NOT NULL AND lat NOT BETWEEN -33.75 AND 5.27)
   OR (lng IS NOT NULL AND lng NOT BETWEEN -73.99 AND -34.79);

-- 7. Volume of sellers with no geolocation match - eyeball check
SELECT COUNT(*) AS sellers_missing_geolocation
FROM `ai-bi-pipeline.warehouse.dim_sellers`
WHERE lat IS NULL OR lng IS NULL;