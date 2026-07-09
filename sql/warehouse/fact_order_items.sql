-- =============================================================================
-- fact_order_items.sql
-- Fact table for the warehouse layer
--
-- Grain: one row per order line item (order_id + item_sequence_number)
--
-- Design notes:
--   - order_status and is_late_delivery are order-level attributes,
--     denormalized down to item grain as degenerate dimensions rather than
--     snowflaking out a separate order dimension
--   - order_date_key resolves to dim_date via the order's purchase date.
--     Other dates (approved_at, delivered/estimated dates, shipping_limit_date)
--     are kept as plain DATE/TIMESTAMP columns rather than additional
--     dim_date joins - BI tools can filter on them directly without needing
--     calendar attributes, and role-playing every date through dim_date
--     would add joins without adding analytical value here
--   - customer_unique_id resolves the order's customer_id through
--     stg_customers to the durable person-level identity used by dim_customers
--   - Payments and reviews are intentionally excluded - they're order-grain,
--     not item-grain, and belong in their own fact tables (see
--     fact_order_payments.sql, fact_reviews.sql)
--   - Materialized as a TABLE: facts are periodically refreshed snapshots,
--     not live-recomputed on every query like staging views
-- =============================================================================

CREATE OR REPLACE TABLE `ai-bi-pipeline.warehouse.fact_order_items` AS

SELECT
    -- Degenerate dimensions
    oi.order_id,
    oi.item_sequence_number,
    o.order_status,
    o.is_late_delivery,

    -- Dimension keys
    oi.product_id,
    oi.seller_id,
    c.customer_unique_id,
    CAST(FORMAT_DATE('%Y%m%d', DATE(o.purchased_at)) AS INT64)   AS order_date_key,

    -- Order/item dates kept as plain columns (see design notes above)
    o.purchased_at,
    o.approved_at,
    o.delivered_to_carrier_date,
    o.delivered_to_customer_date,
    o.estimated_delivery_date,
    oi.shipping_limit_date,

    -- Measures
    oi.price,
    oi.freight_value,
    oi.total_amount

FROM `ai-bi-pipeline.staging.stg_order_items` oi
JOIN `ai-bi-pipeline.staging.stg_orders` o
    ON oi.order_id = o.order_id
JOIN `ai-bi-pipeline.staging.stg_customers` c
    ON o.customer_id = c.customer_id;