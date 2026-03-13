# TrendLens 关键文件索引

> **文档定位：** 跨模块修改时的快速文件导航
> **Claude Code 指引：** [CLAUDE.md](../CLAUDE.md)

---

## iOS 客户端

### 核心实体

| 文件 | 职责 |
|------|------|
| [Core/Domain/Entities/Platform.swift](TrendLens/Core/Domain/Entities/Platform.swift) | 平台枚举 |
| [Core/Domain/Entities/TrendTopic.swift](TrendLens/Core/Domain/Entities/TrendTopic.swift) | 话题实体与 SwiftData Model |
| [Core/Domain/Entities/TrendSnapshot.swift](TrendLens/Core/Domain/Entities/TrendSnapshot.swift) | 快照实体（含 TTL/ETag） |

### Repository 协议

| 文件 | 职责 |
|------|------|
| [Core/Domain/Repositories/TrendingRepository.swift](TrendLens/Core/Domain/Repositories/TrendingRepository.swift) | 热榜数据访问协议 |
| [Core/Domain/Repositories/UserPreferenceRepository.swift](TrendLens/Core/Domain/Repositories/UserPreferenceRepository.swift) | 用户偏好访问协议 |

### 基础设施

| 文件 | 职责 |
|------|------|
| [Core/Infrastructure/Network/NetworkClient.swift](TrendLens/Core/Infrastructure/Network/NetworkClient.swift) | 网络层（ETag 支持） |
| [App/DependencyContainer.swift](TrendLens/App/DependencyContainer.swift) | 依赖注入配置 |

---

## Python 后端

### 管道核心

| 文件 | 职责 |
|------|------|
| [backend/src/trendlens/pipeline.py](backend/src/trendlens/pipeline.py) | 管道编排器（10 步流程） |
| [backend/src/trendlens/models.py](backend/src/trendlens/models.py) | 核心数据模型（RawTopic, NormalizedTopic） |
| [backend/src/trendlens/constants.py](backend/src/trendlens/constants.py) | 全局阈值与常量 |
| [backend/src/trendlens/config.py](backend/src/trendlens/config.py) | 配置加载（YAML + env） |

### 采集器

| 文件 | 职责 |
|------|------|
| [backend/src/trendlens/fetchers/base.py](backend/src/trendlens/fetchers/base.py) | Fetcher 基类 + @register_fetcher 注册表 |
| [backend/src/trendlens/fetchers/http_client.py](backend/src/trendlens/fetchers/http_client.py) | httpx AsyncClient + tenacity 重试 |
| [backend/src/trendlens/fetchers/zhihu.py](backend/src/trendlens/fetchers/zhihu.py) | 知乎热榜 |
| [backend/src/trendlens/fetchers/baidu.py](backend/src/trendlens/fetchers/baidu.py) | 百度热搜 |
| [backend/src/trendlens/fetchers/weibo.py](backend/src/trendlens/fetchers/weibo.py) | 微博热搜（xxapi.cn） |
| [backend/src/trendlens/fetchers/bilibili_hs.py](backend/src/trendlens/fetchers/bilibili_hs.py) | B站热搜 |
| [backend/src/trendlens/fetchers/bilibili_hv.py](backend/src/trendlens/fetchers/bilibili_hv.py) | B站热门视频 |
| [backend/src/trendlens/fetchers/douyin.py](backend/src/trendlens/fetchers/douyin.py) | 抖音热榜（xxapi.cn） |
| [backend/src/trendlens/fetchers/toutiao.py](backend/src/trendlens/fetchers/toutiao.py) | 今日头条 |

### 内容抓取

| 文件 | 职责 |
|------|------|
| [backend/src/trendlens/scraping/base.py](backend/src/trendlens/scraping/base.py) | Scraper 基类 + @register_scraper 注册表 |
| [backend/src/trendlens/scraping/html_utils.py](backend/src/trendlens/scraping/html_utils.py) | HTML→文本转换、截断、清理 |
| [backend/src/trendlens/scraping/scraper_manager.py](backend/src/trendlens/scraping/scraper_manager.py) | 抓取编排器（并发控制、DB 过滤、分发） |
| [backend/src/trendlens/scraping/zhihu.py](backend/src/trendlens/scraping/zhihu.py) | 知乎（用热榜 excerpt） |
| [backend/src/trendlens/scraping/baidu.py](backend/src/trendlens/scraping/baidu.py) | 百度（description 优先，fallback rawUrl） |
| [backend/src/trendlens/scraping/toutiao.py](backend/src/trendlens/scraping/toutiao.py) | 头条（移动 info API） |
| [backend/src/trendlens/scraping/bilibili_hs.py](backend/src/trendlens/scraping/bilibili_hs.py) | B站热搜（WBI 搜索 API） |
| [backend/src/trendlens/scraping/bilibili_hv.py](backend/src/trendlens/scraping/bilibili_hv.py) | B站热门（API description） |
| [backend/src/trendlens/scraping/weibo.py](backend/src/trendlens/scraping/weibo.py) | 微博（Stub — 需登录） |
| [backend/src/trendlens/scraping/douyin.py](backend/src/trendlens/scraping/douyin.py) | 抖音（Stub — 延后至 AI 摘要） |
| [backend/src/trendlens/storage/content_store.py](backend/src/trendlens/storage/content_store.py) | content 查询与批量更新 |

### 处理管道

| 文件 | 职责 |
|------|------|
| [backend/src/trendlens/processing/normalizer.py](backend/src/trendlens/processing/normalizer.py) | topic_key 生成 + 热度归一化 |
| [backend/src/trendlens/processing/entity_extractor.py](backend/src/trendlens/processing/entity_extractor.py) | jieba POS 命名实体提取 |
| [backend/src/trendlens/processing/embedder.py](backend/src/trendlens/processing/embedder.py) | Jina API 批量嵌入（512d） |
| [backend/src/trendlens/processing/llm_client.py](backend/src/trendlens/processing/llm_client.py) | Anthropic Messages API 异步客户端 |
| [backend/src/trendlens/processing/quality_filter.py](backend/src/trendlens/processing/quality_filter.py) | LLM 内容质量过滤（编号拒绝列表） |
| [backend/src/trendlens/processing/keyword_extractor.py](backend/src/trendlens/processing/keyword_extractor.py) | AI 关键词提取（jieba + LLM + 去重） |
| [backend/src/trendlens/processing/trend_collector.py](backend/src/trendlens/processing/trend_collector.py) | Google Trends 数据采集（pytrends + asyncio.to_thread） |

### 匹配与聚类

| 文件 | 职责 |
|------|------|
| [backend/src/trendlens/matching/matcher.py](backend/src/trendlens/matching/matcher.py) | 三信号融合匹配算法 |
| [backend/src/trendlens/matching/union_find.py](backend/src/trendlens/matching/union_find.py) | Union-Find 路径压缩聚类 |

### 存储层

| 文件 | 职责 |
|------|------|
| [backend/src/trendlens/storage/client.py](backend/src/trendlens/storage/client.py) | PostgREST httpx 客户端 |
| [backend/src/trendlens/storage/topic_store.py](backend/src/trendlens/storage/topic_store.py) | topics UPSERT + heat_history |
| [backend/src/trendlens/storage/embedding_store.py](backend/src/trendlens/storage/embedding_store.py) | topic_embeddings 读写 |
| [backend/src/trendlens/storage/cluster_store.py](backend/src/trendlens/storage/cluster_store.py) | event_clusters 创建/合并 |
| [backend/src/trendlens/storage/snapshot_store.py](backend/src/trendlens/storage/snapshot_store.py) | snapshots_meta 写入 |
| [backend/src/trendlens/storage/trend_store.py](backend/src/trendlens/storage/trend_store.py) | 趋势关键词/数据 CRUD + 清理 |
| [backend/src/trendlens/storage/maintenance.py](backend/src/trendlens/storage/maintenance.py) | 数据清理 |
| [backend/src/trendlens/trend_pipeline.py](backend/src/trendlens/trend_pipeline.py) | 趋势数据采集独立管道（60 分钟周期） |

---

## 设计文档

| 文件 | 职责 |
|------|------|
| [backend/docs/backend-architecture.md](../backend/docs/backend-architecture.md) | Python 后端完整架构 |
| [backend/docs/data-storage-strategy.md](../backend/docs/data-storage-strategy.md) | topic_key、归一化、匹配算法规范 |
| [backend/docs/data-requirements.md](../backend/docs/data-requirements.md) | 数据需求与字段映射 |
| [backend/docs/hot-news-data-sources-v2.md](../backend/docs/hot-news-data-sources-v2.md) | 20 个数据源接口规范 |
| [backend/migrations/001_init_tables.sql](backend/migrations/001_init_tables.sql) | 数据库 Schema（6 张表 + pgvector） |
| [backend/migrations/002_cron_jobs.sql](backend/migrations/002_cron_jobs.sql) | 定时清理 SQL |
| [backend/migrations/003_trend_tables.sql](backend/migrations/003_trend_tables.sql) | 趋势数据表（3 张 + RPC + RLS） |
