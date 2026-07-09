-- =============================================================================
-- rpt_order_items_summary.sql
-- Flat, pre-joined reporting view for BI tools (Looker Studio, Power BI,
-- Metabase) - denormalizes fact_order_items with all of its dimensions so
-- BI tools don't need to blend/join multiple tables themselves.
--
-- Design notes:
--   - Materialized as a VIEW, not a TABLE: always reflects the current state
--     of the underlying warehouse tables with no separate refresh step
--   - city/state/zip/lat/lng are prefixed customer_/seller_ since both
--     dim_customers and dim_sellers contribute columns with the same names
--   - Review data is intentionally excluded - fact_reviews is order-grain,
--     and joining it here would fan review scores out across every line
--     item in a multi-item order. Point BI tools at fact_reviews directly
--     for review-related charts.
-- =============================================================================

CREATE OR REPLACE VIEW `ai-bi-pipeline.reporting.rpt_order_items_summary` AS

SELECT
    -- Order / item identifiers
    f.order_id,
    f.item_sequence_number,
    f.order_status,
    f.is_late_delivery,

    -- Dates
    f.purchased_at,
    f.approved_at,
    f.delivered_to_carrier_date,
    f.delivered_to_customer_date,
    f.estimated_delivery_date,
    f.shipping_limit_date,
    d.year          AS order_year,
    d.quarter       AS order_quarter,
    d.month         AS order_month,
    d.month_name    AS order_month_name,
    d.day_name      AS order_day_name,
    d.is_weekend    AS order_is_weekend,

    -- Customer
    cu.customer_unique_id,
    cu.city             AS customer_city,
    cu.state            AS customer_state,
    cu.zip_code_prefix  AS customer_zip_code_prefix,
    cu.lat              AS customer_lat,
    cu.lng              AS customer_lng,

    -- Product
    p.product_id,
    p.category_name     AS product_category,
    p.weight_g,
    p.length_cm,
    p.height_cm,
    p.width_cm,

    -- Seller
    s.seller_id,
    s.city              AS seller_city,
    s.state             AS seller_state,
    s.zip_code_prefix    AS seller_zip_code_prefix,
    s.lat               AS seller_lat,
    s.lng               AS seller_lng,

    -- Measures
    f.price,
    f.freight_value,
    f.total_amount

FROM `ai-bi-pipeline.warehouse.fact_order_items` f
JOIN `ai-bi-pipeline.warehouse.dim_date` d
    ON f.order_date_key = d.date_key
JOIN `ai-bi-pipeline.warehouse.dim_customers` cu
    ON f.customer_unique_id = cu.customer_unique_id
JOIN `ai-bi-pipeline.warehouse.dim_products` p
    ON f.product_id = p.product_id
JOIN `ai-bi-pipeline.warehouse.dim_sellers` s
    ON f.seller_id = s.seller_id;