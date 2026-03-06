-- TrendLens Trend Data Array Redesign
-- Migration: 004_trend_data_array
-- Date: 2026-02-27
-- Changes: trend_data from per-point rows to per-keyword array rows
--          (timestamps[] + trend_values[] reduce row count ~100x)

-- ============================================================
-- 1. Drop old trend_data table and recreate with array columns
-- ============================================================

DROP TABLE IF EXISTS trend_data;

CREATE TABLE trend_data (
    keyword_id   TEXT NOT NULL REFERENCES trend_keywords(keyword_id) ON DELETE CASCADE,
    data_source  TEXT NOT NULL DEFAULT 'google_trends',
    resolution   TEXT NOT NULL DEFAULT 'hourly',
    geo          TEXT NOT NULL DEFAULT '',
    timestamps   TIMESTAMPTZ[] NOT NULL DEFAULT '{}',
    trend_values INT[] NOT NULL DEFAULT '{}',
    queried_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (keyword_id, data_source, resolution, geo)
);

CREATE INDEX idx_trend_data_queried ON trend_data(queried_at DESC);

-- ============================================================
-- 2. Replace RPC function (returns array columns directly)
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
      AND tk.is_active = TRUE
      AND td.queried_at >= p_since;
$$;

-- ============================================================
-- 3. Drop old downsample function (no longer needed)
-- ============================================================

DROP FUNCTION IF EXISTS downsample_trend_data(INT);

-- ============================================================
-- 4. RLS (recreate for new table)
-- ============================================================

ALTER TABLE trend_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_read_trend_data" ON trend_data
    FOR SELECT TO anon USING (true);

-- ============================================================
-- Done. trend_data now stores one row per keyword per source.
-- ============================================================
