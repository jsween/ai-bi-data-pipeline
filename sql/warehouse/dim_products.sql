-- =============================================================================
-- dim_products.sql
-- Product dimension for the warehouse layer
--
-- Design notes:
--   - Straight materialization of stg_products - grain and columns already
--     match what a dimension needs, no further transformation required
--   - Materialized as a TABLE: dimensions are periodically refreshed
--     snapshots, not live-recomputed on every query like staging views
-- =============================================================================

CREATE OR REPLACE TABLE `ai-bi-pipeline.warehouse.dim_products` AS

SELECT
    product_id,
    category_name,
    product_name_length,
    product_description_length,
    photos_qty,
    weight_g,
    length_cm,
    height_cm,
    width_cm

FROM `ai-bi-pipeline.staging.stg_products`;