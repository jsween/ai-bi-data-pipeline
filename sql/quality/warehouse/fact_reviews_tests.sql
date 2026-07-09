-- =============================================================================
-- fact_reviews_tests.sql
-- Quality checks for warehouse.fact_reviews
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity between staging and the fact
WITH staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_order_reviews`
),
fact_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.warehouse.fact_reviews`
)
SELECT
    staging_count.row_count                     AS staging_row_count,
    fact_count.row_count                        AS fact_row_count,
    staging_count.row_count = fact_count.row_count AS counts_match
FROM staging_count, fact_count;

-- 2. No null keys
SELECT COUNT(*) AS null_keys
FROM `ai-bi-pipeline.warehouse.fact_reviews`
WHERE review_id IS NULL
   OR order_id IS NULL
   OR customer_unique_id IS NULL
   OR review_date_key IS NULL;

-- 3. Review score should always be between 1 and 5
SELECT COUNT(*) AS bad_scores
FROM `ai-bi-pipeline.warehouse.fact_reviews`
WHERE score < 1 OR score > 5;

-- 4. Response time should never be negative
SELECT COUNT(*) AS negative_response_times
FROM `ai-bi-pipeline.warehouse.fact_reviews`
WHERE response_time_days < 0;

-- 5. review_date_key should always exist in dim_date
SELECT COUNT(*) AS orphaned_date_keys
FROM `ai-bi-pipeline.warehouse.fact_reviews` f
LEFT JOIN `ai-bi-pipeline.warehouse.dim_date` d
    ON f.review_date_key = d.date_key
WHERE d.date_key IS NULL;