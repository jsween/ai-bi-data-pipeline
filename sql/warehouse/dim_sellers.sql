-- =============================================================================
-- dim_sellers.sql
-- Seller dimension for the warehouse layer
--
-- Design notes:
--   - Enriched with lat/lng from stg_geolocation (joined on zip_code_prefix)
--     for geographic/map analysis in the BI layer
--   - stg_geolocation is already unique per zip_code_prefix (aggregated at
--     the staging layer), so this join cannot fan out seller rows
--   - Materialized as a TABLE: dimensions are periodically refreshed
--     snapshots, not live-recomputed on every query like staging views
-- =============================================================================

CREATE OR REPLACE TABLE `ai-bi-pipeline.warehouse.dim_sellers` AS

SELECT
    s.seller_id,
    s.city,
    s.state,
    s.zip_code_prefix,
    g.lat,
    g.lng

FROM `ai-bi-pipeline.staging.stg_sellers` s
LEFT JOIN `ai-bi-pipeline.staging.stg_geolocation` g
    ON s.zip_code_prefix = g.zip_code_prefix;