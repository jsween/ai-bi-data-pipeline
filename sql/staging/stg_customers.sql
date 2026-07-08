-- =============================================================================
-- stg_customers.sql
-- Staging view for raw_olist.customers
--
-- Transformations applied:
--   - Removed redundant "customer_" prefix from city and state columns
--   - Kept customer_id and customer_unique_id as-is (keys, prefix is meaningful)
--   - Standardized city to UPPER for consistency
--   - Standardized state to UPPER (should already be, but enforced)
--   - Cast zip_code_prefix to STRING (leading zeros matter in zip codes)
-- =============================================================================

CREATE OR REPLACE VIEW `ai-bi-pipeline.staging.stg_customers`   AS
SELECT
    -- Keys
    customer_id,
    customer_unique_id,

    -- Location
    UPPER(TRIM(customer_city))                                           AS city,
    UPPER(TRIM(customer_state))                                          AS state,
    LPAD(CAST(customer_zip_code_prefix AS STRING), 5, '0')               AS zip_code_prefix

FROM `ai-bi-pipeline.raw_olist.customers`;