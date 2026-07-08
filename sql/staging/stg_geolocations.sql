-- =============================================================================
-- stg_geolocation.sql
-- Staging view for raw_olist.geolocation
--
-- Transformations applied:
--   - Filtered out coordinates falling outside Brazil's bounding box
--     (a small number of source rows have bad geocodes, e.g. (0,0) or points
--     in the ocean/other continents, which would otherwise skew the average)
--   - Grain changed: raw has many lat/lng rows per zip_code_prefix (repeated
--     geocoding hits); staging aggregates to one row per zip_code_prefix
--   - lat/lng collapsed to the average coordinate per zip_code_prefix
--   - city/state collapsed to the most frequently occurring value per
--     zip_code_prefix (a zip prefix can have minor city name variants)
--   - Cast zip_code_prefix to STRING (leading zeros matter in zip codes)
-- =============================================================================

CREATE OR REPLACE VIEW `ai-bi-pipeline.staging.stg_geolocation` AS

WITH cleaned AS (
    SELECT
        LPAD(CAST(geolocation_zip_code_prefix AS STRING), 5, '0')   AS zip_code_prefix,
        geolocation_lat                                             AS lat,
        geolocation_lng                                             AS lng,
        UPPER(TRIM(geolocation_city))                               AS city,
        UPPER(TRIM(geolocation_state))                              AS state
    FROM `ai-bi-pipeline.raw_olist.geolocation`
    -- Brazil's approximate bounding box - drops a handful of bad geocodes
    WHERE geolocation_lat BETWEEN -33.75 AND 5.27
      AND geolocation_lng BETWEEN -73.99 AND -34.79
),

ranked_city_state AS (
    SELECT
        zip_code_prefix,
        city,
        state,
        ROW_NUMBER() OVER (
            PARTITION BY zip_code_prefix
            ORDER BY COUNT(*) DESC
        ) AS rn
    FROM cleaned
    GROUP BY zip_code_prefix, city, state
),

coords AS (
    SELECT
        zip_code_prefix,
        AVG(lat) AS lat,
        AVG(lng) AS lng
    FROM cleaned
    GROUP BY zip_code_prefix
)

SELECT
    coords.zip_code_prefix,
    coords.lat,
    coords.lng,
    ranked_city_state.city,
    ranked_city_state.state

FROM coords
JOIN ranked_city_state
    ON coords.zip_code_prefix = ranked_city_state.zip_code_prefix
   AND ranked_city_state.rn = 1;