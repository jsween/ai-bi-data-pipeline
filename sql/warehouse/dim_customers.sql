-- =============================================================================
-- dim_customers.sql
-- Customer dimension for the warehouse layer
--
-- Design notes:
--   - Grain is customer_unique_id, NOT customer_id. In the Olist source data,
--     customer_id is generated per-order; customer_unique_id is the durable
--     identity for a real person across repeat orders. Building this at the
--     customer_id grain would make every customer look like a one-time buyer.
--   - A person can have multiple customer_id rows (one per order) with
--     potentially different addresses. We pick the address from their most
--     recent order as the canonical one.
--   - Enriched with lat/lng from stg_geolocation (joined on zip_code_prefix)
--     for geographic/map analysis in the BI layer.
--   - Materialized as a TABLE: dimensions are periodically refreshed
--     snapshots, not live-recomputed on every query like staging views.
-- =============================================================================

CREATE OR REPLACE TABLE `ai-bi-pipeline.warehouse.dim_customers` AS

WITH customer_orders AS (
    SELECT
        c.customer_unique_id,
        c.city,
        c.state,
        c.zip_code_prefix,
        o.purchased_at,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_unique_id
            ORDER BY o.purchased_at DESC
        ) AS rn
    FROM `ai-bi-pipeline.staging.stg_customers` c
    JOIN `ai-bi-pipeline.staging.stg_orders` o
        ON c.customer_id = o.customer_id
),

most_recent_address AS (
    SELECT
        customer_unique_id,
        city,
        state,
        zip_code_prefix
    FROM customer_orders
    WHERE rn = 1
)

SELECT
    a.customer_unique_id,
    a.city,
    a.state,
    a.zip_code_prefix,
    g.lat,
    g.lng

FROM most_recent_address a
LEFT JOIN `ai-bi-pipeline.staging.stg_geolocation` g
    ON a.zip_code_prefix = g.zip_code_prefix;