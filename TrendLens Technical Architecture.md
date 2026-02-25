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
| 网络 | URLSession + async/await + ETag |
| 远程数据 | supabase-swift（Supabase Data API） |
| 图表 | Swift Charts（含 3D） |
| 小组件 | WidgetKit |
| 后台刷新 | BGTaskScheduler |
| 日志 | OSLog |

### 后端（Python）

| 类别 | 技术 |
|------|------|
| 语言 | Python 3.12+ |
| HTTP 客户端 | httpx（异步） |
| HTML 解析 | BeautifulSoup4 + lxml |
| 正文提取 | readability-lxml / newspaper3k |
| 数据库 | Supabase（PostgreSQL 15+） |
| ORM/客户端 | supabase-py |
| AI 摘要 | Claude API（anthropic-sdk） |
| 调度 | APScheduler |
| 日志 | Python logging + structlog |
| 配置 | python-dotenv |

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
[后端数据管道]
Fetcher → Scraper → Processor → Snapshot → Supabase (PostgreSQL)
  │          │          │
  │          │          └─ 热度归一化、AI 摘要、标签提取
  │          └─ 正文页面抓取
  └─ 热榜列表 API 采集

[快照对比]
当前快照 + 上一快照 → Differ → rankChange / heatHistory 更新
```

### 缓存策略

1. 检查 validUntil 判断缓存有效性
2. 有效 → 返回 SwiftData 本地缓存
3. 过期 → 请求 Supabase（带 ETag）
4. 200 响应 → 更新本地缓存
5. 304 响应 → 延长本地缓存有效期
6. 网络失败 → 返回过期缓存（带「数据已过期」标记）

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

> **[权威定义]** 本章节为后端架构的唯一定义来源。
> **详细数据源规范：** [backend/docs/hot-news-data-sources-v2.md](backend/docs/hot-news-data-sources-v2.md)
> **数据需求文档：** [backend/docs/data-requirements.md](backend/docs/data-requirements.md)

### 10.1 后端目录结构

```
backend/
├── docs/                      # 文档
│   ├── data-sources-v1.md     # 全量数据源调研
│   ├── hot-news-data-sources-v2.md  # 选定接口规范
│   └── data-requirements.md   # 数据需求与字段映射
├── data/                      # 接口样本数据（开发参考）
├── src/
│   ├── fetchers/              # 阶段 1：热榜列表采集器（每源一个文件）
│   ├── scrapers/              # 阶段 2：正文页面抓取器
│   ├── parsers/               # 响应解析器（JSON / HTML / 内嵌数据）
│   ├── processors/            # 数据处理（归一化、AI 摘要、标签提取）
│   ├── storage/               # Supabase 存储层
│   ├── differ/                # 快照对比（rankChange、heatHistory）
│   ├── scheduler/             # 定时任务调度
│   └── common/                # 通用工具（HTTP 客户端、日志、配置）
├── tests/
├── config/
│   └── sources.yaml           # 数据源配置（URL、频率、启用状态）
├── .env                       # 环境变量（Supabase URL/Key、API Token）
├── requirements.txt
└── main.py                    # 入口
```

### 10.2 数据管道架构

```
┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐
│ Fetcher  │───→│ Parser   │───→│ Scraper  │───→│Processor │───→│ Storage  │
│ 热榜API  │    │ 响应解析 │    │ 正文抓取 │    │ 后处理   │    │ Supabase │
└──────────┘    └──────────┘    └──────────┘    └──────────┘    └──────────┘
                                                     │               │
                                                     │               ▼
                                                     │          ┌──────────┐
                                                     │          │ Differ   │
                                                     │          │ 快照对比 │
                                                     │          └──────────┘
                                                     ▼
                                              ┌─────────────┐
                                              │ AI (Claude) │
                                              │ 摘要 + 标签 │
                                              └─────────────┘
```

**管道各阶段职责**：

| 阶段 | 输入 | 输出 | 频率 |
|------|------|------|------|
| Fetcher | 数据源 API URL | 原始响应（JSON/HTML） | 每 15 分钟 |
| Parser | 原始响应 | 结构化话题列表（title, heat, link...） | 同 Fetcher |
| Scraper | 话题 link URL | 正文内容、图片、标签 | 每条话题 |
| Processor | 原始字段 | 归一化热度、AI 摘要、提取标签 | 批量 |
| Storage | 处理后话题 + 元数据 | Supabase 数据库记录 | 同 Fetcher |
| Differ | 当前快照 + 前一快照 | rankChange、heatHistory 追加 | 同 Storage |

### 10.3 Supabase 集成

**连接方式**：

| 端 | SDK | 用途 |
|----|-----|------|
| Python 后端 | `supabase-py` | 写入采集数据（insert/upsert） |
| iOS 客户端 | `supabase-swift` | 读取数据（select + 实时订阅） |

**Data API 配置**：
- 已启用 Autogenerate RESTful API（public schema）
- iOS 端通过 `SUPABASE_URL` + `SUPABASE_ANON_KEY` 连接
- 后端通过 `SUPABASE_URL` + `SUPABASE_SERVICE_ROLE_KEY` 连接（绕过 RLS）

**安全策略**：
- Row Level Security (RLS) 启用
- anon key：只允许 SELECT（iOS 端只读）
- service_role key：允许 INSERT/UPDATE/DELETE（仅后端使用，不暴露给客户端）

### 10.4 iOS 远程数据层变化

**新增组件**：

| 组件 | 位置 | 职责 |
|------|------|------|
| `SupabaseClient` | Infrastructure/ | Supabase 连接配置 |
| `RemoteTrendingDataSource` | Data/DataSources/ | 通过 Supabase API 获取远程数据 |
| `SupabaseMapper` | Data/Mappers/ | Supabase JSON → TrendTopicEntity 映射 |

**Repository 策略变更**：

```swift
// Phase 2: Remote-first, Local-cache
func fetchTrending(platform: Platform) async throws -> TrendSnapshotEntity {
    // 1. 检查本地缓存
    if let cached = try await localDataSource.getLatestSnapshot(for: platform),
       cached.isValid {
        return cached
    }
    // 2. 请求远程
    do {
        let remote = try await remoteDataSource.fetchSnapshot(for: platform)
        try await localDataSource.saveSnapshot(remote)  // 更新缓存
        return remote
    } catch {
        // 3. 降级：返回过期缓存
        if let expired = try await localDataSource.getLatestSnapshot(for: platform) {
            return expired  // 带 isExpired 标记
        }
        throw error
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
| Platform | 平台枚举（根据实际数据源动态调整） |
| Morphic Card | 变形卡片（非对称圆角 + 渐变光带） |
| Heat Spectrum | 热度光谱（8 级颜色映射） |
| Prismatic Flow | 棱镜流设计系统 |
| Fetcher | 后端数据采集器（调用热榜 API 获取列表） |
| Scraper | 后端正文抓取器（跟踪链接解析页面内容） |
| Differ | 后端快照对比器（计算 rankChange 和 heatHistory） |
| Heat Normalization | 热度值归一化（不同平台量级统一映射） |
