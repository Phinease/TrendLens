-- TrendLens: Trend Keyword Cleanup Strategy
-- Migration: 004_trend_keyword_cleanup
-- Date: 2026-03-27
-- Adds: query_miss_streak, no_trend_data columns to trend_keywords
--        + cleanup sparse/empty trend data
--        + update get_keywords_needing_query filter

-- ============================================================
-- 1. Add columns to trend_keywords
-- ============================================================

-- Consecutive successful queries that returned zero data points.
-- Reset to 0 when a query returns data. NOT incremented on network errors.
ALTER TABLE trend_keywords
    ADD COLUMN IF NOT EXISTS query_miss_streak INT NOT NULL DEFAULT 0;

-- Permanently marks keywords confirmed to have no Google Trends data.
-- Once TRUE, the keyword is never queried again.
ALTER TABLE trend_keywords
    ADD COLUMN IF NOT EXISTS no_trend_data BOOLEAN NOT NULL DEFAULT FALSE;

-- Index: skip no_trend_data keywords in queue queries
CREATE INDEX IF NOT EXISTS idx_trend_keywords_queryable
    ON trend_keywords (is_active, no_trend_data, last_queried_at ASC NULLS FIRST)
    WHERE is_active = TRUE AND no_trend_data = FALSE;

-- ============================================================
-- 2. Backfill: mark existing keywords with confirmed no data
-- ============================================================

-- Keywords that have been queried (last_queried_at IS NOT NULL),
-- have hit_rate = 0, and have no trend_data rows → confirmed no data.
UPDATE trend_keywords tk
SET no_trend_data = TRUE,
    query_miss_streak = 2
WHERE tk.is_active = TRUE
  AND tk.last_queried_at IS NOT NULL
  AND tk.query_hit_rate = 0
  AND NOT EXISTS (
      SELECT 1 FROM trend_data td WHERE td.keyword_id = tk.keyword_id
  );

-- ============================================================
-- 3. Clean up sparse trend_data (≤ 3 data points out of 168h)
-- ============================================================

-- Delete trend_data rows where the time series has ≤ 3 points
-- (less than 2% coverage of a 7-day hourly window — not useful)
DELETE FROM trend_data
WHERE array_length(timestamps, 1) IS NULL
   OR array_length(timestamps, 1) <= 3;

-- Mark keywords whose trend_data was just deleted as no_trend_data
-- (they had data but it was too sparse to be useful)
UPDATE trend_keywords tk
SET no_trend_data = TRUE,
    query_miss_streak = 2
WHERE tk.is_active = TRUE
  AND tk.last_queried_at IS NOT NULL
  AND NOT EXISTS (
      SELECT 1 FROM trend_data td WHERE td.keyword_id = tk.keyword_id
  )
  AND tk.no_trend_data = FALSE;

-- ============================================================
-- 4. Update RPC: get_topic_trend_data should skip no_trend_data
-- ============================================================

CREATE OR REPLACE FUNCTION get_topic_trend_data(
    p_topic_key TEXT,
    p_since TIMESTAMPTZ DEFAULT NOW() - INTERVAL '7 days'
)
RETURNS TABLE (
    keyword TEXT,
    relevance REAL,
    data_source TEXT,
    resolution TEXT,
    geo TEXT,
    timestamps TIMESTAMPTZ[],
    trend_values INT[],
    queried_at TIMESTAMPTZ
) LANGUAGE sql STABLE AS $$
    SELECT
        tk.keyword,
        ttl.relevance,
        td.data_source,
        td.resolution,
        td.geo,
        td.timestamps,
        td.trend_values,
        td.queried_at
    FROM topic_trend_links ttl
    JOIN trend_keywords tk ON tk.keyword_id = ttl.keyword_id
    JOIN trend_data td ON td.keyword_id = ttl.keyword_id
    WHERE ttl.topic_key = p_topic_key
      AND tk.no_trend_data = FALSE
      AND td.queried_at >= p_since
    ORDER BY td.queried_at DESC;
$$;

-- ============================================================
-- Done.
-- ============================================================
