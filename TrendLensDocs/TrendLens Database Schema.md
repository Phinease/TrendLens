# TrendLens Database Schema

> **定位：** 当前 Supabase 数据库的全量模型速查，面向 iOS 客户端和 Python 后端的开发参考
> **数据库：** Supabase (PostgreSQL 15 + pgvector)
> **设计决策详见：** [data-storage-strategy.md](../backend/docs/data-storage-strategy.md)
> **最后同步：** 2026-03-13（基于线上数据库实际状态）

---

## 一、ER 关系总览

```
platforms ─────────────< topics >?──────── event_clusters
  │  (1:N)                │ (N:1 可空)
  │                       │
  │                       ├────< heat_history        (1:N, CASCADE)
  │                       ├────1 topic_embeddings    (1:1, CASCADE)
  │                       └────< topic_trend_links   (1:N, CASCADE)
  │                                    │
  └──< snapshots_meta                  │
       (1:N)                           │
                              trend_keywords ─────< trend_data
                                (1:N)                (1:N, CASCADE)
```

**外键级联规则：**
- `topics` 删除 → 自动级联删除 `heat_history`、`topic_embeddings`、`topic_trend_links`
- `trend_keywords` 删除 → 自动级联删除 `trend_data`、`topic_trend_links`
- `platforms`、`event_clusters` → 无级联删除（受引用保护）

---

## 二、表结构定义

### 2.1 platforms — 平台配置

| 列 | 类型 | 约束 | 默认值 | 说明 |
|----|------|------|--------|------|
| `id` | TEXT | **PK** | — | 平台标识：`zhihu`, `weibo`, `baidu` 等 |
| `display_name` | TEXT | NOT NULL | — | 中文名 |
| `display_name_en` | TEXT | nullable | — | 英文名 |
| `category` | TEXT | NOT NULL | — | `domestic` / `tech` / `finance` / `international` |
| `priority` | TEXT | NOT NULL | `'P0'` | `P0` / `P1` / `P2` |
| `icon_name` | TEXT | nullable | — | SF Symbol 或自定义图标名 |
| `color_hex` | TEXT | nullable | — | 品牌色 `#FF6B35` |
| `fetch_interval` | INT | NOT NULL | `15` | 采集间隔（分钟） |
| `enabled` | BOOLEAN | NOT NULL | `TRUE` | 是否启用 |
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | — |

**种子数据（20 行）：**
- **P0（7）：** zhihu, baidu, weibo, bilibili-hs, bilibili-hv, douyin, toutiao
- **P1（6）：** sina-news, thepaper, tencent-hot, hackernews, 36kr-renqi, douban
- **P2（7）：** wallstreetcn-hot, cankaoxiaoxi, github-trending, netease-news, tieba, ithome, kaopu

---

### 2.2 topics — 热搜话题主表

| 列 | 类型 | 约束 | 默认值 | 说明 |
|----|------|------|--------|------|
| `topic_key` | TEXT | **PK** | — | `{platform}:{source_id\|url:hash\|title:hash}` |
| `platform_id` | TEXT | NOT NULL, **FK→platforms** | — | 所属平台 |
| `source_id` | TEXT | nullable | — | 平台原生 ID |
| `title` | TEXT | NOT NULL | — | 话题标题 |
| `description` | TEXT | nullable | — | 话题描述 |
| `content` | TEXT | nullable | — | 正文内容（抓取） |
| `summary` | TEXT | nullable | — | AI 摘要 |
| `link` | TEXT | nullable | — | 原文链接 |
| `image_urls` | TEXT[] | nullable | — | 图片 URL 数组 |
| `tags` | TEXT[] | nullable | — | 标签数组 |
| `heat_value` | INT | nullable | — | 归一化热度 0–10,000,000 |
| `raw_heat_value` | TEXT | nullable | — | 原始热度值 |
| `rank` | INT | nullable | — | 当前排名 |
| `rank_change` | JSONB | nullable | — | `{"type":"up","value":3}` |
| `cluster_id` | TEXT | nullable, **FK→event_clusters** | — | 跨平台事件 ID |
| `entities` | TEXT[] | nullable | — | NER 命名实体 |
| `first_seen_at` | TIMESTAMPTZ | NOT NULL | — | 首次上榜 |
| `last_seen_at` | TIMESTAMPTZ | NOT NULL | — | 最近在榜 |
| `fetched_at` | TIMESTAMPTZ | NOT NULL | — | 最新采集时间 |
| `is_on_list` | BOOLEAN | NOT NULL | `TRUE` | 是否当前在榜 |
| `schema_version` | INT | NOT NULL | `1` | — |
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | — |
| `updated_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | — |

**索引：**

| 索引名 | 定义 | 用途 |
|--------|------|------|
| `idx_topics_platform_onlist` | `(platform_id, is_on_list)` | 按平台筛选在榜话题 |
| `idx_topics_platform_rank` | `(platform_id, rank) WHERE is_on_list = TRUE` | 平台热榜排序 |
| `idx_topics_cluster` | `(cluster_id) WHERE cluster_id IS NOT NULL` | 按事件聚类查询 |
| `idx_topics_last_seen` | `(last_seen_at)` | 过期清理 |
| `idx_topics_entities` | `GIN(entities)` | 实体数组重叠查询 |

---

### 2.3 heat_history — 热度时间序列

| 列 | 类型 | 约束 | 默认值 | 说明 |
|----|------|------|--------|------|
| `id` | BIGSERIAL | **PK** | auto | — |
| `topic_key` | TEXT | NOT NULL, **FK→topics** (CASCADE) | — | 话题标识 |
| `timestamp` | TIMESTAMPTZ | NOT NULL, **UNIQUE(topic_key, timestamp)** | — | 采集时间点 |
| `heat_value` | INT | nullable | — | 归一化热度 |
| `rank` | INT | nullable | — | 当时排名 |
| `raw_heat_value` | TEXT | nullable | — | 原始热度值 |

**索引：** `idx_heat_history_topic_time` → `(topic_key, timestamp DESC)`

---

### 2.4 event_clusters — 跨平台事件聚类

| 列 | 类型 | 约束 | 默认值 | 说明 |
|----|------|------|--------|------|
| `cluster_id` | TEXT | **PK** | — | `evt_{timestamp}_{hash}` |
| `title` | TEXT | NOT NULL | — | 代表性标题（最高热度话题） |
| `keywords` | TEXT[] | nullable | — | 共享关键实体 |
| `platform_count` | INT | NOT NULL | `0` | 涉及平台数 |
| `topic_count` | INT | NOT NULL | `0` | 关联话题数 |
| `max_heat` | INT | NOT NULL | `0` | 最高热度（排序用） |
| `first_seen_at` | TIMESTAMPTZ | NOT NULL | — | — |
| `last_updated_at` | TIMESTAMPTZ | NOT NULL | — | — |
| `is_active` | BOOLEAN | NOT NULL | `TRUE` | 是否仍有活跃话题 |
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | — |

**索引：** `idx_clusters_active` → `(is_active, max_heat DESC)`

---

### 2.5 topic_embeddings — 向量嵌入 (pgvector)

| 列 | 类型 | 约束 | 默认值 | 说明 |
|----|------|------|--------|------|
| `topic_key` | TEXT | **PK**, **FK→topics** (CASCADE) | — | — |
| `embedding` | vector(512) | NOT NULL | — | Jina v3 嵌入，512 维 |
| `model_version` | TEXT | NOT NULL | `'jina-embeddings-v3'` | — |
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | — |

**索引：** `idx_embeddings_hnsw` → `HNSW(embedding vector_cosine_ops) WITH (m=16, ef_construction=64)`

---

### 2.6 snapshots_meta — 快照审计日志

| 列 | 类型 | 约束 | 默认值 | 说明 |
|----|------|------|--------|------|
| `id` | TEXT | **PK** | — | `{platform}_{timestamp}` |
| `platform_id` | TEXT | NOT NULL, **FK→platforms** | — | — |
| `fetched_at` | TIMESTAMPTZ | NOT NULL | — | — |
| `topic_count` | INT | NOT NULL | — | 话题总数 |
| `new_topic_count` | INT | NOT NULL | `0` | 新增话题数 |
| `content_hash` | TEXT | nullable | — | 内容哈希（变更检测） |
| `fetch_duration` | INT | nullable | — | 采集耗时（ms） |
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | — |

**索引：** `idx_snapshots_platform_time` → `(platform_id, fetched_at DESC)`

---

### 2.7 trend_keywords — 趋势搜索关键词

| 列 | 类型 | 约束 | 默认值 | 说明 |
|----|------|------|--------|------|
| `keyword_id` | TEXT | **PK** | — | 归一化关键词文本作为 ID |
| `keyword` | TEXT | NOT NULL | — | 显示形式 |
| `language` | TEXT | NOT NULL | `'zh'` | — |
| `source` | TEXT | NOT NULL | `'llm'` | `llm` / `manual` / `entity` |
| `embedding` | vector(512) | nullable | — | Jina 嵌入（去重用） |
| `last_queried_at` | TIMESTAMPTZ | nullable | — | 上次查询 Google Trends |
| `query_hit_rate` | REAL | NOT NULL | `0` | Google Trends 有效数据比率 |
| `is_active` | BOOLEAN | NOT NULL | `TRUE` | — |
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | — |

**索引：**

| 索引名 | 定义 |
|--------|------|
| `idx_trend_keywords_active` | `(is_active, last_queried_at ASC NULLS FIRST)` |
| `idx_trend_keywords_embedding` | `HNSW(embedding vector_cosine_ops) WHERE embedding IS NOT NULL` |

---

### 2.8 topic_trend_links — 话题↔关键词 多对多

| 列 | 类型 | 约束 | 默认值 | 说明 |
|----|------|------|--------|------|
| `topic_key` | TEXT | **PK(1/2)**, **FK→topics** (CASCADE) | — | — |
| `keyword_id` | TEXT | **PK(2/2)**, **FK→trend_keywords** (CASCADE) | — | — |
| `relevance` | REAL | NOT NULL | `1.0` | 相关度 0.0–1.0 |
| `source` | TEXT | NOT NULL | `'llm'` | — |
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | — |

**索引：** `idx_topic_trend_links_keyword` → `(keyword_id)`

---

### 2.9 trend_data — 趋势时间序列（数组模式）

每个 keyword+source+resolution+geo 组合存储**一行**，时序数据以平行数组存储。

| 列 | 类型 | 约束 | 默认值 | 说明 |
|----|------|------|--------|------|
| `keyword_id` | TEXT | **PK(1/4)**, **FK→trend_keywords** (CASCADE) | — | — |
| `data_source` | TEXT | **PK(2/4)** | `'google_trends'` | — |
| `resolution` | TEXT | **PK(3/4)** | `'hourly'` | — |
| `geo` | TEXT | **PK(4/4)** | `''` | `''`=全球, `'CN'`=中国 |
| `timestamps` | TIMESTAMPTZ[] | NOT NULL | `'{}'` | 时间点数组 |
| `trend_values` | INT[] | NOT NULL | `'{}'` | Google Trends 相对值 (0–100) |
| `queried_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | 最近查询时间 |
| `created_at` | TIMESTAMPTZ | NOT NULL | `NOW()` | — |

**索引：** `idx_trend_data_queried` → `(queried_at DESC)`

> `timestamps` 与 `trend_values` 等长、一一对应。相比每个数据点一行，行数减少约 100x。

---

## 三、RPC 函数

### 3.1 get_topic_trend_data — 获取话题关联的趋势数据

iOS 客户端单次调用，穿透 `topic_trend_links → trend_keywords → trend_data` 三表 JOIN。

```sql
get_topic_trend_data(
    p_topic_key  TEXT,
    p_since      TIMESTAMPTZ DEFAULT NOW() - INTERVAL '7 days'
)
RETURNS TABLE (
    keyword       TEXT,
    relevance     REAL,
    data_source   TEXT,
    resolution    TEXT,
    geo           TEXT,
    timestamps    TIMESTAMPTZ[],
    trend_values  INT[],
    queried_at    TIMESTAMPTZ
)
```

**调用示例（Supabase Swift SDK）：**
```swift
let result = try await supabase.rpc("get_topic_trend_data", params: [
    "p_topic_key": topicKey
]).execute()
```

### 3.2 find_similar_keywords — 向量相似关键词查找

后端去重用，基于 pgvector 余弦相似度。

```sql
find_similar_keywords(
    p_embedding   vector(512),
    p_threshold   REAL DEFAULT 0.85,
    p_count       INT DEFAULT 5
)
RETURNS TABLE (
    keyword_id    TEXT,
    keyword       TEXT,
    similarity    REAL
)
```

---

## 四、Row Level Security

所有 9 张表均启用 RLS。

| 表 | anon (iOS) 可读 | 说明 |
|----|:-:|------|
| `platforms` | **SELECT** | 平台列表 |
| `topics` | **SELECT** | 热搜数据 |
| `heat_history` | **SELECT** | 热度曲线 |
| `event_clusters` | **SELECT** | 跨平台事件 |
| `trend_keywords` | **SELECT** | 关键词列表 |
| `topic_trend_links` | **SELECT** | 话题-关键词关联 |
| `trend_data` | **SELECT** | 趋势数据 |
| `topic_embeddings` | — | 仅 service_role |
| `snapshots_meta` | — | 仅 service_role |

Python 后端使用 **service_role key** 绕过 RLS 进行全部读写操作。

---

## 五、iOS 客户端常用查询速查

| 场景 | 查询目标 | Supabase 调用 |
|------|---------|---------------|
| 某平台热榜 | `topics` | `.from("topics").select().eq("platform_id", id).eq("is_on_list", true).order("rank")` |
| 全平台热榜 | `topics` | `.from("topics").select().eq("is_on_list", true).order("heat_value", ascending: false).limit(50)` |
| 话题详情+聚类 | `topics` JOIN `event_clusters` | `.from("topics").select("*, event_clusters(*)").eq("topic_key", key)` |
| 热度曲线 | `heat_history` | `.from("heat_history").select().eq("topic_key", key).order("timestamp", ascending: false).limit(96)` |
| 跨平台事件列表 | `event_clusters` | `.from("event_clusters").select().eq("is_active", true).order("max_heat", ascending: false)` |
| 事件下所有报道 | `topics` | `.from("topics").select().eq("cluster_id", cid).eq("is_on_list", true)` |
| 话题趋势数据 | RPC | `.rpc("get_topic_trend_data", params: ["p_topic_key": key])` |
| 平台列表 | `platforms` | `.from("platforms").select().eq("enabled", true).order("priority")` |

---

## 六、Python 后端写入速查

| 操作 | 表 | 方法 | 说明 |
|------|---|------|------|
| 存储话题 | `topics` | UPSERT on `topic_key` | 存在则更新热度/排名/时间 |
| 记录热度 | `heat_history` | INSERT | 每轮采集追加 |
| 存储嵌入 | `topic_embeddings` | UPSERT on `topic_key` | 新话题生成嵌入 |
| 更新聚类 | `event_clusters` | UPSERT on `cluster_id` | 匹配后更新统计 |
| 分配聚类 | `topics.cluster_id` | UPDATE | 匹配算法结果写回 |
| 快照审计 | `snapshots_meta` | INSERT | 每轮采集记录 |
| 存储关键词 | `trend_keywords` | UPSERT on `keyword_id` | LLM 提取后去重写入 |
| 关联关键词 | `topic_trend_links` | UPSERT on `(topic_key, keyword_id)` | — |
| 存储趋势 | `trend_data` | UPSERT on PK | 数组 append/replace |
| 标记下榜 | `topics.is_on_list` | UPDATE → `FALSE` | 不在本轮结果中的话题 |

---

## 七、数据保留策略摘要

| 数据 | 保留 | 清理方式 |
|------|------|---------|
| topics (在榜) | 永久 | — |
| topics (下榜) | 90 天 | Python 调度器 |
| heat_history (全精度) | 7 天 | Python 调度器 |
| heat_history (降采样:每小时) | 7–90 天 | Python 调度器 |
| event_clusters (非活跃) | 90 天 | Python 调度器 |
| topic_embeddings | 随 topics 级联 | CASCADE |
| snapshots_meta | 14 天 | Python 调度器 |
| trend_data | 数组内管理 | Python 调度器 |
| trend_keywords (无关联) | 30 天后停用 | Python 调度器 |

> pg_cron 不可用（Supabase 免费版），所有清理由 Python 后端每日 03:00 UTC 执行。
