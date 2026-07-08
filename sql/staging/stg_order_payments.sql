-- =============================================================================
-- stg_order_payments.sql
-- Staging view for raw_olist.order_payments
--
-- Transformations applied:
--   - Renamed payment_sequential to payment_sequence_number for clarity
--     (mirrors item_sequence_number in stg_order_items)
--   - Standardized payment_type to UPPER for consistency
--   - Rounded payment_value to 2 decimal places
--   - Grain is unchanged: one row per payment on an order (orders can have
--     multiple payment rows via split payments/installments)
-- =============================================================================

CREATE OR REPLACE VIEW `ai-bi-pipeline.staging.stg_order_payments` AS

SELECT
    -- Keys
    order_id,
    payment_sequential                                   AS payment_sequence_number,

    -- Payment details
    UPPER(TRIM(payment_type))                            AS payment_type,
    payment_installments,

    -- Financials
    ROUND(payment_value, 2)                              AS payment_value

FROM `ai-bi-pipeline.raw_olist.order_payments`;