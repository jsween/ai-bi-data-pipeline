-- =============================================================================
-- dim_date_tests.sql
-- Quality checks for warehouse.dim_date
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count should match the expected number of days in the range
-- 2016-01-01 through 2020-12-31 inclusive = 1,827 days
SELECT COUNT(*) = 1827 AS row_count_matches
FROM `ai-bi-pipeline.warehouse.dim_date`;

-- 2. No null date_key or full_date
SELECT COUNT(*) AS null_dates
FROM `ai-bi-pipeline.warehouse.dim_date`
WHERE date_key IS NULL OR full_date IS NULL;

-- 3. date_key is unique
SELECT date_key, COUNT(*) AS duplicates
FROM `ai-bi-pipeline.warehouse.dim_date`
GROUP BY date_key
HAVING COUNT(*) > 1;

-- 4. full_date is unique
SELECT full_date, COUNT(*) AS duplicates
FROM `ai-bi-pipeline.warehouse.dim_date`
GROUP BY full_date
HAVING COUNT(*) > 1;

-- 5. date_key correctly encodes full_date as YYYYMMDD
SELECT COUNT(*) AS mismatched_date_keys
FROM `ai-bi-pipeline.warehouse.dim_date`
WHERE date_key != CAST(FORMAT_DATE('%Y%m%d', full_date) AS INT64);

-- 6. Min and max dates match the expected range
SELECT
    MIN(full_date) AS min_date,
    MAX(full_date) AS max_date,
    MIN(full_date) = DATE('2016-01-01') AS min_matches_expected,
    MAX(full_date) = DATE('2020-12-31') AS max_matches_expected
FROM `ai-bi-pipeline.warehouse.dim_date`;