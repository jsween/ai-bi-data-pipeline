-- =============================================================================
-- stg_order_reviews.sql
-- Staging view for raw_olist.order_reviews
--
-- Transformations applied:
--   - Kept review_id and order_id as-is (keys, prefix is meaningful)
--   - Dropped redundant "review_" prefix from score/comment/timestamp columns
--   - Trimmed free-text comment fields (source is lenient-parsed at ingestion
--     due to unescaped quotes/newlines in customer comments)
--   - Cast creation date to DATE (time component not present in source)
--   - Kept answer timestamp as TIMESTAMP (time matters for response SLA)
--   - Added response_time_days as a derived column
-- =============================================================================

CREATE OR REPLACE VIEW `ai-bi-pipeline.staging.stg_order_reviews` AS

SELECT
    -- Keys
    review_id,
    order_id,

    -- Review details
    review_score                                                          AS score,
    TRIM(review_comment_title)                                            AS comment_title,
    TRIM(review_comment_message)                                          AS comment_message,

    -- Timestamps
    DATE(review_creation_date)                                            AS created_date,
    review_answer_timestamp                                               AS answered_at,

    -- Derived
    DATE_DIFF(DATE(review_answer_timestamp), DATE(review_creation_date), DAY)  AS response_time_days

FROM `ai-bi-pipeline.raw_olist.order_reviews`;