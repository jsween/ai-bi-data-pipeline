-- =============================================================================
-- dim_customers_tests.sql
-- Quality checks for warehouse.dim_customers
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count should equal the distinct count of customer_unique_id in staging
WITH distinct_customers AS (
    SELECT COUNT(DISTINCT customer_unique_id) AS unique_customer_count
    FROM `ai-bi-pipeline.staging.stg_customers`
),
dim_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.warehouse.dim_customers`
)
SELECT
    distinct_customers.unique_customer_count   AS staging_unique_customers,
    dim_count.row_count                        AS dim_row_count,
    distinct_customers.unique_customer_count = dim_count.row_count AS counts_match
FROM distinct_customers, dim_count;

-- 2. No null customer_unique_id (key)
SELECT COUNT(*) AS null_customer_ids
FROM `ai-bi-pipeline.warehouse.dim_customers`
WHERE customer_unique_id IS NULL;

-- 3. No duplicate customer_unique_id
SELECT customer_unique_id, COUNT(*) AS duplicates
FROM `ai-bi-pipeline.warehouse.dim_customers`
GROUP BY customer_unique_id
HAVING COUNT(*) > 1;

-- 4. Zip code prefix is always 5 characters
SELECT COUNT(*) AS bad_zip_codes
FROM `ai-bi-pipeline.warehouse.dim_customers`
WHERE LENGTH(zip_code_prefix) != 5;

-- 5. State values are always 2 characters
SELECT COUNT(*) AS bad_state_codes
FROM `ai-bi-pipeline.warehouse.dim_customers`
WHERE LENGTH(state) != 2;

-- 6. No null cities or states
SELECT COUNT(*) AS null_locations
FROM `ai-bi-pipeline.warehouse.dim_customers`
WHERE city IS NULL OR state IS NULL;

-- 7. Non-null lat/lng should always fall within Brazil's bounding box
-- (nulls are expected/OK - not every zip_code_prefix has a geolocation match)
SELECT COUNT(*) AS bad_coordinates
FROM `ai-bi-pipeline.warehouse.dim_customers`
WHERE (lat IS NOT NULL AND lat NOT BETWEEN -33.75 AND 5.27)
   OR (lng IS NOT NULL AND lng NOT BETWEEN -73.99 AND -34.79);

-- 8. Volume of customers with no geolocation match - eyeball check
SELECT COUNT(*) AS customers_missing_geolocation
FROM `ai-bi-pipeline.warehouse.dim_customers`
WHERE lat IS NULL OR lng IS NULL;