-- =============================================================================
-- fact_order_payments.sql
-- Fact table for the warehouse layer
--
-- Grain: one row per payment (order_id + payment_sequence_number)
--
-- Design notes:
--   - Kept as its own fact, separate from fact_order_items: an order's line
--     items and its payments vary independently (a multi-item order can
--     have one payment; a single-item order can be split across several
--     installments), so joining payments directly to order_items would fan
--     out payment_value once per line item and inflate totals
--   - order_date_key resolves via the order's purchase date, same pattern
--     as fact_order_items, so the two facts stay comparable on the same
--     conformed date dimension
--   - Materialized as a TABLE: facts are periodically refreshed snapshots,
--     not live-recomputed on every query like staging views
-- =============================================================================

CREATE OR REPLACE TABLE `ai-bi-pipeline.warehouse.fact_order_payments` AS

SELECT
    -- Degenerate dimensions
    op.order_id,
    op.payment_sequence_number,
    op.payment_type,

    -- Dimension keys
    c.customer_unique_id,
    CAST(FORMAT_DATE('%Y%m%d', DATE(o.purchased_at)) AS INT64)   AS order_date_key,

    -- Measures
    op.payment_installments,
    op.payment_value

FROM `ai-bi-pipeline.staging.stg_order_payments` op
JOIN `ai-bi-pipeline.staging.stg_orders` o
    ON op.order_id = o.order_id
JOIN `ai-bi-pipeline.staging.stg_customers` c
    ON o.customer_id = c.customer_id;