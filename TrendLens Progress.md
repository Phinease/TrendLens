# TrendLens 开发进展

> **文档定位：** 当前开发进度与任务追踪（唯一权威来源）
> **阶段定义参考：** [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md) 第 7 章
>
> **当前阶段：** 阶段 2 - 后端数据采集 + 远程数据集成
> **最后更新：** 2026-02-27

---

## 已完成阶段

### 阶段 0：项目基建 ✅（2026-01-21）

Clean Architecture 目录结构、依赖注入容器、Domain/Data/Infrastructure 三层架构、基础导航结构（iPhone TabView / iPad+macOS NavigationSplitView）、炫酷启动页。

### 阶段 0.5：UI 设计深化 ✅（2026-01-22）

Prismatic Flow 设计系统（平台渐变色带、热度光谱、3D 阴影层级）、UI 组件库 14 个组件、热度曲线功能（HeatCurveView、HeatCurveMini、触摸交互）、Feed 页面完整 UI。

### 阶段 1：MVP（本地 SwiftData + Mock 数据）✅（2026-01-23）

MockDataGenerator 动态数据生成（6 平台各 15 条话题）、FeedView/CompareView/SearchView/SettingsView 完整实现、下拉刷新/收藏/屏蔽词过滤。

**技术要点**：SwiftData Predicate 不捕获外部变量（改用内存过滤）、`@MainActor` 隔离、`isRemoteEnabled = false` 配置。

### 阶段 1.5：UI 系统重构（Ethereal Insight）✅（2026-01-24 ~ 2026-02-18）

| Phase | 核心交付 | 完成 |
|-------|---------|------|
| 1.5.1 | DesignSystem 重构、原子级组件库（PlatformIcon、RankChangeIndicator、MiniTrendLine、StandardCard） | ✅ |
| 1.5.2 | HeroCard 实现、FeedView 重构为 Hero+Standard 混合布局 | ✅ |
| 1.5.3 | 官方 TabView + FluidRibbon 集成，平台切换流畅 | ✅ |
| 1.5.4 | CompareView/SearchView 响应式布局（iPad 2列 LazyVGrid）、状态组件（EmptyState/Skeleton/Error） | ✅ |
| 1.5.5 | 卡片交互（缩放反馈、滑动操作、长按菜单）、FluidRibbon 优化（滑动切换、触觉反馈） | ✅ |
| 1.5.6 | TopicDetailView（新闻内容）+ DataAnalyseView（热度数据）分离、卡片导航按钮 | ✅ |
| 1.5.7 | 三端验证与文档更新 | ⏸️ 延后 |

> **1.5.7 延后说明**：深色模式走查、动态字体测试、VoiceOver 测试等验收工作延后至阶段 6（质量与发布）阶段统一执行。三端编译已在各 Phase 中持续验证通过。

---

## 当前阶段

### 阶段 2：后端数据采集 + 远程数据集成 🚧

**目标**：建立 Python 后端数据采集系统，通过 Supabase 存储数据，iOS 应用连接远程数据源替换本地 Mock 数据。

**设计文档**：
- 数据源选型：[backend/docs/hot-news-data-sources-v2.md](backend/docs/hot-news-data-sources-v2.md)
- 数据需求：[backend/docs/data-requirements.md](backend/docs/data-requirements.md)
- 数据存储策略：[backend/docs/data-storage-strategy.md](backend/docs/data-storage-strategy.md)
- 全量调研：[backend/docs/data-sources-v1.md](backend/docs/data-sources-v1.md)

**技术栈**：Python 后端 + Supabase (PostgreSQL + pgvector) + Jina Embeddings v3 + Supabase Data API

**Supabase 配置**：
- Project: TrendLens
- 已启用 Data API（RESTful，用于 iOS 端 supabase-swift 连接）

---

#### 2.1 数据源补充与接口验证 🚧

**目标**：完善 hot-news-data-sources-v2.md，验证所有选定接口的可用性和数据完整度

- [x] **2.1.1 P0 核心源接口验证**（7 源）✅ — 2.3 采集器 + 2.3.9 内容抓取中全部验证
  - [x] zhihu — 热榜列表 ✅ + 内容：热榜 excerpt（~80%）
  - [x] baidu — 热搜列表 ✅ + 内容：description/rawUrl（100%）
  - [x] weibo — 热搜列表 ✅（xxapi.cn）+ 内容：❌ 需登录，暂为 Stub
  - [x] bilibili-hs — 热搜列表 ✅ + 内容：WBI 搜索 API（100%）
  - [x] bilibili-hv — 热门视频 ✅ + 内容：API description（~30%）
  - [x] douyin — 热搜列表 ✅（xxapi.cn）+ 内容：❌ JS 加密，暂为 Stub
  - [x] toutiao — 热榜列表 ✅ + 内容：移动 info API（~30-65%）
- [ ] **2.1.2 P1 补充源接口验证**（6 源）
  - [ ] sina-news, thepaper, tencent-hot, hackernews, 36kr-renqi, douban
- [ ] **2.1.3 P2 延伸源接口验证**（7 源）
  - [ ] wallstreetcn, cankaoxiaoxi, github-trending, netease-news, tieba, ithome, kaopu
- [ ] **2.1.4 补充缺失的数据源**
  - [ ] 评估是否需要新增平台以覆盖数据需求缺口
  - [ ] 更新 data-requirements.md 覆盖矩阵

---

#### 2.2 数据库建模

**目标**：基于 data-requirements.md 设计 Supabase 数据表
**设计规范**：[data-storage-strategy.md](backend/docs/data-storage-strategy.md)

- [x] **2.2.1 确定热度值归一化方案** — 排名映射 + 原始值保留（策略文档 §8）
- [x] **2.2.1b 确定话题身份标识策略** — 混合优先级 topic_key（策略文档 §2）
- [x] **2.2.1c 确定跨平台关联算法** — 三信号融合：时间窗口 + 实体匹配 + Jina 向量相似度（策略文档 §4）
- [x] **2.2.2 设计数据表结构**（策略文档 §3）
  - [x] platforms 表（平台配置）
  - [x] topics 表（话题主体，UPSERT 模式）
  - [x] heat_history 表（热度时间序列）
  - [x] event_clusters 表（跨平台事件聚类）
  - [x] topic_embeddings 表（pgvector 向量嵌入）
  - [x] snapshots_meta 表（快照审计日志）
- [x] **2.2.2b 设计 RLS 策略** — iOS 端 anon 只读，后端 service_role 写入（策略文档 §3.8）
- [x] **2.2.2c 设计数据保留策略** — 7 天全精度 / 90 天降采样保留（策略文档 §7）
- [x] **2.2.5 更新 data-requirements.md 第六章**
- [x] **2.2.3 在 Supabase 中创建表和索引** — 6 张表 + pgvector HNSW 索引 + 20 平台种子数据
- [x] **2.2.4 配置 Row Level Security (RLS)** — anon 只读 4 张公开表，embeddings/snapshots 仅 service_role
- [ ] ~~2.2.6 配置 pg_cron 定时清理~~ — 免费版不支持，改由 Python 后端调度器执行

---

#### 2.3 Python 后端开发

**目标**：实现数据采集管道，定时抓取热榜数据存入 Supabase
**技术栈**：uv + Python 3.14 / httpx / structlog / jieba / Jina Embeddings / Supabase PostgREST
**代码位置**：`backend/src/trendlens/`（45 个 Python 源文件，7 个包）

- [x] **2.3.1 后端项目初始化** ✅
  - [x] uv 项目结构 (`pyproject.toml` + `src/trendlens/` 布局)
  - [x] 依赖管理 (httpx[http2,socks], beautifulsoup4, lxml, jieba, pydantic, click, apscheduler, tenacity, structlog)
  - [x] 配置管理 (`config.py` — YAML + `TRENDLENS_*` 环境变量覆盖)
  - [x] 日志系统 (`log_setup.py` — structlog JSON, 每次运行独立日志文件, 错误按日期归档)
  - [x] CLI 入口 (`cli.py` — `run` / `serve` / `scrape` / `cleanup` 四命令)
  - [x] 数据模型 (`models.py` — RawTopic / FetchResult / NormalizedTopic)
  - [x] .gitignore 更新 (logs/, .venv/, __pycache__/)
- [x] **2.3.2 采集器基础设施** ✅
  - [x] BaseFetcher ABC + `@register_fetcher` 自动注册装饰器
  - [x] 共享 httpx.AsyncClient (HTTP/2, SOCKS 代理, User-Agent 轮换)
  - [x] tenacity 重试策略 (3 次指数退避, 仅重试网络/超时错误)
- [x] **2.3.3 P0 核心源采集器** ✅ (5/7 已验证通过)
  - [x] zhihu — 知乎热榜 (50 条) ✅ 已验证
  - [x] baidu — 百度热搜 HTML 内嵌 JSON 解析 (51 条) ✅ 已验证
  - [x] bilibili-hs — B 站热搜 (20 条) ✅ 已验证
  - [x] bilibili-hv — B 站热门视频 (49 条) ✅ 已验证
  - [x] toutiao — 今日头条热榜 (50 条) ✅ 已验证
  - [x] weibo — 微博热搜 via xxapi.cn (52 条) ✅ 已验证
  - [x] douyin — 抖音热搜 via xxapi.cn (50 条, 含 hot_value/图片) ✅ 已验证
- [x] **2.3.4 数据处理管道** ✅
  - [x] topic_key 三级降级生成 (source_id → URL → title hash)
  - [x] 热度排名映射归一化 (0..10,000,000 指数衰减)
  - [x] 标题规范化 (去标点/空白, 保留中英文数字, 小写化)
  - [x] jieba 命名实体提取 (nr/ns/nt/nz/nrt/vn)
  - [x] Jina API 批量嵌入 (64 条/批, 512 维, 失败降级)
- [x] **2.3.5 存储层** ✅ (Supabase PostgREST via httpx)
  - [x] PostgREST 客户端 (`client.py` — upsert/update/select/rpc)
  - [x] topics UPSERT + heat_history APPEND (`topic_store.py`)
  - [x] 下榜检测 (mark_offlist)
  - [x] 向量嵌入存储 (`embedding_store.py`)
  - [x] 事件聚类 CRUD (`cluster_store.py`)
  - [x] 快照元数据 (`snapshot_store.py`)
  - [x] 数据清理 (`maintenance.py` — 复刻 002_cron_jobs.sql)
- [x] **2.3.6 匹配算法** ✅
  - [x] 三信号融合 (实体 Jaccard 0.3 + 向量余弦 0.7, 阈值 0.65)
  - [x] Union-Find 聚类
  - [x] 实体候选生成 (内存倒排索引)
  - [x] 向量候选生成 (RPC 函数预留, 当前降级为实体模式)
- [x] **2.3.7 编排器 + 调度器** ✅
  - [x] `pipeline.py` 完整流程 (fetch → normalize → entity → embed → upsert → **scrape** → offlist → match → snapshot)
  - [x] `scheduler.py` APScheduler 持续模式 (每 15 分钟)
  - [x] 并发控制 (asyncio.Semaphore=5)
  - [x] 错误恢复 (单源失败不影响其他, 批量写入失败降级为逐条)

> **首次端到端运行验证** (2026-02-25):
> - 5 平台成功采集 220 条话题
> - 220 条 Jina 嵌入生成 (4 批次, ~10s)
> - 220 条 topics + heat_history 写入 Supabase
> - 220 条向量嵌入存入 topic_embeddings
> - 1 个跨平台事件聚类产生
> - 5 条 snapshots_meta 记录
> - 总耗时 ~29 秒
>
> **第二次运行** (weibo + douyin 切换 xxapi.cn 后):
> - **7/7 平台全部成功**，323 条话题
> - baidu (51), bilibili-hs (20), bilibili-hv (50), douyin (50), toutiao (50), weibo (52), zhihu (50)
> - 124 条新嵌入 (仅新话题)，2 个跨平台聚类
> - 下榜检测: baidu 4条, bilibili-hs 2条, toutiao 14条, zhihu 1条
> - 总耗时 ~30 秒

- [x] **2.3.8 数据源修复** ✅
  - [x] weibo: 改用 xxapi.cn 免登录 API (52 条, 含热度值)
  - [x] douyin: 改用 xxapi.cn 免登录 API (50 条, 含 hot_value/sentence_id/图片)
- [x] **2.3.9 内容抓取 (Content Scraping)** ✅
  - [x] NormalizedTopic 新增 `content` 字段，topic_store upsert 条件写入
  - [x] 抓取框架 (`scraping/base.py` — BaseScraper ABC + `@register_scraper` 注册器)
  - [x] HTML 工具 (`scraping/html_utils.py` — html_to_text, truncate, clean_content)
  - [x] 7 平台 Scraper 实现:
    - [x] bilibili-hv — 直接用 API 已有 description（~30% 话题有 desc）
    - [x] zhihu — 用热榜 API 已有的 excerpt（~80% 话题有，常 200-800 字）
    - [x] baidu — description > 50 字符直接用，否则抓取 rawUrl（100% 成功率）
    - [x] toutiao — `m.toutiao.com/i{source_id}/info/` 移动 API（~30-65% 有文章内容，其余为话题聚合页无正文）
    - [x] bilibili-hs — B 站 WBI 搜索 API `/wbi/search/type`（100% 成功率）
    - [x] weibo — Stub（搜索 API 需登录，xxapi 无内容字段）
    - [x] douyin — Stub（搜索页爬取复杂，按 v2 文档建议延后至 AI 摘要）
  - [x] 编排器 (`scraping/scraper_manager.py` — 并发控制 Semaphore=10, DB 过滤去重)
  - [x] Pipeline 集成 (Step 6.5: upsert 后、mark_offlist 前)
  - [x] CLI `scrape` 独立命令 (`uv run python -m trendlens scrape`)
  - [x] 常量: SCRAPE_CONCURRENCY_LIMIT=10, SCRAPE_TOP_N_PER_PLATFORM=20, SCRAPE_CONTENT_MAX_LENGTH=5000
  - [x] 存储层 (`storage/content_store.py` — 查询无 content 话题 + 批量更新)

> **Content Scraping 端到端验证** (2026-02-25):
> - 完整管道含 Step 6.5, 7/7 平台, 323 话题, 47 条新内容写入
> - baidu 20/20, bilibili-hs 8/8, toutiao 6/20, zhihu 11/20, bilibili-hv 2/20
> - weibo/douyin 为 Stub（需登录/AI 摘要）
> - 总管道耗时 ~43 秒（含 content scraping ~20 秒）

- [x] **2.3.10 Content 质量过滤** ✅
  - [x] LLM 编号过滤法（`processing/quality_filter.py`）：标题+描述编号 → LLM 输出拒绝编号列表
  - [x] Pipeline 集成 Step 2.5：归一化后、实体提取前，被过滤 topic 不进入后续步骤
  - [x] content = description 去重：`content_store.batch_update_content` 写入前比对，重复则跳过
  - [x] `scraper_manager.py` 传入 description 供 content_store 比对
  - [x] CLI `filter-quality` 命令（dry-run 查看过滤效果）
  - [x] CLI `truncate-all` 命令（清空全部数据表，应用未上线重置）
  - [x] `SupabaseClient.delete()` 方法
  - [x] 常量：`QUALITY_FILTER_BATCH_SIZE=50`, `QUALITY_LLM_TEMPERATURE=0.1`
  - [x] 文档更新：backend-architecture.md §4 管道流程 + §5.7 Quality Filter
- [x] **2.3.11 热力数据采集** ✅
  - [x] 数据库迁移（`003_trend_tables.sql`）：trend_keywords / topic_trend_links / trend_data 三张新表 + RPC + RLS
  - [x] heat_history 增强：新增 raw_heat_value 列（ALTER TABLE + topic_store 写入）
  - [x] LLM 客户端（`processing/llm_client.py`）：httpx 异步封装 Anthropic Messages API + tenacity 重试
  - [x] AI 关键词提取（`processing/keyword_extractor.py`）：jieba 粗提取 → LLM 语境扩展 → 精确字符串去重
  - [x] 停用词过滤：标准中文停用词表（哈工大+百度+cn, 1860 词）+ 趋势领域补充词表（`data/stopwords_zh.txt` + `data/trend_stopwords.txt`）
  - [x] LLM Prompt 优化：明确禁止泛化行业词、通用概念词、情感短语
  - [x] 趋势数据存储（`storage/trend_store.py`）：keywords/links/data CRUD + 查询统计 + 清理
  - [x] Google Trends 采集器（`processing/trend_collector.py`）：pytrends + asyncio.to_thread + 限流 + 降级
  - [x] 趋势管道（`trend_pipeline.py`）：独立 60 分钟周期
  - [x] 主管道集成：Step 6.3 关键词提取 + 存储（pipeline.py）
  - [x] 调度器集成：trend_cycle 60 分钟 job（scheduler.py）
  - [x] CLI 新增 `extract-keywords` / `collect-trends` 命令
  - [x] trend_data 数组存储重构（`004_trend_data_array.sql`）：per-point → per-keyword，timestamps[] + trend_values[]
  - [x] 维护集成：trend_data 清理 + 关键词停用（maintenance.py）
  - [x] 配置：LLMConfig / TrendConfig 新增（config.py, constants.py, supabase.example.yaml）
  - [x] 依赖：pytrends>=4.9（pyproject.toml）
- [x] **2.3.12 Tag 数据补充** ✅
  - [x] LLM 内容分类：15 个预设类别（`CONTENT_CATEGORIES`），与关键词提取合并到同一 LLM 调用
  - [x] Tag 合并算法（`merge_tags()`）：categories ∪ keywords ∪ platform_tags → `topics.tags`
  - [x] 抖音状态标签过滤（`DOUYIN_STATUS_LABELS`：新/推荐/热/爆/首映）
  - [x] 批量写入（`batch_update_tags()`）：pipeline Step 6.4 + CLI extract-keywords
- [ ] **2.3.13 向量嵌入存储验证**
  - [ ] 确认 Supabase 免费版对 pgvector 的支持情况（存储上限、HNSW 索引限制）
  - [ ] 验证当前 topic_embeddings 写入是否正常持久化
  - [ ] 部署 Supabase RPC 函数 `match_topic_embedding` 以启用向量匹配
- [ ] **2.3.14 P1/P2 源扩展** (后续)
  - [ ] 实现 P1 源（6 个）
  - [ ] 实现 P2 源（7 个）
  - [ ] 数据质量验证

---

#### 2.4 iOS 远程数据层

**目标**：iOS 应用连接 Supabase 获取真实数据，替换本地 Mock

- [ ] **2.4.1 Supabase Swift SDK 集成**
  - [ ] 添加 supabase-swift 依赖
  - [ ] 配置 Supabase Client（URL + anon key）
- [ ] **2.4.2 RemoteDataSource 实现**
  - [ ] 实现 `RemoteTrendingDataSource`（基于 Supabase API）
  - [ ] 数据模型映射（Supabase JSON → TrendTopicEntity）
  - [ ] 平台枚举更新（根据实际可用数据源调整）
- [ ] **2.4.3 缓存与离线策略**
  - [ ] ETag 支持（304 响应处理）
  - [ ] 本地 SwiftData 缓存（validUntil TTL）
  - [ ] 离线模式降级（使用过期缓存 + 标记）
- [ ] **2.4.4 数据刷新**
  - [ ] 手动下拉刷新触发网络请求
  - [ ] 自动刷新间隔（配合 validUntil）
  - [ ] 多平台并行请求（TaskGroup）
- [ ] **2.4.5 端到端验证**
  - [ ] 后端采集 → Supabase 存储 → iOS 读取 → UI 展示
  - [ ] 三端编译验证（iPhone/iPad/Mac）
  - [ ] 错误处理与降级测试

---

#### 2.5 平台枚举调整

**目标**：根据实际数据源可用性更新 iOS 端 Platform 枚举

> **当前状态**：iOS 端有 6 个平台（weibo/xiaohongshu/bilibili/douyin/x/zhihu），其中小红书和 X 无可靠数据源。
> 此任务在后端核心功能稳定后再执行。

- [ ] **2.5.1 确定最终平台列表**
- [ ] **2.5.2 更新 Platform.swift 枚举**
- [ ] **2.5.3 更新 UI 组件中的平台引用**
- [ ] **2.5.4 三端编译验证**

---

## ⚠️ 重要开发原则

**阶段 2 开发原则：**

1. **后端先行**：先完成后端数据采集，确认数据质量，再对接 iOS 端
2. **逐源验证**：每实现一个数据源，立即验证数据完整性和正确性
3. **数据优先于 UI**：先确保数据管道稳定，UI 调整随后进行
4. **保持 Mock 兼容**：iOS 端保留 Mock 数据能力，方便开发调试

**编译要求**

```bash
# iOS Simulator
xcodebuild -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# iPad Simulator
xcodebuild -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'

# macOS
xcodebuild -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=macOS'
```

---

## 未来阶段

### 阶段 3：后台刷新 + 通知

- BGTaskScheduler 集成
- 本地通知（热点突发提醒、收藏话题更新）
- 电量和流量优化

### 阶段 5：用户体系（可选）

- BaaS 选型和集成
- 云端偏好同步（收藏、屏蔽词、订阅平台）
- 匿名用户迁移
- 隐私和安全

### 阶段 6：质量与发布

- 单元测试（Domain 90%, Data 80%, Presentation 75%）
- UI 测试
- 性能优化（启动 < 2s, 列表 60fps）
- 深色模式走查、动态字体、VoiceOver（原 Phase 1.5.7 内容）
- 隐私合规
- 发布准备（App Store 提交）

---

## 术语参考

所有项目术语定义见 [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md) 第 10 章。
