-- =============================================================================
-- rpt_order_items_summary_tests.sql
-- Quality checks for reporting.rpt_order_items_summary
-- All checks should return 0 or TRUE to pass
-- =============================================================================

-- 1. Row count parity with fact_order_items
-- (all joins are on keys already validated as complete in the warehouse-layer
-- tests, so an inner join here should neither drop nor fan out rows)
WITH fact_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.warehouse.fact_order_items`
),
rpt_count AS (
    SELECT COUNT(*) AS row_count
    FROM `ai-bi-pipeline.reporting.rpt_order_items_summary`
)
SELECT
    fact_count.row_count                     AS fact_row_count,
    rpt_count.row_count                      AS rpt_row_count,
    fact_count.row_count = rpt_count.row_count AS counts_match
FROM fact_count, rpt_count;

-- 2. No null keys
SELECT COUNT(*) AS null_keys
FROM `ai-bi-pipeline.reporting.rpt_order_items_summary`
WHERE order_id IS NULL
   OR customer_unique_id IS NULL
   OR product_id IS NULL
   OR seller_id IS NULL;

-- 3. total_amount equals price + freight_value (sanity check the join
-- didn't corrupt the underlying measures)
SELECT COUNT(*) AS bad_total_amounts
FROM `ai-bi-pipeline.reporting.rpt_order_items_summary`
WHERE ROUND(total_amount, 2) != ROUND(price + freight_value, 2);