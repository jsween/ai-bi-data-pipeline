-- =============================================================================
-- fact_reviews.sql
-- Fact table for the warehouse layer
--
-- Grain: one row per review (review_id / order_id pair - a small number of
-- review_ids repeat across different orders in the source data; see
-- stg_order_reviews_tests.sql check #3)
--
-- Design notes:
--   - Kept as its own fact for the same fan-out reason as payments: reviews
--     are order-grain, not item-grain
--   - review_date_key resolves via the review's created_date, not the
--     order's purchase date, since that's the natural time dimension for
--     review-volume and response-time analysis
--   - Materialized as a TABLE: facts are periodically refreshed snapshots,
--     not live-recomputed on every query like staging views
-- =============================================================================

CREATE OR REPLACE TABLE `ai-bi-pipeline.warehouse.fact_reviews` AS

SELECT
    -- Degenerate dimensions
    r.review_id,
    r.order_id,

    -- Dimension keys
    c.customer_unique_id,
    CAST(FORMAT_DATE('%Y%m%d', r.created_date) AS INT64)   AS review_date_key,

    -- Attributes / measures
    r.score,
    r.comment_title,
    r.comment_message,
    r.created_date,
    r.answered_at,
    r.response_time_days

FROM `ai-bi-pipeline.staging.stg_order_reviews` r
JOIN `ai-bi-pipeline.staging.stg_orders` o
    ON r.order_id = o.order_id
JOIN `ai-bi-pipeline.staging.stg_customers` c
    ON o.customer_id = c.customer_id;