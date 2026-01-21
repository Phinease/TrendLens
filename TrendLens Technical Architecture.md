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
│   ├── Compare/            # 对比页（交集/差集）
│   ├── Search/             # 搜索/收藏
│   ├── Settings/           # 设置
│   └── [Feature]/
│       ├── [Feature]View.swift
│       ├── [Feature]ViewModel.swift
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
├── Extensions/
└── Resources/
```

---

## 3. 技术栈

> **[权威定义]** 本章节为技术栈选型的唯一定义来源。

| 类别 | 技术 |
|------|------|
| UI | SwiftUI（Liquid Glass、3D Layout、WebView） |
| 状态管理 | `@Observable`（MVVM） |
| 持久化 | SwiftData（Model Inheritance、Persistent History） |
| 网络 | URLSession + async/await + ETag |
| 图表 | Swift Charts（含 3D） |
| 小组件 | WidgetKit |
| 后台刷新 | BGTaskScheduler |
| 日志 | OSLog |

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

```
View → ViewModel → UseCase → Repository → DataSource
                                  ↓
                            Local / Remote
```

**缓存策略**：

1. 检查 validUntil 判断缓存有效性
2. 有效 → 返回缓存
3. 无效 → 请求网络 → 成功则更新缓存
4. 网络失败 → 返回过期缓存（带标记）

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

---

## 9. 版本要求

| 平台 | 最低版本 |
|------|----------|
| iOS / iPadOS | 26.0 |
| macOS | 26.0 (Tahoe) |
| Xcode | 26.0 |
| Swift | 6.2 |
