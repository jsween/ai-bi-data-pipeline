-- =============================================================================
-- dim_date.sql
-- Calendar dimension for the warehouse layer
--
-- Design notes:
--   - Materialized as a TABLE, not a VIEW: this is static reference data
--     generated from a date spine, not derived from a raw source table
--   - date_key is an INT64 in YYYYMMDD format (standard Kimball surrogate key
--     for date dimensions - sortable, human-readable, joins cheaply)
--   - Range covers 2016-01-01 through 2020-12-31: Olist orders run roughly
--     Sept 2016 - Oct 2018, with a buffer on both ends for estimated/shipping
--     dates that can fall slightly outside the order date range
--   - is_weekend uses BigQuery's DAYOFWEEK extract, where 1 = Sunday, 7 = Saturday
-- =============================================================================

CREATE OR REPLACE TABLE `ai-bi-pipeline.warehouse.dim_date` AS

WITH date_spine AS (
    SELECT full_date
    FROM UNNEST(GENERATE_DATE_ARRAY('2016-01-01', '2020-12-31', INTERVAL 1 DAY)) AS full_date
)

SELECT
    CAST(FORMAT_DATE('%Y%m%d', full_date) AS INT64)   AS date_key,
    full_date,
    EXTRACT(YEAR FROM full_date)                        AS year,
    EXTRACT(QUARTER FROM full_date)                     AS quarter,
    EXTRACT(MONTH FROM full_date)                       AS month,
    FORMAT_DATE('%B', full_date)                        AS month_name,
    EXTRACT(DAY FROM full_date)                         AS day_of_month,
    EXTRACT(DAYOFWEEK FROM full_date)                   AS day_of_week,
    FORMAT_DATE('%A', full_date)                        AS day_name,
    EXTRACT(WEEK FROM full_date)                        AS week_of_year,
    EXTRACT(DAYOFWEEK FROM full_date) IN (1, 7)         AS is_weekend

FROM date_spine
ORDER BY full_date;