# TrendLens 数据存储策略

> **定位：** 数据存储架构、表设计、话题追踪与跨平台关联算法的完整技术规范
> **配套文档：**
> - [data-requirements.md](data-requirements.md) — 数据字段需求与覆盖矩阵
> - [hot-news-data-sources-v2.md](hot-news-data-sources-v2.md) — 数据源接口规范
> **技术栈：** Supabase (PostgreSQL 15 + pgvector) + Python 后端 + Jina Embeddings
> **最后更新：** 2026-02-25

---

## 一、核心原则

### 1.1 设计原则

| 原则 | 说明 |
|------|------|
| **客户端零计算** | iOS 端仅负责查询和展示，所有数据加工（归一化、排名计算、聚类）在存入前完成 |
| **数据不重复** | 结构化数据与向量数据通过外键关联，不在多表存储相同内容 |
| **查询极简** | iOS 端的每个 UI 场景都能用 **单条 SQL**（或 Supabase client 单次调用）完成 |
| **长期稳定** | 算法和表结构需支持数月乃至数年的持续运行，无需人工干预 |
| **可扩展** | 新增数据源、新增平台不需要修改表结构 |

### 1.2 存储分层

| 层 | 存储引擎 | 内容 | 访问者 |
|----|---------|------|--------|
| **结构化数据** | PostgreSQL (Supabase) | 话题、热度历史、事件聚类、平台配置 | iOS 客户端（读）、Python 后端（写） |
| **向量数据** | pgvector (Supabase 内置) | 话题标题嵌入向量 | Python 后端（匹配算法中读写） |
| **审计日志** | PostgreSQL | 快照元数据 | Python 后端（调试用） |

> **关键决策：** 向量数据存储在独立表 `topic_embeddings` 中，通过外键 `topic_key` 关联到 `topics` 表。
> 原因：iOS 客户端永远不需要读取向量数据，分表避免常规查询加载无用的 embedding 列。

---

## 二、话题身份标识策略（Topic Identity）

### 2.1 问题定义

每 15 分钟采集一次热榜，同一话题可能出现在多次采集中，但热度值、排名会变化。需要一个稳定的标识符将跨快照的同一话题关联起来，以支持：
- 热度时间序列积累（`heat_history`）
- 排名变化计算（`rank_change`）
- 话题生命周期追踪

### 2.2 方案：混合优先级 topic_key

采用 **三级降级策略** 生成 `topic_key`：

```
优先级 1：平台原生 ID（最稳定）
  topic_key = "{platform}:{source_id}"

优先级 2：规范化链接（次稳定）
  topic_key = "{platform}:url:{normalize(link)}"

优先级 3：标题哈希（兜底）
  topic_key = "{platform}:title:{sha256(normalize(title))[:16]}"
```

### 2.3 各数据源 topic_key 生成规则

| 源 ID | 优先级 | source_id 来源 | 示例 |
|-------|--------|---------------|------|
| `zhihu` | 1 | URL 中提取 question ID | `zhihu:question:12345678` |
| `baidu` | 1 | `word` 字段（关键词） | `baidu:word:特朗普访华` |
| `weibo` | 3 | 无稳定 ID，用标题哈希 | `weibo:title:a3f8b2c1e9d04567` |
| `bilibili-hs` | 1 | `hot_id` | `bilibili-hs:hot:12345` |
| `bilibili-hv` | 1 | `bvid` | `bilibili-hv:BV1xx411c7mD` |
| `douyin` | 3 | 无稳定 ID，用标题哈希 | `douyin:title:b7e2f1a0c3d89456` |
| `toutiao` | 1 | `ClusterIdStr` | `toutiao:cluster:7654321` |
| `sina-news` | 2 | 文章 URL | `sina-news:url:c4d5e6f7a8b90123` |
| `thepaper` | 1 | `contId` | `thepaper:cont:28456` |
| `tencent-hot` | 2 | `link_info.url` | `tencent-hot:url:d1e2f3a4b5c60789` |
| `hackernews` | 1 | item ID | `hackernews:item:39234567` |
| `36kr-renqi` | 2 | 文章 URL | `36kr:url:e5f6a7b8c9d01234` |
| `douban` | 1 | subject ID | `douban:subject:36217654` |

### 2.4 标题规范化算法

用于优先级 3（标题哈希）和跨平台实体匹配：

```python
import re
import hashlib

def normalize_title(title: str) -> str:
    """规范化标题用于哈希和匹配"""
    text = title.strip()
    # 移除常见无意义前后缀
    text = re.sub(r'^[#【\[「]|[#】\]」]$', '', text)
    # 统一空白字符
    text = re.sub(r'\s+', '', text)
    # 移除标点符号（保留中文和英文字母数字）
    text = re.sub(r'[^\u4e00-\u9fff\u3400-\u4dbfa-zA-Z0-9]', '', text)
    return text.lower()

def generate_title_key(platform: str, title: str) -> str:
    normalized = normalize_title(title)
    hash_val = hashlib.sha256(normalized.encode('utf-8')).hexdigest()[:16]
    return f"{platform}:title:{hash_val}"
```

### 2.5 同平台话题更新流程

```
采集到话题 T（platform=zhihu, source_id=12345）
    │
    ├─ 生成 topic_key = "zhihu:question:12345"
    │
    ├─ 查询 topics 表是否存在该 topic_key
    │
    ├─ [不存在] ──→ INSERT 新话题
    │               ├─ first_seen_at = NOW()
    │               ├─ is_on_list = TRUE
    │               └─ rank_change = {type: "new"}
    │
    └─ [已存在] ──→ UPDATE 现有话题
                    ├─ heat_value = 新值
                    ├─ rank = 新排名
                    ├─ rank_change = 对比旧 rank 计算
                    ├─ last_seen_at = NOW()
                    ├─ updated_at = NOW()
                    └─ APPEND heat_history 记录
```

**下榜检测：** 某次采集中该平台的话题列表不再包含某 topic_key → 将该话题 `is_on_list` 设为 `FALSE`。

---

## 三、数据表设计

### 3.1 表关系总览

```
platforms (平台配置)
    │
    ├──< topics (话题主体，UPSERT)
    │       │
    │       ├──< heat_history (热度时间序列)
    │       │
    │       ├──1 topic_embeddings (向量嵌入)
    │       │
    │       └──>? event_clusters (跨平台事件)
    │
    └──< snapshots_meta (快照审计日志)
```

### 3.2 platforms — 平台配置

```sql
CREATE TABLE platforms (
    id              TEXT PRIMARY KEY,          -- 'zhihu', 'weibo', 'baidu'
    display_name    TEXT NOT NULL,             -- '知乎', '微博', '百度'
    display_name_en TEXT,                      -- 'Zhihu', 'Weibo', 'Baidu'
    category        TEXT NOT NULL,             -- 'domestic', 'tech', 'finance', 'international'
    priority        TEXT NOT NULL DEFAULT 'P0',-- 'P0', 'P1', 'P2'
    icon_name       TEXT,                      -- iOS SF Symbol 或自定义图标名
    color_hex       TEXT,                      -- 品牌色 '#FF6B35'
    fetch_interval  INT NOT NULL DEFAULT 15,   -- 采集间隔（分钟）
    enabled         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 3.3 topics — 话题主体

```sql
CREATE TABLE topics (
    -- 身份标识
    topic_key       TEXT PRIMARY KEY,          -- 混合优先级生成（见第二章）
    platform_id     TEXT NOT NULL REFERENCES platforms(id),
    source_id       TEXT,                      -- 平台原生 ID（可空）

    -- 内容字段（iOS 直接使用）
    title           TEXT NOT NULL,
    description     TEXT,                      -- 话题描述/摘要
    content         TEXT,                      -- 正文内容（阶段 2 抓取）
    summary         TEXT,                      -- AI 生成摘要
    link            TEXT,                      -- 原文链接
    image_urls      TEXT[],                    -- 图片 URL 数组
    tags            TEXT[],                    -- 标签数组

    -- 热度与排名（iOS 直接使用）
    heat_value      INT,                       -- 归一化后的热度值
    raw_heat_value  TEXT,                      -- 原始热度值（保留原始信息）
    rank            INT,                       -- 当前排名
    rank_change     JSONB,                     -- {"type":"up","value":3}

    -- 跨平台关联
    cluster_id      TEXT REFERENCES event_clusters(cluster_id),
    entities        TEXT[],                    -- 提取的命名实体（用于匹配）

    -- 时间与状态
    first_seen_at   TIMESTAMPTZ NOT NULL,      -- 首次上榜时间
    last_seen_at    TIMESTAMPTZ NOT NULL,      -- 最近一次在榜时间
    fetched_at      TIMESTAMPTZ NOT NULL,      -- 最新采集时间戳
    is_on_list      BOOLEAN NOT NULL DEFAULT TRUE,  -- 当前是否在榜

    -- 元数据
    schema_version  INT NOT NULL DEFAULT 1,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 索引
CREATE INDEX idx_topics_platform_onlist ON topics(platform_id, is_on_list);
CREATE INDEX idx_topics_platform_rank ON topics(platform_id, rank) WHERE is_on_list = TRUE;
CREATE INDEX idx_topics_cluster ON topics(cluster_id) WHERE cluster_id IS NOT NULL;
CREATE INDEX idx_topics_last_seen ON topics(last_seen_at);
CREATE INDEX idx_topics_entities ON topics USING GIN(entities);
```

### 3.4 heat_history — 热度时间序列

```sql
CREATE TABLE heat_history (
    id              BIGSERIAL PRIMARY KEY,
    topic_key       TEXT NOT NULL REFERENCES topics(topic_key) ON DELETE CASCADE,
    timestamp       TIMESTAMPTZ NOT NULL,
    heat_value      INT,
    rank            INT,

    UNIQUE(topic_key, timestamp)
);

CREATE INDEX idx_heat_history_topic_time ON heat_history(topic_key, timestamp DESC);
```

### 3.5 event_clusters — 跨平台事件聚类

```sql
CREATE TABLE event_clusters (
    cluster_id      TEXT PRIMARY KEY,          -- 'evt_{timestamp}_{hash}'
    title           TEXT NOT NULL,             -- 代表性标题（取最高热度话题）
    keywords        TEXT[],                    -- 共享关键实体
    platform_count  INT NOT NULL DEFAULT 0,    -- 涉及平台数
    topic_count     INT NOT NULL DEFAULT 0,    -- 关联话题数
    max_heat        INT NOT NULL DEFAULT 0,    -- 最高热度（排序用）
    first_seen_at   TIMESTAMPTZ NOT NULL,
    last_updated_at TIMESTAMPTZ NOT NULL,
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,  -- 是否仍在热榜
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_clusters_active ON event_clusters(is_active, max_heat DESC);
```

### 3.6 topic_embeddings — 向量嵌入（pgvector）

```sql
-- 启用 pgvector 扩展
CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE topic_embeddings (
    topic_key       TEXT PRIMARY KEY REFERENCES topics(topic_key) ON DELETE CASCADE,
    embedding       vector(512) NOT NULL,      -- Jina Embeddings 512 维
    model_version   TEXT NOT NULL DEFAULT 'jina-embeddings-v3',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- HNSW 索引（余弦相似度，支持近似最近邻搜索）
CREATE INDEX idx_embeddings_hnsw ON topic_embeddings
    USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);
```

> **为什么选 HNSW 而非 IVFFlat？**
> - HNSW 可在空表上创建，无需等待数据积累
> - 数据增删不影响索引质量，无需定期重建
> - 查询性能更稳定，适合持续运行的生产系统

> **为什么选 512 维？**
> - Jina v3 支持 Matryoshka 维度截断（32 到 1024）
> - 512 维在中文短文本匹配中质量与存储的平衡点最佳
> - 10,000 条话题 × 512 维 × 4 字节 ≈ 20 MB，远在免费额度内
> - HNSW 索引 512 维查询延迟 < 10ms（万级数据量）

### 3.7 snapshots_meta — 快照审计日志

```sql
CREATE TABLE snapshots_meta (
    id              TEXT PRIMARY KEY,          -- '{platform}_{timestamp}'
    platform_id     TEXT NOT NULL REFERENCES platforms(id),
    fetched_at      TIMESTAMPTZ NOT NULL,
    topic_count     INT NOT NULL,
    new_topic_count INT NOT NULL DEFAULT 0,    -- 本次新增话题数
    content_hash    TEXT,                      -- 话题列表哈希（变更检测）
    fetch_duration  INT,                       -- 采集耗时（毫秒）
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_snapshots_platform_time ON snapshots_meta(platform_id, fetched_at DESC);
```

### 3.8 Row Level Security 配置

```sql
-- 所有表启用 RLS
ALTER TABLE platforms ENABLE ROW LEVEL SECURITY;
ALTER TABLE topics ENABLE ROW LEVEL SECURITY;
ALTER TABLE heat_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_clusters ENABLE ROW LEVEL SECURITY;
ALTER TABLE topic_embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE snapshots_meta ENABLE ROW LEVEL SECURITY;

-- iOS 客户端：仅读取权限（anon role）
CREATE POLICY "anon_read_platforms" ON platforms FOR SELECT TO anon USING (true);
CREATE POLICY "anon_read_topics" ON topics FOR SELECT TO anon USING (true);
CREATE POLICY "anon_read_heat_history" ON heat_history FOR SELECT TO anon USING (true);
CREATE POLICY "anon_read_clusters" ON event_clusters FOR SELECT TO anon USING (true);

-- topic_embeddings 和 snapshots_meta 对客户端不可见（不设 anon 策略）

-- Python 后端使用 service_role key 绕过 RLS 进行写入
```

---

## 四、跨平台话题关联算法

### 4.1 算法概述

采用 **三信号融合** 策略，不依赖 LLM，保证实时性和成本可控：

```
信号 1：时间窗口过滤（硬门槛）
    └─ 仅匹配 24 小时内共同在榜的话题

信号 2：命名实体匹配（快速候选筛选）
    └─ jieba 分词提取实体 → 倒排索引 → 实体重叠度

信号 3：语义向量相似度（精确验证）
    └─ Jina Embeddings → pgvector 余弦相似度
```

### 4.2 Jina Embeddings 配置

| 参数 | 值 | 说明 |
|------|---|------|
| 模型 | `jina-embeddings-v3` | 成熟稳定，89 语言支持，中文表现优秀 |
| 维度 | 512 | Matryoshka 截断，平衡质量与存储 |
| task | `text-matching` | 专为文本对匹配优化的 LoRA 适配器 |
| 输入 | `title + " " + (description or "")` | 标题为主，描述为辅 |

```python
# 调用示例
import httpx

async def get_embeddings(texts: list[str]) -> list[list[float]]:
    response = await httpx.AsyncClient().post(
        "https://api.jina.ai/v1/embeddings",
        headers={"Authorization": f"Bearer {JINA_API_KEY}"},
        json={
            "model": "jina-embeddings-v3",
            "input": texts,
            "dimensions": 512,
            "task": "text-matching"
        }
    )
    data = response.json()
    return [item["embedding"] for item in data["data"]]
```

### 4.3 实体提取

使用 jieba 分词 + 词性标注提取命名实体：

```python
import jieba.posseg as pseg

# 需要提取的词性
ENTITY_POS_TAGS = {
    'nr',   # 人名
    'ns',   # 地名
    'nt',   # 机构名
    'nz',   # 其他专名
    'nrt',  # 音译人名
    'vn',   # 名动词（如 "选举"）
}

def extract_entities(title: str) -> list[str]:
    """从标题提取命名实体"""
    words = pseg.cut(title)
    entities = []
    for word, flag in words:
        if flag in ENTITY_POS_TAGS and len(word) >= 2:
            entities.append(word)
    return list(set(entities))

# 示例：
# "特朗普访华讨论贸易问题" → ["特朗普", "访华", "贸易"]
# "杨幂刘恺威正式离婚" → ["杨幂", "刘恺威", "离婚"]
```

### 4.4 匹配算法详细流程

每个采集周期结束后执行：

```
Phase 1: 准备
    ├─ 获取本轮新增或更新的话题列表 T_new
    ├─ 获取当前所有 is_on_list=TRUE 的话题 T_active
    └─ 确保所有话题都有 embedding（新话题需先调用 Jina API）

Phase 2: 候选生成（实体倒排索引）
    ├─ 对 T_new 中每个话题 t：
    │   ├─ 取 t.entities
    │   ├─ 通过 GIN 索引查询 T_active 中共享实体的话题
    │   │   SQL: SELECT topic_key, entities FROM topics
    │   │        WHERE entities && ARRAY[t.entities]   -- 数组重叠
    │   │          AND platform_id != t.platform_id     -- 不同平台
    │   │          AND is_on_list = TRUE
    │   │          AND last_seen_at > NOW() - INTERVAL '24 hours'
    │   └─ 得到候选集 C_entity(t)
    │
    └─ 同时：通过 pgvector 查询语义相似话题
        ├─ SQL: SELECT t.topic_key, t.entities,
        │              1 - (te.embedding <=> $embedding) as similarity
        │        FROM topics t
        │        JOIN topic_embeddings te ON t.topic_key = te.topic_key
        │        WHERE t.platform_id != $platform
        │          AND t.is_on_list = TRUE
        │          AND t.last_seen_at > NOW() - INTERVAL '24 hours'
        │          AND 1 - (te.embedding <=> $embedding) > 0.5
        │        ORDER BY te.embedding <=> $embedding
        │        LIMIT 20
        └─ 得到候选集 C_vector(t)

Phase 3: 融合评分
    ├─ 合并候选集 C(t) = C_entity(t) ∪ C_vector(t)
    ├─ 对每个候选对 (t, c)：
    │   ├─ entity_score = jaccard(t.entities, c.entities)
    │   ├─ vector_score = cosine_similarity(t.embedding, c.embedding)
    │   └─ 计算综合分（见 4.5）
    └─ 过滤：综合分 > 阈值的保留

Phase 4: 聚类分配（Union-Find）
    ├─ 对所有通过阈值的配对 (t, c)：
    │   ├─ 若两者都无 cluster_id → 创建新 event_cluster
    │   ├─ 若一方有 cluster_id → 另一方加入该 cluster
    │   └─ 若两方有不同 cluster_id → 合并 cluster（保留较早的）
    └─ 更新 topics.cluster_id

Phase 5: 聚类元数据更新
    ├─ 重新统计 topic_count、platform_count、max_heat
    ├─ title = 该 cluster 中 heat_value 最高的话题标题
    ├─ keywords = 该 cluster 中出现次数 ≥ 2 的实体
    └─ is_active = cluster 中是否存在 is_on_list=TRUE 的话题
```

### 4.5 综合评分公式

```python
def compute_match_score(entity_score: float, vector_score: float) -> float:
    """
    三档匹配策略：
    - 实体高度匹配（>0.5）：即使语义分不高也认为匹配
    - 语义高度相似（>0.85）：即使无共享实体也认为匹配
    - 双信号中等：两者都达到中等水平则匹配
    """
    # 任一信号极强 → 直接匹配
    if entity_score >= 0.5:
        return max(0.8, entity_score * 0.3 + vector_score * 0.7)
    if vector_score >= 0.85:
        return max(0.8, entity_score * 0.3 + vector_score * 0.7)

    # 双信号加权
    return entity_score * 0.3 + vector_score * 0.7

MATCH_THRESHOLD = 0.65
```

**设计考量：**

| 场景 | 实体分 | 语义分 | 综合分 | 是否匹配 |
|------|--------|--------|--------|---------|
| 微博"杨幂离婚" vs 知乎"杨幂刘恺威离婚" | 0.67 | 0.72 | 0.80 | ✅ |
| 微博"新能源车销量" vs 头条"电动汽车暴涨" | 0.0 | 0.88 | ≥0.80 | ✅ |
| 百度"台风来袭" vs 微博"台风山竹登陆" | 0.33 | 0.78 | 0.65 | ✅ 边界 |
| 知乎"如何评价iPhone" vs B站"iPhone开箱" | 0.5 | 0.62 | ≥0.80 | ✅ |
| 微博"地震" vs 头条"股市暴跌" | 0.0 | 0.15 | 0.11 | ❌ |

### 4.6 算法复杂度与性能

| 阶段 | 时间复杂度 | 说明 |
|------|-----------|------|
| 实体提取 | O(N × L) | N=话题数, L=平均标题长度; jieba 切分极快 |
| Jina 嵌入 | O(N / B) | B=批大小; 单次 API 调用处理整批 |
| 实体候选查询 | O(N × log M) | GIN 索引; M=活跃话题总数 |
| pgvector 相似搜索 | O(N × log M) | HNSW 索引; 每次查询 < 10ms |
| Union-Find 聚类 | O(P × α(P)) ≈ O(P) | P=候选配对数; α 为反阿克曼函数 |

**实际耗时估算（7 平台 × 30 话题 = 210 条/轮）：**

| 步骤 | 耗时 |
|------|------|
| jieba 实体提取 | ~50ms |
| Jina API（仅新话题，约 30-50 条） | ~500ms |
| PostgreSQL 候选查询（210 次） | ~200ms |
| 评分 + 聚类 | ~10ms |
| 数据库写入 | ~300ms |
| **合计** | **~1.1 秒** |

### 4.7 大规模数据下的优化策略

当数据源扩展到 P1/P2（20 个源，600+ 话题/轮）时：

| 优化 | 方法 | 触发条件 |
|------|------|---------|
| **批量嵌入** | Jina API 单次请求发送所有新话题 | 默认启用 |
| **增量匹配** | 仅对新增/更新话题运行匹配，非全量重算 | 默认启用 |
| **时间窗口收窄** | 候选查询的时间窗口从 24h 缩到 12h | 活跃话题 > 2000 |
| **pgvector 预过滤** | 在 WHERE 子句中加 `platform_id` 过滤减少扫描范围 | 默认启用 |
| **HNSW 参数调优** | 提高 `ef_search` 换取更高召回率 | 匹配漏检率 > 5% |
| **异步并行** | 多平台实体查询和向量查询并行执行 | 默认启用 |

---

## 五、数据管道架构

### 5.1 整体流程

```
┌──────────────────────────────────────────────────────────────┐
│                    Python 后端（每 15 分钟）                   │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ① Fetch ──→ ② Extract ──→ ③ Embed ──→ ④ Match ──→ ⑤ Write │
│  平台API      实体提取      Jina API    三信号匹配   Supabase │
│                                                              │
└──────────────────────────────────────────────────────────────┘
         │                                          │
         ▼                                          ▼
┌─────────────────┐                    ┌─────────────────────┐
│  外部数据源 API  │                    │    Supabase         │
│  (20 个平台)     │                    │  ┌───────────────┐  │
└─────────────────┘                    │  │ PostgreSQL     │  │
                                       │  │  topics        │  │
                                       │  │  heat_history  │  │
┌─────────────────┐                    │  │  clusters      │  │
│   Jina API      │                    │  ├───────────────┤  │
│ Embeddings v3   │                    │  │ pgvector       │  │
│ (text-matching) │                    │  │  embeddings    │  │
└─────────────────┘                    │  └───────────────┘  │
                                       │         │ RLS       │
                                       │         ▼           │
                                       │  ┌───────────────┐  │
                                       │  │ Data API      │  │
                                       │  │ (REST/anon)   │  │
                                       │  └───────┬───────┘  │
                                       └──────────┼──────────┘
                                                  │
                                                  ▼
                                       ┌─────────────────────┐
                                       │   iOS 客户端         │
                                       │   supabase-swift     │
                                       │   (只读查询)         │
                                       └─────────────────────┘
```

### 5.2 各步骤详细职责

| 步骤 | 输入 | 输出 | 说明 |
|------|------|------|------|
| **① Fetch** | 平台 API URL | 原始话题列表 | 调用热榜 API，获取标题/热度/链接等原始数据 |
| **② Extract** | 原始话题列表 | 话题 + entities | jieba 实体提取、热度值归一化、生成 topic_key |
| **③ Embed** | 新话题标题列表 | embedding 向量 | 批量调用 Jina API，仅处理新话题（已有 embedding 的跳过） |
| **④ Match** | 新话题 + 全量活跃话题 | cluster 分配 | 三信号匹配算法，分配/创建 cluster_id |
| **⑤ Write** | 处理完毕的完整数据 | Supabase 记录 | UPSERT topics、APPEND heat_history、更新 clusters |

### 5.3 关于 Supabase Edge Functions 的考量

经评估，当前架构中 **Python 后端直接调用 Jina API** 是更优选择：

| 方案 | 优点 | 缺点 |
|------|------|------|
| **Python 直调 Jina** | 流程简单；嵌入和匹配在同一进程中，无异步等待 | Python 端需网络可达 Jina API |
| Edge Function 调 Jina | Supabase 全球边缘网络更稳定 | 增加架构复杂度；需处理异步回调时序；Edge Function CPU 限 2 秒 |

**保留 Edge Function 作为备选：** 若 Python 部署环境对 Jina API 网络不稳定（如中国大陆直连不可靠），可将嵌入生成迁移到 Supabase Edge Function：

```
Python INSERT topic (无 embedding)
    → Database Webhook 触发 Edge Function
    → Edge Function 调用 Jina API
    → Edge Function 写回 topic_embeddings
    → Python 轮询/等待后执行匹配
```

此迁移只需改变嵌入写入的位置，不影响表结构和匹配算法。

---

## 六、iOS 客询接口

### 6.1 设计原则

- iOS 端 **不读取** `topic_embeddings` 和 `snapshots_meta` 表
- iOS 端 **不执行** 任何聚合计算、相似度计算或数据加工
- 所有查询通过 Supabase Swift SDK 的 `.from().select().eq().order()` 链式调用完成
- 利用 Supabase 外键关系自动 JOIN

### 6.2 场景查询映射

| iOS 场景 | 查询 | 说明 |
|---------|------|------|
| **FeedView — 某平台热榜** | `topics?platform_id=eq.zhihu&is_on_list=eq.true&order=rank` | 单表查询，rank 索引 |
| **FeedView — 全平台热榜** | `topics?is_on_list=eq.true&order=heat_value.desc&limit=50` | 按热度排序 |
| **TopicDetailView** | `topics?topic_key=eq.xxx&select=*,event_clusters(*)` | 带 cluster 信息的 JOIN |
| **DataAnalyseView — 热度曲线** | `heat_history?topic_key=eq.xxx&order=timestamp.desc&limit=96` | 最近 24h 数据点 |
| **CompareView — 跨平台事件列表** | `event_clusters?is_active=eq.true&order=max_heat.desc` | 活跃事件排序 |
| **CompareView — 事件详情** | `topics?cluster_id=eq.evt_xxx&is_on_list=eq.true&order=platform_id,rank` | **一条语句拉出所有平台报道** |
| **SearchView** | `topics?title=ilike.*关键词*&is_on_list=eq.true` | ILIKE 模糊搜索 |

### 6.3 Supabase Swift SDK 示例

```swift
// CompareView: 获取某事件的所有平台报道
let topics = try await supabase
    .from("topics")
    .select("*, event_clusters(*)")
    .eq("cluster_id", clusterId)
    .eq("is_on_list", true)
    .order("platform_id")
    .order("rank")
    .execute()
    .value as [TopicResponse]

// FeedView: 获取知乎热榜
let topics = try await supabase
    .from("topics")
    .select()
    .eq("platform_id", "zhihu")
    .eq("is_on_list", true)
    .order("rank")
    .execute()
    .value as [TopicResponse]

// DataAnalyseView: 获取热度历史
let history = try await supabase
    .from("heat_history")
    .select()
    .eq("topic_key", topicKey)
    .order("timestamp", ascending: false)
    .limit(96)
    .execute()
    .value as [HeatHistoryResponse]
```

### 6.4 iOS 端数据模型映射

Supabase 返回的 JSON 直接映射到 iOS Domain Entity，无需额外转换逻辑：

| Supabase 字段 | iOS TrendTopicEntity 字段 | 转换 |
|--------------|--------------------------|------|
| `topic_key` | `id` | 直接映射 |
| `platform_id` | `platform` | String → Platform 枚举 |
| `title` | `title` | 直接映射 |
| `description` | `description` | 直接映射 |
| `summary` | `summary` | 直接映射 |
| `heat_value` | `heatValue` | 直接映射 |
| `rank` | `rank` | 直接映射 |
| `rank_change` | `rankChange` | JSONB → RankChange 解码 |
| `link` | `link` | 直接映射 |
| `image_urls` | `imageURLs` | 直接映射 |
| `tags` | `tags` | 直接映射 |
| `fetched_at` | `fetchedAt` | ISO 8601 → Date |
| `cluster_id` | (新增) `clusterId` | 直接映射，用于跨平台跳转 |

---

## 七、数据保留与维护策略

### 7.1 数据生命周期

| 数据类型 | 保留策略 | 清理方式 |
|---------|---------|---------|
| **topics** (is_on_list=TRUE) | 永久保留（活跃话题） | — |
| **topics** (is_on_list=FALSE) | 保留 90 天，之后删除 | pg_cron 每日清理 |
| **heat_history** | 全精度保留 7 天 | pg_cron 每日清理 |
| **heat_history** (降采样) | 7-90 天：每小时一个点 | pg_cron 每日降采样 |
| **heat_history** (>90天) | 删除 | pg_cron 每日清理 |
| **event_clusters** (is_active=TRUE) | 永久保留 | — |
| **event_clusters** (is_active=FALSE) | 保留 90 天 | pg_cron 每日清理 |
| **topic_embeddings** | 随 topics 级联删除 | 自动（ON DELETE CASCADE） |
| **snapshots_meta** | 保留 14 天 | pg_cron 每日清理 |

### 7.2 定期维护任务

> **执行方式：** Supabase 免费版不支持 pg_cron，以下清理 SQL 由 Python 后端调度器（每日凌晨 3:00）通过 service_role 连接执行。

```sql
-- Python 后端每日执行以下清理 SQL：

  -- 1. 标记下榜话题
  -- (由 Python 后端在每轮采集后执行，此处为兜底)

  -- 2. 删除 90 天前的下榜话题
  DELETE FROM topics
  WHERE is_on_list = FALSE
    AND last_seen_at < NOW() - INTERVAL '90 days';

  -- 3. 降采样 7 天前的 heat_history（保留每小时第一条）
  DELETE FROM heat_history
  WHERE timestamp < NOW() - INTERVAL '7 days'
    AND timestamp > NOW() - INTERVAL '90 days'
    AND id NOT IN (
      SELECT DISTINCT ON (topic_key, date_trunc('hour', timestamp))
        id FROM heat_history
      WHERE timestamp < NOW() - INTERVAL '7 days'
        AND timestamp > NOW() - INTERVAL '90 days'
      ORDER BY topic_key, date_trunc('hour', timestamp), timestamp
    );

  -- 4. 删除 90 天前的 heat_history
  DELETE FROM heat_history
  WHERE timestamp < NOW() - INTERVAL '90 days';

  -- 5. 删除 14 天前的快照元数据
  DELETE FROM snapshots_meta
  WHERE fetched_at < NOW() - INTERVAL '14 days';

  -- 6. 停用无活跃话题的 cluster
  UPDATE event_clusters SET is_active = FALSE, last_updated_at = NOW()
  WHERE is_active = TRUE
    AND cluster_id NOT IN (
      SELECT DISTINCT cluster_id FROM topics
      WHERE is_on_list = TRUE AND cluster_id IS NOT NULL
    );

  -- 7. 删除 90 天前的非活跃 cluster
  DELETE FROM event_clusters
  WHERE is_active = FALSE
    AND last_updated_at < NOW() - INTERVAL '90 days';
```

### 7.3 存储空间估算（免费额度 500 MB，90 天保留周期）

| 数据 | 单条大小 | 90 天累计条数 | 占用 |
|------|---------|-------------|------|
| topics (活跃) | ~1 KB | ~600 | ~0.6 MB |
| topics (含 90 天周转) | ~1 KB | ~15,000 | ~15 MB |
| heat_history (全精度 7 天) | ~40 bytes | ~600 × 672 ≈ 400K | ~16 MB |
| heat_history (降采样 8-90 天) | ~40 bytes | ~15,000 × 83d × 24 ≈ 300K | ~12 MB |
| event_clusters | ~0.5 KB | ~1,500 | ~0.75 MB |
| topic_embeddings | ~2.1 KB | ~15,000 | ~31 MB |
| snapshots_meta (14 天) | ~0.2 KB | ~7 × 96 × 14 ≈ 9,400 | ~2 MB |
| 索引 | — | — | ~15 MB |
| **合计** | | | **~92 MB** |

> 约占免费额度的 18.4%，仍有充裕的扩展空间。

---

## 八、热度值归一化方案

### 8.1 方案选择

采用 **平台内排名映射 + 原始值保留** 策略：

```python
def normalize_heat(rank: int, total: int, raw_heat: int | None) -> int:
    """
    归一化热度值到 0 - 10,000,000 区间

    策略：
    1. 基础分 = 基于排名的指数衰减（确保跨平台可比性）
    2. 原始值保留在 raw_heat_value 字段（供高级分析使用）
    """
    if total == 0:
        return 0
    # 排名越高（rank 越小），热度值越大
    # 使用指数衰减：第 1 名 = 10,000,000，第 30 名 ≈ 1,000,000
    position_ratio = (total - rank + 1) / total  # 1.0 ~ 0.03
    heat = int(10_000_000 * (position_ratio ** 1.5))
    return max(heat, 1)
```

### 8.2 设计理由

| 方案 | 优点 | 缺点 | 结论 |
|------|------|------|------|
| 保留原始值 | 信息无损 | 跨平台不可比（知乎"万热度" vs HN 评分 342） | ❌ |
| 各平台独立归一化到 0-100 | 简单 | 丢失热度量级信息 | ❌ |
| **排名映射 + 原始值保留** | 跨平台可比；原始值不丢失 | 排名映射可能不完全准确 | ✅ |

---

## 九、实施路线图

### 9.1 与阶段 2 任务的对应关系

| 本文档章节 | 对应 Progress.md 任务 | 实施顺序 |
|-----------|---------------------|---------|
| 第二章（Topic Identity） | 2.2.1 话题去重策略 | 1 |
| 第八章（热度归一化） | 2.2.1 热度值归一化方案 | 1 |
| 第三章（表设计） | 2.2.2 ~ 2.2.5 数据库建模 | 2 |
| 第四章（匹配算法） | 2.3.4 数据处理器 | 3 |
| 第五章（数据管道） | 2.3.1 ~ 2.3.6 后端开发 | 3 |
| 第六章（iOS 查询） | 2.4 iOS 远程数据层 | 4 |
| 第七章（数据保留） | 2.3.6 调度系统 | 3 |

### 9.2 依赖关系

```
[表创建 + RLS] ──→ [Python 后端 Fetcher] ──→ [嵌入 + 匹配算法] ──→ [iOS 集成]
      │                    │                         │
      └─ pgvector 扩展     └─ Jina API Key           └─ 调优阈值
         HNSW 索引            jieba 词典
```

---

## 十、文档更新日志

| 日期 | 更新内容 |
|------|---------|
| 2026-02-25 | 初版创建：Topic Identity 策略、表设计、三信号匹配算法、数据管道、iOS 查询接口、数据保留策略 |
