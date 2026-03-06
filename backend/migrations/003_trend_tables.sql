-- TrendLens Trend Data Collection
-- Migration: 003_trend_tables
-- Date: 2026-02-26
-- Adds: trend_keywords, topic_trend_links, trend_data tables
--        + heat_history enhancement + RPC functions + RLS

-- ============================================================
-- 1. trend_keywords — Trend Search Keywords
-- ============================================================

CREATE TABLE trend_keywords (
    keyword_id      TEXT PRIMARY KEY,
    keyword         TEXT NOT NULL,
    language        TEXT NOT NULL DEFAULT 'zh',
    source          TEXT NOT NULL DEFAULT 'llm',
    embedding       vector(512),
    last_queried_at TIMESTAMPTZ,
    query_hit_rate  REAL NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_trend_keywords_active ON trend_keywords(is_active, last_queried_at ASC NULLS FIRST);
CREATE INDEX idx_trend_keywords_embedding ON trend_keywords
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64)
    WHERE embedding IS NOT NULL;

-- ============================================================
-- 2. topic_trend_links — Topic-Keyword Many-to-Many
-- ============================================================

CREATE TABLE topic_trend_links (
    topic_key       TEXT NOT NULL REFERENCES topics(topic_key) ON DELETE CASCADE,
    keyword_id      TEXT NOT NULL REFERENCES trend_keywords(keyword_id) ON DELETE CASCADE,
    relevance       REAL NOT NULL DEFAULT 1.0,
    source          TEXT NOT NULL DEFAULT 'llm',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    PRIMARY KEY (topic_key, keyword_id)
);

CREATE INDEX idx_topic_trend_links_keyword ON topic_trend_links(keyword_id);

-- ============================================================
-- 3. trend_data — Trend Time Series
-- ============================================================

CREATE TABLE trend_data (
    id              BIGSERIAL PRIMARY KEY,
    keyword_id      TEXT NOT NULL REFERENCES trend_keywords(keyword_id) ON DELETE CASCADE,
    timestamp       TIMESTAMPTZ NOT NULL,
    value           INT NOT NULL,
    data_source     TEXT NOT NULL DEFAULT 'google_trends',
    resolution      TEXT NOT NULL DEFAULT 'hourly',
    geo             TEXT NOT NULL DEFAULT '',

    UNIQUE (keyword_id, timestamp, data_source, geo)
);

CREATE INDEX idx_trend_data_keyword_time ON trend_data(keyword_id, timestamp DESC);

-- ============================================================
-- 4. heat_history enhancement — raw_heat_value
-- ============================================================

ALTER TABLE heat_history ADD COLUMN IF NOT EXISTS raw_heat_value TEXT;

-- ============================================================
-- 5. RPC Functions
-- ============================================================

-- Get all trend data for a topic (iOS single-call query)
CREATE OR REPLACE FUNCTION get_topic_trend_data(
    p_topic_key TEXT,
    p_since TIMESTAMPTZ DEFAULT NOW() - INTERVAL '7 days'
)
RETURNS TABLE (
    keyword TEXT,
    relevance REAL,
    "timestamp" TIMESTAMPTZ,
    value INT,
    data_source TEXT,
    resolution TEXT,
    geo TEXT
) LANGUAGE sql STABLE AS $$
    SELECT
        tk.keyword,
        ttl.relevance,
        td."timestamp",
        td.value,
        td.data_source,
        td.resolution,
        td.geo
    FROM topic_trend_links ttl
    JOIN trend_keywords tk ON tk.keyword_id = ttl.keyword_id
    JOIN trend_data td ON td.keyword_id = ttl.keyword_id
    WHERE ttl.topic_key = p_topic_key
      AND td."timestamp" >= p_since
    ORDER BY td."timestamp" DESC;
$$;

-- Find similar keywords by embedding (pgvector dedup)
CREATE OR REPLACE FUNCTION find_similar_keywords(
    p_embedding vector(512),
    p_threshold REAL DEFAULT 0.85,
    p_count INT DEFAULT 5
)
RETURNS TABLE (
    keyword_id TEXT,
    keyword TEXT,
    similarity REAL
) LANGUAGE sql STABLE AS $$
    SELECT
        tk.keyword_id,
        tk.keyword,
        (1 - (tk.embedding <=> p_embedding))::REAL AS similarity
    FROM trend_keywords tk
    WHERE tk.embedding IS NOT NULL
      AND tk.is_active = TRUE
      AND (1 - (tk.embedding <=> p_embedding)) >= p_threshold
    ORDER BY tk.embedding <=> p_embedding
    LIMIT p_count;
$$;

-- Downsample trend_data older than N days (keep one per day per keyword)
CREATE OR REPLACE FUNCTION downsample_trend_data(p_older_than_days INT DEFAULT 7)
RETURNS INT LANGUAGE plpgsql AS $$
DECLARE
    deleted_count INT;
BEGIN
    DELETE FROM trend_data
    WHERE "timestamp" < NOW() - (p_older_than_days || ' days')::INTERVAL
      AND id NOT IN (
        SELECT DISTINCT ON (keyword_id, date_trunc('day', "timestamp"), data_source, geo)
            id
        FROM trend_data
        WHERE "timestamp" < NOW() - (p_older_than_days || ' days')::INTERVAL
        ORDER BY keyword_id, date_trunc('day', "timestamp"), data_source, geo, "timestamp"
      );
    GET DIAGNOSTICS deleted_count = ROW_COUNT;
    RETURN deleted_count;
END;
$$;

-- ============================================================
-- 6. Row Level Security
-- ============================================================

ALTER TABLE trend_keywords ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_trend_links ENABLE ROW LEVEL SECURITY;
ALTER TABLE trend_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY "anon_read_trend_keywords" ON trend_keywords
    FOR SELECT TO anon USING (true);

CREATE POLICY "anon_read_topic_trend_links" ON topic_trend_links
    FOR SELECT TO anon USING (true);

CREATE POLICY "anon_read_trend_data" ON trend_data
    FOR SELECT TO anon USING (true);

-- ============================================================
-- Done. Trend data collection tables ready.
-- ============================================================
