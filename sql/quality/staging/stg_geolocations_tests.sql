-- =============================================================================
-- stg_geolocation_tests.sql
-- Quality checks for staging.stg_geolocation
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Grain check: staging should have exactly one row per distinct zip_code_prefix
-- (not a raw/staging row count match - staging is aggregated, so counts differ)
WITH distinct_raw_zips AS (
    SELECT COUNT(DISTINCT LPAD(CAST(geolocation_zip_code_prefix AS STRING), 5, '0')) AS zip_count
    FROM `ai-bi-pipeline.raw_olist.geolocation`
),
staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_geolocation`
)
SELECT
    distinct_raw_zips.zip_count     AS distinct_raw_zip_prefixes,
    staging_count.row_count         AS staging_row_count,
    staging_count.row_count <= distinct_raw_zips.zip_count AS counts_are_plausible
FROM distinct_raw_zips, staging_count;

-- 2. No null zip_code_prefix (key)
SELECT COUNT(*) AS null_zip_codes
FROM `ai-bi-pipeline.staging.stg_geolocation`
WHERE zip_code_prefix IS NULL;

-- 3. No duplicate zip_code_prefix (should be unique after aggregation)
SELECT zip_code_prefix, COUNT(*) AS duplicates
FROM `ai-bi-pipeline.staging.stg_geolocation`
GROUP BY zip_code_prefix
HAVING COUNT(*) > 1;

-- 4. Zip code prefix is always 5 characters after LPAD
SELECT COUNT(*) AS bad_zip_codes
FROM `ai-bi-pipeline.staging.stg_geolocation`
WHERE LENGTH(zip_code_prefix) != 5;

-- 5. Lat/lng should always fall within Brazil's bounding box
SELECT COUNT(*) AS bad_coordinates
FROM `ai-bi-pipeline.staging.stg_geolocation`
WHERE lat NOT BETWEEN -33.75 AND 5.27
   OR lng NOT BETWEEN -73.99 AND -34.79;

-- 6. State values are always 2 characters (Brazilian state codes)
SELECT COUNT(*) AS bad_state_codes
FROM `ai-bi-pipeline.staging.stg_geolocation`
WHERE LENGTH(state) != 2;

-- 7. No null cities or states
SELECT COUNT(*) AS null_locations
FROM `ai-bi-pipeline.staging.stg_geolocation`
WHERE city IS NULL OR state IS NULL;

-- 8. Distinct states - eyeball check for unexpected values
SELECT DISTINCT state
FROM `ai-bi-pipeline.staging.stg_geolocation`
ORDER BY state;