# TrendLens 技术架构文档

> **文档定位：** 技术实现规范的权威来源（架构、技术栈、模块职责、并发模型、编码规范）
> **产品规划参考：** [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md)
> **当前进度查询：** [TrendLens Progress.md](TrendLens%20Progress.md)
>
> 基于 iOS 26 / iPadOS 26 / macOS 26 SDK（Xcode 26, Swift 6.2）

---

## 1. 整体架构

> **[权威定义]** 本章节为架构分层的唯一定义来源，其他文档请引用本章节。

采用 **Clean Architecture + MVVM** 分层架构。

```
┌─────────────────────────────────────────────────┐
│  Presentation: SwiftUI Views + ViewModels       │
├─────────────────────────────────────────────────┤
│  Domain: UseCases + Entities + Repository Proto │
├─────────────────────────────────────────────────┤
│  Data: Repository Impl + Local/Remote DataSource│
├─────────────────────────────────────────────────┤
│  Infrastructure: Network + Logging + Background │
└─────────────────────────────────────────────────┘
```

---

## 2. 目录结构

```
TrendLens/
├── App/                    # 入口、依赖注入
├── Features/               # 功能模块
│   ├── Feed/               # 首页热榜（All）
│   │   ├── Views/
│   │   │   ├── FeedView.swift
│   │   │   └── TopicDetailView.swift    # 话题详情页（独立导航页面）
│   │   ├── ViewModels/
│   │   │   └── FeedViewModel.swift
│   │   └── Components/
│   ├── Compare/            # 对比页（交集/差集）
│   ├── Search/             # 搜索/收藏
│   ├── Settings/           # 设置
│   └── [Feature]/
│       ├── Views/
│       ├── ViewModels/
│       └── Components/
├── Core/
│   ├── Domain/
│   │   ├── Entities/       # Topic, Snapshot, Platform, UserPreference
│   │   ├── UseCases/       # FetchTrending, ComparePlatforms, Search, ManageFavorites
│   │   └── Repositories/   # Protocol 定义
│   ├── Data/
│   │   ├── Repositories/   # Protocol 实现
│   │   ├── DataSources/    # Local (SwiftData) + Remote (Network)
│   │   └── Mappers/        # DTO ↔ Entity ↔ Model
│   └── Infrastructure/     # Network, Logging, BackgroundTasks
├── UIComponents/           # 可复用组件
│   ├── Navigation/         # FluidRibbon
│   ├── Cards/              # HeroCard, StandardCard, PlatformIcon
│   ├── Charts/             # HeatCurveView, MiniTrendLine
│   ├── States/             # EmptyStateView, SkeletonCard
│   └── Modifiers/          # CardStyle, HeatEffectModifier
├── Extensions/
└── Resources/
```

---

## 3. 技术栈

> **[权威定义]** 本章节为技术栈选型的唯一定义来源。

### iOS 客户端

| 类别 | 技术 |
|------|------|
| UI | SwiftUI（Liquid Glass、3D Layout、WebView） |
| 状态管理 | `@Observable`（MVVM） |
| 持久化 | SwiftData（Model Inheritance、Persistent History） |
| 网络 | supabase-swift 2.x（Supabase Data API） |
| 图表 | Swift Charts（含 3D） |
| 小组件 | WidgetKit |
| 后台刷新 | BGTaskScheduler |
| 日志 | OSLog |

### 后端（Python）

> 详细技术栈说明见 [backend/docs/backend-architecture.md](backend/docs/backend-architecture.md) §3

| 类别 | 技术 |
|------|------|
| 语言 | Python 3.12+ |
| 包管理 | uv |
| HTTP 客户端 | httpx[http2,socks]（异步、代理支持） |
| HTML 解析 | BeautifulSoup4 + lxml |
| 中文分词 | jieba（POS 实体提取） |
| 向量嵌入 | Jina Embeddings v3（512d） |
| 数据库 | Supabase（PostgreSQL + pgvector） |
| 存储接口 | PostgREST via httpx |
| 数据验证 | Pydantic v2 |
| 调度 | APScheduler v3 |
| 重试 | tenacity |
| 日志 | structlog（JSON） |
| CLI | Click |
| 配置 | PyYAML + 环境变量覆盖 |

---

## 4. Swift 6.2 并发模型

> **[权威定义]** 本章节为并发模型与 Actor 隔离策略的唯一定义来源。

**关键变化**：新项目默认 `@MainActor` 隔离

| 层级 | 隔离策略 |
|------|----------|
| View / ViewModel | `@MainActor`（默认） |
| UseCase | `Sendable`，可在任意 Actor 调用 |
| Repository / DataSource | `nonisolated` 标记需要后台执行的方法 |

**项目设置**：

- Default Actor Isolation: `MainActor`
- Strict Concurrency Checking: `Complete`
- Swift Language Mode: `6`

---

## 5. 模块职责边界

> **[权威定义]** 本章节为模块职责与边界的唯一定义来源。

| 层级 | 组件 | 职责 | 禁止 |
|------|------|------|------|
| Presentation | View | UI 渲染、交互响应 | 业务逻辑、IO 操作 |
| Presentation | ViewModel | 状态管理、调用 UseCase | 直接访问 DataSource |
| Domain | Entity | 业务数据结构 | 依赖任何框架 |
| Domain | UseCase | 单一业务操作 | 直接 IO 操作 |
| Data | Repository | 协调数据源、缓存策略 | UI 代码 |
| Data | DataSource | 单一数据源读写 | 业务逻辑 |
| Infrastructure | NetworkClient | HTTP 封装 | 业务逻辑 |

---

## 6. 数据流与缓存策略

> **[权威定义]** 本章节为数据流与缓存策略的唯一定义来源。

### 阶段 1（本地 Mock）

```
View → ViewModel → UseCase → Repository → LocalDataSource (SwiftData)
                                               ↑
                                        MockDataGenerator
```

### 阶段 2（远程 Supabase）

```
View → ViewModel → UseCase → Repository ─→ RemoteDataSource (Supabase API)
                                        └→ LocalDataSource (SwiftData 缓存)
```

```
[后端数据管道] (详见 backend/docs/backend-architecture.md §4)
Fetcher → Normalizer → Entity Extractor → Embedder → Storage → Scraper → Matcher
  │           │              │                │          │          │         │
  │           │              │                │          │          │         └─ 三信号融合 + Union-Find
  │           │              │                │          │          └─ 内容抓取（5 平台，仅无 content 话题）
  │           │              │                │          └─ PostgREST UPSERT
  │           │              │                └─ Jina v3 512d（仅新话题）
  │           │              └─ jieba POS 命名实体
  │           └─ topic_key 三级降级 + 热度排名映射
  └─ 7 平台并发采集（15 分钟间隔）
```

### 缓存策略

1. 检查 validUntil 判断缓存有效性（TTL 15 分钟，匹配后端采集间隔）
2. 有效 → 返回 SwiftData 本地缓存
3. 过期 → 请求 Supabase
4. 200 响应 → 更新本地缓存
5. 网络失败 → 返回过期缓存（带「数据已过期」标记）

---

## 7. 依赖注入

使用 `DependencyContainer` 单例管理依赖：

- 提供 `make[ViewModel]()` 工厂方法
- 支持测试时替换为 Mock 实现

---

## 8. 编码规范

> **[权威定义]** 本章节为编码规范的唯一定义来源。

### 命名

- 类型：`PascalCase`
- 变量/函数：`camelCase`
- 文件名与主类型一致

### View 结构

```
@State 属性 → @Environment → 常规属性 → body → 子视图 → 方法
```

### ViewModel 结构

```
Published State (private(set)) → Dependencies → Init → Public Methods
```

### 错误处理

定义领域错误类型，Repository 层统一转换

### 导航模式

**标准导航栈（推荐）：**

```swift
// 列表页
NavigationStack {
    List(items) { item in
        NavigationLink(destination: DetailView(item: item)) {
            ItemRow(item: item)
        }
        .buttonStyle(.plain)  // 保持自定义样式
    }
}
```

**使用场景：**
- 详情页：使用 NavigationLink（如 TopicDetailView）
- 全屏模态：使用 `.sheet(item:)` 或 `.fullScreenCover(item:)`
- 临时弹出：使用 `.sheet(item:)` + `.presentationDetents([.medium])`

**最佳实践：**
- 优先使用系统标准导航（NavigationStack + NavigationLink）
- 仅在必要时使用自定义转场动画
- 保持导航层级清晰，避免嵌套超过 3 层

---

## 9. 版本要求

| 平台 | 最低版本 |
|------|----------|
| iOS / iPadOS | 26.0 |
| macOS | 26.0 (Tahoe) |
| Xcode | 26.0 |
| Swift | 6.2 |

---

## 10. 后端架构（Python + Supabase）

> **[权威定义]** 本章节为后端架构的概述入口。
> **完整后端架构文档：** [backend/docs/backend-architecture.md](backend/docs/backend-architecture.md)
> **数据源规范：** [backend/docs/hot-news-data-sources-v2.md](backend/docs/hot-news-data-sources-v2.md)
> **存储设计规范：** [backend/docs/data-storage-strategy.md](backend/docs/data-storage-strategy.md)
> **数据需求文档：** [backend/docs/data-requirements.md](backend/docs/data-requirements.md)

### 10.1 后端目录结构

```
backend/
├── pyproject.toml                  # uv 项目定义 + 依赖
├── config/
│   ├── supabase.yaml               # 密钥配置（gitignored）
│   └── supabase.example.yaml       # 配置模板
├── data/                           # 65 个 API 样本文件（开发验证用）
├── docs/                           # 设计文档
├── migrations/                     # SQL 迁移脚本
├── logs/                           # 运行时日志（gitignored）
└── src/
    └── trendlens/                  # Python 包
        ├── cli.py                  # Click CLI（run / serve / scrape / cleanup）
        ├── config.py               # Pydantic 配置（YAML + env）
        ├── constants.py            # 全局阈值与常量
        ├── models.py               # RawTopic / FetchResult / NormalizedTopic
        ├── pipeline.py             # 编排器：11 步完整管道（含 Step 6.5 内容抓取）
        ├── scheduler.py            # APScheduler 持续调度
        ├── log_setup.py            # structlog 日志配置
        ├── fetchers/               # 7 个 P0 平台采集器 + 基础设施
        ├── scraping/               # 7 个 P0 平台内容抓取器 + 编排器
        ├── processing/             # normalizer + entity_extractor + embedder
        ├── matching/               # 三信号融合匹配 + Union-Find
        └── storage/                # PostgREST 客户端 + 6 个 store 模块
```

### 10.2 数据管道架构

```
┌──────────┐  ┌────────────┐  ┌──────────┐  ┌─────────┐  ┌───────────┐  ┌──────────┐
│ Fetcher  │→│ Normalizer │→│ Embedder │→│ Storage │→│  Scraper  │→│ Matcher  │
│ 7平台并发 │  │ key+热度   │  │ Jina 512d│  │ UPSERT  │  │ 内容抓取   │  │ 三信号+UF │
└──────────┘  └────────────┘  └──────────┘  └─────────┘  └───────────┘  └──────────┘
      │              │                                         │
      │              └─ jieba 实体提取                          └─ 5 平台并发（Sem=10）
      │                                                          DB 过滤仅新话题
      └─ tenacity 重试 + httpx HTTP/2 + SOCKS 代理
```

**管道各阶段职责**：

| 阶段 | 模块 | 输入 | 输出 | 频率 |
|------|------|------|------|------|
| 采集 | `fetchers/` | 平台 API | `FetchResult` (RawTopic[]) | 每 15 分钟 |
| 归一化 | `processing/normalizer.py` | RawTopic | NormalizedTopic (topic_key + heat) | 同采集 |
| 实体提取 | `processing/entity_extractor.py` | 标题文本 | 命名实体列表 | 同采集 |
| 嵌入 | `processing/embedder.py` | 标题文本 | 512 维向量 | 仅新话题 |
| 存储 | `storage/` | NormalizedTopic | Supabase 6 张表 | 同采集 |
| 内容抓取 | `scraping/` | DB 中无 content 的话题 | topics.content 列 | 仅新话题（Step 6.5） |
| 匹配 | `matching/matcher.py` | 实体 + 向量 | event_clusters | 同采集 |

### 10.3 Supabase 集成

**连接方式**：

| 端 | 接口 | 用途 |
|----|-----|------|
| Python 后端 | PostgREST via httpx | 写入采集数据（UPSERT/PATCH） |
| iOS 客户端 | `supabase-swift` | 读取数据（SELECT + 实时订阅） |

**选择 PostgREST 的原因**：asyncpg 直连走 TCP 无法通过 SOCKS 代理，PostgREST 走 HTTP 可以。

**安全策略**：
- Row Level Security (RLS) 启用
- `anon` key：只允许 SELECT（iOS 端只读）
- `service_role` key：允许 INSERT/UPDATE/DELETE（仅后端使用）

**数据库 Schema（6 张表 + pgvector）**：

| 表 | 用途 |
|----|------|
| `topics` | 话题主表（topic_key PK） |
| `heat_history` | 热度时序数据 |
| `topic_embeddings` | 512 维向量嵌入 |
| `event_clusters` | 跨平台事件聚类 |
| `snapshots_meta` | 快照元数据 |
| `platform_config` | 平台配置 |

### 10.4 iOS 远程数据层

**平台枚举**（7 平台，与后端 platform_id 一致）：

| 枚举 case | rawValue | 显示名 |
|-----------|----------|--------|
| weibo | "weibo" | 微博 |
| zhihu | "zhihu" | 知乎 |
| baidu | "baidu" | 百度 |
| bilibiliHotSearch | "bilibili-hs" | B站热搜 |
| bilibiliHotVideo | "bilibili-hv" | B站热门 |
| douyin | "douyin" | 抖音 |
| toutiao | "toutiao" | 头条 |

**组件**：

| 组件 | 位置 | 职责 |
|------|------|------|
| `supabaseClient` | Infrastructure/Network/SupabaseConfig.swift | nonisolated(unsafe) 全局 SupabaseClient 实例 |
| `RemoteTrendingDataSource` | Data/DataSources/Remote/ | actor，通过 Supabase SDK 查询话题/热度历史/搜索 |
| DTO 层 | 同上 | SupabaseTopicDTO / RankChangeDTO / SupabaseHeatHistoryDTO |

**Supabase 配置**：xcconfig（gitignored）→ Info.plist 注入 → Bundle.main 读取

**RemoteTrendingDataSource 方法**：

| 方法 | Supabase 查询 | 说明 |
|------|--------------|------|
| `fetchTopics(for:)` | topics WHERE platform_id = ? AND is_on_list ORDER BY rank | 单平台在榜话题 |
| `fetchAllOnListTopics()` | topics WHERE is_on_list ORDER BY heat_value DESC LIMIT 200 | 全平台 |
| `fetchHeatHistory(for:)` | heat_history WHERE topic_key = ? ORDER BY timestamp DESC LIMIT 96 | 懒加载，仅详情页 |
| `searchTopics(query:)` | topics WHERE title ILIKE %query% AND is_on_list | 直接搜索 |
| `fetchSnapshot(for:)` | 调用 fetchTopics + 合成 TrendSnapshotEntity | 快照合成（无后端 snapshot 表） |

**快照合成**：后端无 snapshot 表，由 RemoteTrendingDataSource 合成：id = platform_timestamp, validUntil = now + 900s, contentHash = SHA256(sorted topic_keys)

**热度历史策略**：列表页不加载（heatHistory: []），仅在 getTopicDetail 时懒加载

**Repository 策略**：

```swift
// Remote-first, Local-cache, Stale fallback
func fetchLatestSnapshot(for platform: Platform, forceRefresh: Bool) async throws -> TrendSnapshotEntity {
    if !forceRefresh, let cached = localDataSource.getLatestSnapshot(for: platform), cached.isValid {
        return cached.toDomainEntity()  // TTL 有效 → 直接返回
    }
    do {
        let snapshot = try await remoteDataSource.fetchSnapshot(for: platform)
        try await localDataSource.saveSnapshot(snapshot)  // 更新缓存
        return snapshot
    } catch {
        if let cached = try? localDataSource.getLatestSnapshot(for: platform) {
            return cached.toDomainEntity()  // 网络失败 → 过期缓存降级
        }
        throw AppError.network(underlying: error)
    }
}
```

---

## 11. 术语表

| 术语 | 说明 |
|------|------|
| Feed / 首页 / All | 全平台热榜聚合页 |
| Compare / 对比页 | 交集/差集分析页 |
| Topic | 热点话题实体 |
| Snapshot | 某时刻某平台的完整热榜快照 |
| Platform | 平台枚举（7 平台：weibo/zhihu/baidu/bilibili-hs/bilibili-hv/douyin/toutiao） |
| Morphic Card | 变形卡片（非对称圆角 + 渐变光带） |
| Heat Spectrum | 热度光谱（8 级颜色映射） |
| Prismatic Flow | 棱镜流设计系统 |
| Fetcher | 后端数据采集器（调用热榜 API 获取列表） |
| Scraper | 后端内容抓取器（为话题补充正文 content） |
| topic_key | 话题唯一标识（三级降级：source_id → title hash） |
| Normalizer | 归一化处理器（topic_key 生成 + 热度排名映射） |
| Entity Extractor | jieba 命名实体提取器 |
| Embedder | Jina 向量嵌入生成器（512 维） |
| Matcher | 三信号融合跨平台匹配器 |
| event_cluster | 跨平台事件聚类（≥2 个平台的相关话题集） |
| Heat Normalization | 热度排名映射到 0..10,000,000（position_ratio^1.5） |
| PostgREST | Supabase REST API 接口（后端写入通道） |
