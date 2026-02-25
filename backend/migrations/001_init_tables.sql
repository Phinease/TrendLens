-- TrendLens Database Schema v1
-- Migration: 001_init_tables
-- Date: 2026-02-25
-- Ref: backend/docs/data-storage-strategy.md

-- ============================================================
-- 0. Extensions
-- ============================================================

CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================
-- 1. platforms — Platform Configuration
-- ============================================================

CREATE TABLE platforms (
    id              TEXT PRIMARY KEY,
    display_name    TEXT NOT NULL,
    display_name_en TEXT,
    category        TEXT NOT NULL,
    priority        TEXT NOT NULL DEFAULT 'P0',
    icon_name       TEXT,
    color_hex       TEXT,
    fetch_interval  INT NOT NULL DEFAULT 15,
    enabled         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Seed P0 platforms
INSERT INTO platforms (id, display_name, display_name_en, category, priority, color_hex) VALUES
    ('zhihu',           '知乎',       'Zhihu',           'domestic', 'P0', '#0066FF'),
    ('baidu',           '百度',       'Baidu',           'domestic', 'P0', '#3388FF'),
    ('weibo',           '微博',       'Weibo',           'domestic', 'P0', '#FF6B35'),
    ('bilibili-hs',     'B站热搜',    'Bilibili Search', 'domestic', 'P0', '#00A1D6'),
    ('bilibili-hv',     'B站热门',    'Bilibili Videos', 'domestic', 'P0', '#00A1D6'),
    ('douyin',          '抖音',       'Douyin',          'domestic', 'P0', '#000000'),
    ('toutiao',         '今日头条',    'Toutiao',         'domestic', 'P0', '#FF0000');

-- Seed P1 platforms
INSERT INTO platforms (id, display_name, display_name_en, category, priority, color_hex) VALUES
    ('sina-news',       '新浪新闻',    'Sina News',       'domestic', 'P1', '#D32029'),
    ('thepaper',        '澎湃新闻',    'The Paper',       'domestic', 'P1', '#1A1A1A'),
    ('tencent-hot',     '腾讯新闻',    'Tencent News',    'domestic', 'P1', '#0052D9'),
    ('hackernews',      'Hacker News', 'Hacker News',     'tech',     'P1', '#FF6600'),
    ('36kr-renqi',      '36氪',       '36Kr',            'tech',     'P1', '#0A7AFF'),
    ('douban',          '豆瓣',       'Douban',          'domestic', 'P1', '#007722');

-- Seed P2 platforms
INSERT INTO platforms (id, display_name, display_name_en, category, priority, color_hex) VALUES
    ('wallstreetcn-hot', '华尔街见闻',  'WallStreetCN',    'finance',       'P2', '#0055FF'),
    ('cankaoxiaoxi',     '参考消息',    'Reference News',  'international', 'P2', '#CC0000'),
    ('github-trending',  'GitHub',     'GitHub Trending', 'tech',          'P2', '#333333'),
    ('netease-news',     '网易新闻',    'NetEase News',    'domestic',      'P2', '#CC0000'),
    ('tieba',            '百度贴吧',    'Tieba',           'domestic',      'P2', '#4479BD'),
    ('ithome',           'IT之家',     'IT Home',         'tech',          'P2', '#D32F2F'),
    ('kaopu',            '靠谱新闻',    'Kaopu News',      'international', 'P2', '#2196F3');

-- ============================================================
-- 2. event_clusters — Cross-platform Event Clusters
--    (created before topics due to FK reference)
-- ============================================================

CREATE TABLE event_clusters (
    cluster_id      TEXT PRIMARY KEY,
    title           TEXT NOT NULL,
    keywords        TEXT[],
    platform_count  INT NOT NULL DEFAULT 0,
    topic_count     INT NOT NULL DEFAULT 0,
    max_heat        INT NOT NULL DEFAULT 0,
    first_seen_at   TIMESTAMPTZ NOT NULL,
    last_updated_at TIMESTAMPTZ NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_clusters_active ON event_clusters(is_active, max_heat DESC);

-- ============================================================
-- 3. topics — Topic Main Table (UPSERT target)
-- ============================================================

CREATE TABLE topics (
    topic_key       TEXT PRIMARY KEY,
    platform_id     TEXT NOT NULL REFERENCES platforms(id),
    source_id       TEXT,

    title           TEXT NOT NULL,
    description     TEXT,
    content         TEXT,
    summary         TEXT,
    link            TEXT,
    image_urls      TEXT[],
    tags            TEXT[],

    heat_value      INT,
    raw_heat_value  TEXT,
    rank            INT,
    rank_change     JSONB,

    cluster_id      TEXT REFERENCES event_clusters(cluster_id),
    entities        TEXT[],

    first_seen_at   TIMESTAMPTZ NOT NULL,
    last_seen_at    TIMESTAMPTZ NOT NULL,
    fetched_at      TIMESTAMPTZ NOT NULL,
    is_on_list      BOOLEAN NOT NULL DEFAULT TRUE,

    schema_version  INT NOT NULL DEFAULT 1,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_topics_platform_onlist ON topics(platform_id, is_on_list);
CREATE INDEX idx_topics_platform_rank ON topics(platform_id, rank) WHERE is_on_list = TRUE;
CREATE INDEX idx_topics_cluster ON topics(cluster_id) WHERE cluster_id IS NOT NULL;
CREATE INDEX idx_topics_last_seen ON topics(last_seen_at);
CREATE INDEX idx_topics_entities ON topics USING GIN(entities);

-- ============================================================
-- 4. heat_history — Heat Value Time Series
-- ============================================================

CREATE TABLE heat_history (
    id              BIGSERIAL PRIMARY KEY,
    topic_key       TEXT NOT NULL REFERENCES topics(topic_key) ON DELETE CASCADE,
    timestamp       TIMESTAMPTZ NOT NULL,
    heat_value      INT,
    rank            INT,

    UNIQUE(topic_key, timestamp)
);

CREATE INDEX idx_heat_history_topic_time ON heat_history(topic_key, timestamp DESC);

-- ============================================================
-- 5. topic_embeddings — Vector Embeddings (pgvector)
-- ============================================================

CREATE TABLE topic_embeddings (
    topic_key       TEXT PRIMARY KEY REFERENCES topics(topic_key) ON DELETE CASCADE,
    embedding       vector(512) NOT NULL,
    model_version   TEXT NOT NULL DEFAULT 'jina-embeddings-v3',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_embeddings_hnsw ON topic_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- ============================================================
-- 6. snapshots_meta — Snapshot Audit Log
-- ============================================================

CREATE TABLE snapshots_meta (
    id              TEXT PRIMARY KEY,
    platform_id     TEXT NOT NULL REFERENCES platforms(id),
    fetched_at      TIMESTAMPTZ NOT NULL,
    topic_count     INT NOT NULL,
    new_topic_count INT NOT NULL DEFAULT 0,
    content_hash    TEXT,
    fetch_duration  INT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_snapshots_platform_time ON snapshots_meta(platform_id, fetched_at DESC);

-- ============================================================
-- 7. Row Level Security
-- ============================================================

-- Enable RLS on all tables
ALTER TABLE platforms ENABLE ROW LEVEL SECURITY;
ALTER TABLE topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE heat_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_clusters ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE snapshots_meta ENABLE ROW LEVEL SECURITY;

-- iOS client: read-only via anon role
CREATE POLICY "anon_read_platforms" ON platforms
    FOR SELECT TO anon USING (true);

CREATE POLICY "anon_read_topics" ON topics
    FOR SELECT TO anon USING (true);

CREATE POLICY "anon_read_heat_history" ON heat_history
    FOR SELECT TO anon USING (true);

CREATE POLICY "anon_read_clusters" ON event_clusters
    FOR SELECT TO anon USING (true);

-- topic_embeddings: no anon policy (backend only)
-- snapshots_meta: no anon policy (backend only)

-- ============================================================
-- Done. pg_cron maintenance jobs in 002_cron_jobs.sql
-- ============================================================
