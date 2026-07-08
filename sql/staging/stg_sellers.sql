-- =============================================================================
-- stg_sellers.sql
-- Staging view for raw_olist.sellers
--
-- Transformations applied:
--   - Removed redundant "seller_" prefix from city and state columns
--   - Kept seller_id as-is (key, prefix is meaningful)
--   - Standardized city to UPPER for consistency
--   - Standardized state to UPPER (should already be, but enforced)
--   - Cast zip_code_prefix to STRING (leading zeros matter in zip codes)
-- =============================================================================

CREATE OR REPLACE VIEW `ai-bi-pipeline.staging.stg_sellers` AS
SELECT
    -- Keys
    seller_id,

    -- Location
    UPPER(TRIM(seller_city))                                             AS city,
    UPPER(TRIM(seller_state))                                            AS state,
    LPAD(CAST(seller_zip_code_prefix AS STRING), 5, '0')                 AS zip_code_prefix

FROM `ai-bi-pipeline.raw_olist.sellers`;
