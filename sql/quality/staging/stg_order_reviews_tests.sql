-- =============================================================================
-- stg_order_reviews_tests.sql
-- Quality checks for staging.stg_order_reviews
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity between raw and staging
WITH raw_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.raw_olist.order_reviews`
),
staging_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.staging.stg_order_reviews`
)
SELECT
    raw_count.row_count                             AS raw_row_count,
    staging_count.row_count                         AS staging_row_count,
    raw_count.row_count = staging_count.row_count   AS counts_match
FROM raw_count, staging_count;

-- 2. No null review_ids or order_ids (keys)
SELECT COUNT(*) AS null_keys
FROM `ai-bi-pipeline.staging.stg_order_reviews`
WHERE review_id IS NULL OR order_id IS NULL;

-- 3. Duplicate review_ids - known source data quality issue, eyeball the volume
-- rather than hard-failing on it
SELECT review_id, COUNT(*) AS duplicates
FROM `ai-bi-pipeline.staging.stg_order_reviews`
GROUP BY review_id
HAVING COUNT(*) > 1;

-- 4. Review score should always be between 1 and 5
SELECT COUNT(*) AS bad_scores
FROM `ai-bi-pipeline.staging.stg_order_reviews`
WHERE score < 1 OR score > 5;

-- 5. Response time should never be negative (answered before created)
SELECT COUNT(*) AS negative_response_times
FROM `ai-bi-pipeline.staging.stg_order_reviews`
WHERE response_time_days < 0;

-- 6. Response time distribution - eyeball check
-- Known long-tail behavior: most reviews get answered quickly, but a small
-- number take much longer (observed max: 518 days)
SELECT
    MIN(response_time_days)             AS min_response_time,
    ROUND(AVG(response_time_days), 1)   AS avg_response_time,
    MAX(response_time_days)             AS max_response_time,
    COUNTIF(response_time_days > 60)    AS over_60_days,
    COUNTIF(response_time_days > 180)   AS over_180_days
FROM `ai-bi-pipeline.staging.stg_order_reviews`;

-- 7. Distinct scores - eyeball check for unexpected values
SELECT score, COUNT(*) AS review_count
FROM `ai-bi-pipeline.staging.stg_order_reviews`
GROUP BY score
ORDER BY score;