-- =============================================================================
-- stg_order_items.sql
-- Staging view for raw_olist.order_items
--
-- Transformations applied:
--   - Kept all foreign keys as-is (order_id, product_id, seller_id)
--   - Renamed order_item_id to item_sequence_number for clarity
--   - Cast shipping_limit_date to DATE (time component not needed)
--   - Rounded price and freight_value to 2 decimal places
--   - Added total_amount as a derived column (price + freight_value)
-- =============================================================================

CREATE OR REPLACE VIEW `ai-bi-pipeline.staging.stg_order_items` AS

SELECT
    -- Keys
    order_id,
    order_item_id                                       AS item_sequence_number,
    product_id,
    seller_id,

    -- Shipping
    DATE(shipping_limit_date)                           AS shipping_limit_date,

    -- Financials
    ROUND(price, 2)                                     AS price,
    ROUND(freight_value, 2)                             AS freight_value,

    -- Derived
    ROUND(price + freight_value, 2)                     AS total_amount

FROM `ai-bi-pipeline.raw_olist.order_items`