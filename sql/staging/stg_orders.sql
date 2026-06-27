-- =============================================================================
-- stg_orders.sql
-- Staging view for raw_olist.orders
--
-- Transformations applied:
--   - Renamed columns to remove redundant "order_" prefix where appropriate
--   - Retained all 8 source columns
--   - Cast timestamps to DATE for delivery date fields (time component not needed)
--   - Kept purchase and approved timestamps as TIMESTAMP (time matters for SLA)
--   - Standardized order_status to UPPER for consistency
--   - Flagged late deliveries as a derived boolean column
-- =============================================================================

CREATE OR REPLACE VIEW `ai-bi-pipeline.staging.stg_orders` AS

SELECT
    -- Keys
    order_id,
    customer_id,

    -- Status
    UPPER(TRIM(order_status))                           AS order_status,

    -- Timestamps where time of day matters
    order_purchase_timestamp                            AS purchased_at,
    order_approved_at                                   AS approved_at,

    -- Timestamps where only the date matters
    DATE(order_delivered_carrier_date)                  AS delivered_to_carrier_date,
    DATE(order_delivered_customer_date)                 AS delivered_to_customer_date,
    DATE(order_estimated_delivery_date)                 AS estimated_delivery_date,

    -- Derived columns
    CASE
        WHEN order_delivered_customer_date IS NOT NULL
            AND order_estimated_delivery_date IS NOT NULL
            AND DATE(order_delivered_customer_date) > DATE(order_estimated_delivery_date)
        THEN TRUE
        ELSE FALSE
    END                                                 AS is_late_delivery

FROM `ai-bi-pipeline.raw_olist.orders`;