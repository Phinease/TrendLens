# TrendLens 后端架构文档

> **文档定位：** Python 后端数据管道的权威架构说明
> **上层引用：** [TrendLens Technical Architecture.md](../../TrendLens%20Technical%20Architecture.md) §10
> **数据源规范：** [hot-news-data-sources-v2.md](hot-news-data-sources-v2.md)
> **存储设计：** [data-storage-strategy.md](data-storage-strategy.md)
> **字段映射：** [data-requirements.md](data-requirements.md)

---

## 1. 系统概述

Python 后端是 TrendLens 的数据采集管道，负责从多个平台抓取热榜数据、处理归一化、生成向量嵌入、执行跨平台话题匹配，并将结果存入 Supabase。

```
┌─────────────────────────────────────────────────────────────────┐
│                    TrendLens 数据管道                             │
│                                                                 │
│  ┌─────────┐  ┌────────────┐  ┌──────────┐  ┌───────────────┐  │
│  │ Fetcher │→│ Normalizer │→│ Embedder │→│   Matcher     │  │
│  │ 平台采集 │  │ 归一化处理 │  │ 向量嵌入 │  │ 跨平台匹配   │  │
│  └─────────┘  └────────────┘  └──────────┘  └───────────────┘  │
│       │              │              │              │             │
│       ▼              ▼              ▼              ▼             │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Supabase (PostgREST API)                    │   │
│  │  topics │ heat_history │ topic_embeddings │ event_clusters│   │
│  └──────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────┘
```

**运行模式：**
- **单次运行**：`uv run python -m trendlens run -p P0` — 执行一次完整管道
- **持续模式**：`uv run python -m trendlens serve` — 每 15 分钟自动执行

---

## 2. 项目结构

```
backend/
├── pyproject.toml                  # uv 项目定义 + 依赖
├── config/
│   ├── supabase.yaml               # 密钥配置（gitignored）
│   └── supabase.example.yaml       # 配置模板
├── data/                           # 65 个 API 样本文件（开发验证用）
├── docs/
│   ├── backend-architecture.md     # 本文档
│   ├── data-storage-strategy.md    # topic_key、归一化、匹配算法规范
│   ├── data-requirements.md        # 数据需求与字段映射
│   ├── data-sources-v1.md          # 全量数据源调研
│   └── hot-news-data-sources-v2.md # 选定接口规范（20 个平台）
├── migrations/
│   ├── 001_init_tables.sql         # 6 张表 + pgvector 扩展
│   └── 002_cron_jobs.sql           # 定时清理 SQL
├── logs/                           # 运行时生成（gitignored）
│   ├── runs/                       # 每次运行的独立日志
│   └── errors/                     # 按日期的错误日志
└── src/
    └── trendlens/
        ├── __init__.py             # 版本号
        ├── __main__.py             # python -m trendlens 入口
        ├── cli.py                  # Click CLI（run / serve / cleanup）
        ├── config.py               # Pydantic 配置加载（YAML + env）
        ├── constants.py            # 全局阈值与常量
        ├── models.py               # RawTopic / FetchResult / NormalizedTopic
        ├── log_setup.py            # structlog + 文件日志配置
        ├── pipeline.py             # 编排器：完整管道流程
        ├── scheduler.py            # APScheduler 持续调度
        ├── fetchers/               # 平台采集器
        │   ├── base.py             # BaseFetcher ABC + @register_fetcher
        │   ├── http_client.py      # httpx AsyncClient + tenacity 重试
        │   ├── zhihu.py            # 知乎热榜 (P0)
        │   ├── baidu.py            # 百度热搜 (P0)
        │   ├── weibo.py            # 微博热搜 (P0, xxapi.cn)
        │   ├── bilibili_hs.py      # B站热搜 (P0)
        │   ├── bilibili_hv.py      # B站热门视频 (P0)
        │   ├── douyin.py           # 抖音热榜 (P0, xxapi.cn)
        │   └── toutiao.py          # 今日头条 (P0)
        ├── processing/             # 数据处理
        │   ├── normalizer.py       # topic_key 生成 + 热度归一化
        │   ├── entity_extractor.py # jieba 实体提取
        │   └── embedder.py         # Jina API 批量嵌入
        ├── matching/               # 跨平台匹配
        │   ├── matcher.py          # 三信号融合匹配算法
        │   └── union_find.py       # Union-Find 聚类
        └── storage/                # Supabase 存储层
            ├── client.py           # PostgREST httpx 客户端
            ├── topic_store.py      # topics UPSERT + heat_history
            ├── embedding_store.py  # topic_embeddings 读写
            ├── cluster_store.py    # event_clusters 创建/合并
            ├── snapshot_store.py   # snapshots_meta 写入
            └── maintenance.py      # 数据清理
```

**文件统计：** 6 个包、25 个 Python 模块。

---

## 3. 技术栈

| 类别 | 技术 | 用途 |
|------|------|------|
| 语言 | Python 3.12+ | 异步管道 |
| 包管理 | uv | 依赖管理与运行 |
| HTTP 客户端 | httpx[http2,socks] | 异步请求、代理支持 |
| HTML 解析 | BeautifulSoup4 + lxml | 百度热搜 HTML 解析 |
| 中文分词 | jieba (posseg) | 命名实体提取 |
| 向量嵌入 | Jina Embeddings v3 | 512 维文本嵌入 |
| 数据库 | Supabase (PostgreSQL + pgvector) | 数据持久化 |
| 存储接口 | PostgREST via httpx | 代理友好的 DB 访问 |
| 数据验证 | Pydantic v2 | 配置模型 |
| 配置 | PyYAML | YAML 配置加载 |
| CLI | Click | 命令行界面 |
| 调度 | APScheduler v3 | 定时运行 |
| 重试 | tenacity | HTTP 请求重试策略 |
| 日志 | structlog | JSON 结构化日志 |

---

## 4. 数据管道流程

`pipeline.py:run_cycle()` 编排完整的单次管道执行，共 10 个步骤：

```
Step 1  并发采集 (Semaphore=5)
  │     7 个 P0 fetcher 并行运行
  ▼
Step 2  归一化
  │     topic_key 生成 + 热度映射 + 标题规范化
  ▼
Step 3  实体提取
  │     jieba POS 命名实体提取
  ▼
Step 4  连接 Supabase
  │     初始化 PostgREST 客户端
  ▼
Step 5  向量嵌入
  │     Jina API 批量嵌入（仅新话题，64 条/批）
  ▼
Step 6  UPSERT topics + APPEND heat_history
  │     ON CONFLICT (topic_key) DO UPDATE
  ▼
Step 7  下榜检测
  │     标记该平台不在结果中的话题 is_on_list=FALSE
  ▼
Step 8  存储嵌入向量
  │     topic_embeddings 表 UPSERT
  ▼
Step 9  匹配 + 聚类
  │     三信号融合 → Union-Find → event_clusters
  ▼
Step 10 记录快照元数据
        snapshots_meta 写入
```

---

## 5. 核心模块设计

### 5.1 Fetcher 架构 (`fetchers/`)

**设计模式：** 注册表模式 + 策略模式

```python
# base.py
class BaseFetcher(ABC):
    platform_id: str    # 平台标识符
    priority: str       # "P0" / "P1" / "P2"

    @abstractmethod
    async def fetch(self) -> FetchResult: ...

@register_fetcher       # 装饰器自动注册到全局注册表
class ZhihuFetcher(BaseFetcher):
    platform_id = "zhihu"
    priority = "P0"
```

- 每个 fetcher 自行 try/except，失败返回 `FetchResult(error=...)` 而非抛出异常
- 共享 `httpx.AsyncClient`（连接池、User-Agent 轮换、HTTP/2、30s 超时）
- `tenacity` 重试：3 次、指数退避 1s/2s/4s，仅重试网络/超时错误

**P0 平台列表 (7 个)：**

| Fetcher | API 来源 | 典型条目数 | ID 策略 |
|---------|---------|-----------|---------|
| zhihu | 知乎官方 API | ~50 | question ID from URL |
| baidu | 百度官方页面 (HTML 内嵌 JSON) | ~51 | word 字段 hash |
| weibo | xxapi.cn 免费 API | ~52 | 标题 hash |
| bilibili-hs | B站官方 API | ~20 | hot_id |
| bilibili-hv | B站官方 API | ~50 | bvid |
| douyin | xxapi.cn 免费 API | ~50 | sentence_id / group_id |
| toutiao | 头条官方 API | ~50 | ClusterIdStr |

### 5.2 归一化处理 (`processing/normalizer.py`)

**topic_key 三级降级策略**（参考 data-storage-strategy §2）：

```
Level 1: {platform}:{source_id}       ← 优先使用平台原生 ID
Level 2: {platform}:title:{sha256[:16]} ← 标题 hash 兜底
```

**热度归一化**（参考 data-storage-strategy §8）：

```python
# 排名映射到 0..10,000,000
position_ratio = (total - rank + 1) / total
heat_value = int(10_000_000 * (position_ratio ** 1.5))
```

**标题规范化**：
1. 去除首尾空白
2. 移除包裹符号（#、【】、[]、「」）
3. 合并空白
4. 仅保留 CJK + 字母数字
5. 转小写

### 5.3 实体提取 (`processing/entity_extractor.py`)

使用 jieba POS 标注提取中文命名实体：
- 有效词性标签：`nr`(人名)、`ns`(地名)、`nt`(机构)、`nz`(其他专名)、`nrt`(音译人名)、`vn`(动名词)
- 最小长度：2 字符
- 去重后存入 `NormalizedTopic.entities`

### 5.4 向量嵌入 (`processing/embedder.py`)

- **模型**：Jina Embeddings v3（`jina-embeddings-v3`）
- **维度**：512
- **任务类型**：`text-matching`
- **批量大小**：64 条/批
- **增量策略**：通过 `get_existing_keys()` 查询已有嵌入，仅处理新话题
- **降级策略**：API 失败时跳过嵌入，话题仍正常存储，下轮补嵌入

### 5.5 匹配算法 (`matching/matcher.py`)

完整实现 data-storage-strategy §4 三信号融合匹配：

```
信号 1: 实体 Jaccard 重叠度 (权重 0.3)
  └─ 实体倒排索引快速查找共享实体的候选话题

信号 2: 向量余弦相似度 (权重 0.7)
  └─ 通过 RPC match_topic_embedding 查询（如不可用则降级为仅实体匹配）

融合评分: entity_score × 0.3 + vector_score × 0.7
  ├─ 阈值 ≥ 0.65 → 判定为同一事件
  ├─ 实体强匹配 (≥ 0.5) → 评分不低于 0.8
  └─ 向量强匹配 (≥ 0.85) → 评分不低于 0.8

聚类: Union-Find 路径压缩 + 按秩合并
  └─ 仅保留跨平台（≥2 个平台）的聚类
```

### 5.6 存储层 (`storage/`)

**PostgREST 客户端**：通过 httpx 调用 Supabase PostgREST API（选择 PostgREST 而非 asyncpg 是因为前者可通过 HTTP/SOCKS 代理工作）。

`SupabaseClient` 封装四类操作：
- `insert()` — 支持 upsert（`Prefer: resolution=merge-duplicates`）和冲突处理
- `update()` — PostgREST 过滤条件的 PATCH 操作
- `select()` — 带过滤的查询
- `rpc()` — 调用 Supabase 数据库函数

**数据库表结构**（参见 `migrations/001_init_tables.sql`）：

| 表名 | 用途 | 关键字段 |
|------|------|---------|
| `topics` | 话题主表 | topic_key (PK), platform_id, title, heat_value, entities, is_on_list |
| `heat_history` | 热度时序 | topic_key (FK), heat_value, rank, fetched_at |
| `topic_embeddings` | 向量嵌入 | topic_key (PK), embedding (vector(512)), model |
| `event_clusters` | 跨平台聚类 | cluster_id (PK), member_keys, platforms, title |
| `snapshots_meta` | 快照元数据 | platform_id, fetched_at, topic_count, duration_ms |
| `platform_config` | 平台配置 | platform_id, display_name, priority |

---

## 6. 配置管理

### 6.1 配置文件 (`config/supabase.yaml`)

```yaml
project:
  url: "https://xxx.supabase.co"
keys:
  anon: "eyJ..."          # iOS 端只读
  service_role: "eyJ..."  # 后端写入
database:
  host: "db.xxx.supabase.co"
  port: 5432
  name: "postgres"
  user: "postgres"
  password: "..."
jina:
  api_key: "jina_..."
  model: "jina-embeddings-v3"
  dimensions: 512
  task: "text-matching"
```

### 6.2 环境变量覆盖

所有 YAML 配置可通过 `TRENDLENS_*` 环境变量覆盖：

| 环境变量 | 覆盖目标 |
|---------|---------|
| `TRENDLENS_SUPABASE_URL` | project.url |
| `TRENDLENS_SERVICE_KEY` | keys.service_role |
| `TRENDLENS_DB_HOST` | database.host |
| `TRENDLENS_DB_PASSWORD` | database.password |
| `TRENDLENS_JINA_KEY` | jina.api_key |

---

## 7. 常量与阈值

所有可调参数集中定义在 `constants.py`：

| 常量 | 值 | 含义 |
|------|---|------|
| `FETCH_CONCURRENCY_LIMIT` | 5 | 并发采集 Semaphore |
| `HTTP_TIMEOUT_SECONDS` | 30 | HTTP 请求超时 |
| `HTTP_MAX_RETRIES` | 3 | 重试次数 |
| `HEAT_MAX` | 10,000,000 | 热度归一化上限 |
| `HEAT_EXPONENT` | 1.5 | 排名指数映射参数 |
| `EMBEDDING_BATCH_SIZE` | 64 | Jina API 批量大小 |
| `EMBEDDING_DIMENSIONS` | 512 | 向量维度 |
| `MATCH_ENTITY_WEIGHT` | 0.3 | 实体匹配权重 |
| `MATCH_VECTOR_WEIGHT` | 0.7 | 向量匹配权重 |
| `MATCH_THRESHOLD` | 0.65 | 匹配判定阈值 |
| `OFFLIST_RETENTION_DAYS` | 90 | 下榜话题保留天数 |
| `SNAPSHOT_RETENTION_DAYS` | 14 | 快照保留天数 |

---

## 8. 错误恢复策略

| 层级 | 策略 |
|------|------|
| HTTP 请求 | tenacity 3 次重试，指数退避 1s/2s/4s，仅重试超时/网络错误 |
| 单个 Fetcher | try/except 全包裹，失败返回 error FetchResult，不影响其他源 |
| Jina API | 失败时跳过嵌入，话题仍正常存储，下轮补嵌入 |
| 数据库写入 | 批量 50 条 UPSERT，单批失败记录日志后继续 |
| 匹配 RPC | vector RPC 不可用时降级为仅实体匹配 |
| 管道级别 | 顶层 catch，记录错误日志，不影响调度器下次触发 |

---

## 9. 日志架构

- **框架**：structlog JSON 格式
- **运行日志**：`logs/runs/run_{timestamp}_{uuid}.log` — 每次 `run_cycle()` 独立文件
- **错误日志**：`logs/errors/errors_{date}.log` — 按日期追加
- **控制台**：INFO+ 级别
- **文件**：DEBUG+ 级别
- **标准字段**：`run_id`, `platform`, `event`, `duration_ms`, `status`, `count`
- **隐私保护**：日志不记录话题标题和内容，仅记录计数和状态

---

## 10. CLI 命令

```bash
# 安装依赖
cd backend && uv sync

# 单次运行 P0 源
uv run python -m trendlens run -p P0

# 单次运行全部优先级
uv run python -m trendlens run -p P0 -p P1 -p P2

# 持续模式（每 15 分钟）
uv run python -m trendlens serve

# 手动清理过期数据
uv run python -m trendlens cleanup
```

---

## 11. 数据流示例

以一次典型的 P0 运行为例（7 个平台，约 320 条话题）：

```
1. 并发采集 7 个平台 → 7 个 FetchResult（约 2-5 秒）
2. 归一化 320 条 RawTopic → 320 条 NormalizedTopic
   - 生成 topic_key（如 "zhihu:1234567890", "weibo:title:a1b2c3d4e5f6g7h8"）
   - 映射热度值到 0..10,000,000
3. jieba 实体提取 → 每条话题 0-5 个实体
4. Jina API 嵌入新话题（已有的跳过）→ 512 维向量
5. UPSERT 到 topics 表，追加 heat_history
6. 下榜检测：标记各平台已不在榜的话题
7. 存储嵌入向量到 topic_embeddings
8. 三信号匹配 → Union-Find 聚类 → 写入 event_clusters
9. 写入 snapshots_meta（每个平台一条记录）
```

---

## 12. 扩展指南

### 添加新平台 Fetcher

1. 在 `fetchers/` 下创建 `{platform}.py`
2. 继承 `BaseFetcher`，设置 `platform_id` 和 `priority`
3. 实现 `async def fetch(self) -> FetchResult`
4. 加上 `@register_fetcher` 装饰器
5. 在 `pipeline.py:run_cycle()` 中添加 import

```python
@register_fetcher
class NewPlatformFetcher(BaseFetcher):
    platform_id = "new_platform"
    priority = "P1"

    async def fetch(self) -> FetchResult:
        # 实现采集逻辑
        ...
```

### 优先级说明

| 优先级 | 含义 | 当前平台 |
|-------|------|---------|
| P0 | 核心源，必须可用 | zhihu, baidu, weibo, bilibili-hs, bilibili-hv, douyin, toutiao |
| P1 | 重要补充源 | 待实现（小红书、36氪、IT之家等） |
| P2 | 扩展源 | 待实现（GitHub Trending、HackerNews 等） |
