-- =============================================================================
-- stg_products.sql
-- Staging view for raw_olist.products
--
-- Transformations applied:
--   - Joined to product_category_name_translation to get English category names
--   - Fell back to the raw Portuguese category name if no translation match,
--     then to 'unknown' if the category name itself is null
--   - Fixed misspelled source columns (product_name_lenght -> name_length, etc.)
--   - Dropped redundant "product_" prefix from dimension/weight columns
--   - Left weight/dimension nulls as-is (not fabricating data)
-- =============================================================================

CREATE OR REPLACE VIEW `ai-bi-pipeline.staging.stg_products` AS

SELECT
    -- Keys
    p.product_id,

    -- Category
    COALESCE(t.product_category_name_english, p.product_category_name, 'unknown')  AS category_name,

    -- Descriptive attributes
    p.product_name_lenght                               AS product_name_length,
    p.product_description_lenght                         AS product_description_length,
    p.product_photos_qty                                 AS photos_qty,

    -- Physical dimensions
    p.product_weight_g                                   AS weight_g,
    p.product_length_cm                                  AS length_cm,
    p.product_height_cm                                  AS height_cm,
    p.product_width_cm                                   AS width_cm

FROM `ai-bi-pipeline.raw_olist.products` p
LEFT JOIN `ai-bi-pipeline.raw_olist.product_category_name_translation` t
    ON p.product_category_name = t.product_category_name;