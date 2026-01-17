# TrendLens 模块参考

> 各架构层模块的职责、能力与边界定义。
>
> 架构总览见 `TrendLens Technical Architecture.md`

---

## 1. Presentation Layer

### 1.1 SwiftUI Views
**职责**：纯 UI 渲染与交互响应

| 能力 | 禁止 |
|------|------|
| 页面布局与组件组合 | 业务逻辑 |
| 响应 ViewModel 状态变化 | 直接网络请求 |
| 用户交互事件转发 | 直接数据库操作 |
| 平台适配（iPhone/iPad/Mac） | 持有 Repository 引用 |

### 1.2 ViewModels (@Observable)
**职责**：页面状态管理与业务调度

| 能力 | 禁止 |
|------|------|
| 持有页面状态（topics, isLoading, error） | 直接访问 DataSource |
| 调用 UseCase 执行业务 | 持有 View 引用 |
| Entity → ViewData 转换 | 网络/数据库操作 |
| 错误处理与状态恢复 | 跨页面状态管理 |

**状态字段模式**：`items`, `isLoading`, `error`, `lastUpdatedAt`

### 1.3 Router
**职责**：页面导航与路由

| 能力 |
|------|
| NavigationPath 管理 |
| Deep Link 处理 |
| Sheet/FullScreen 弹窗管理 |

---

## 2. Domain Layer

> 核心原则：**不依赖任何框架**，纯 Swift 代码

### 2.1 Entities
**职责**：业务数据结构定义

| Entity | 核心属性 |
|--------|----------|
| `Topic` | id, title, rank, previousRank, hotScore, platform, url, snapshotTime |
| `Snapshot` | id, platform, topics[], fetchedAt, validUntil, etag |
| `Platform` | enum: weibo, xiaohongshu, bilibili, douyin, x |
| `UserPreference` | favoritedIds, blockedKeywords, enabledPlatforms, sortOrder |

**设计要求**：
- 纯值类型（struct），标记 `Sendable`
- 包含必要的计算属性（如 `rankChange`, `isExpired`）
- 不依赖 SwiftData 或其他框架

### 2.2 UseCases
**职责**：封装单一业务操作

| UseCase | 职责 |
|---------|------|
| `FetchTrendingUseCase` | 获取热榜 + 应用过滤/排序 |
| `ComparePlatformsUseCase` | 计算交集/差集 |
| `SearchTopicsUseCase` | 关键词搜索 + 时间范围过滤 |
| `ManageFavoritesUseCase` | 收藏增删查 |

**设计要求**：
- 只依赖 Repository Protocol
- 标记 `Sendable`
- 包含业务规则（屏蔽词过滤、相似度匹配等）

### 2.3 Repository Protocols
**职责**：定义数据访问接口

```
TrendingRepositoryProtocol:
  - fetchTopics(platforms, forceRefresh) async throws -> [Topic]
  - getSnapshot(platform) async throws -> Snapshot?
  - isCacheValid(platform) -> Bool

UserPreferenceRepositoryProtocol:
  - getPreference() async -> UserPreference
  - addFavorite(topicId) async throws
  - removeFavorite(topicId) async throws
```

---

## 3. Data Layer

### 3.1 Repository Implementation
**职责**：协调 Local/Remote DataSource

| 能力 |
|------|
| 缓存策略：优先本地，后台更新 |
| 网络失败时 fallback 到过期缓存 |
| 304 Not Modified 处理 |
| 并发获取多平台数据 |

**缓存策略**：
1. 检查缓存有效性（validUntil）
2. 有效则返回缓存，无效则请求网络
3. 网络成功则更新缓存
4. 网络失败则返回过期缓存（带标记）

### 3.2 Local DataSource
**职责**：SwiftData 持久化

| 能力 |
|------|
| Snapshot/Topic CRUD |
| 使用 `#Predicate` 查询 |
| 按 platform、时间范围过滤 |
| 清理过期数据 |

### 3.3 Remote DataSource
**职责**：网络请求

| 能力 |
|------|
| 从 CDN/BaaS 获取 JSON |
| ETag/If-None-Match 支持 |
| 根据地区选择端点 |
| 标记 `nonisolated` 在后台执行 |

### 3.4 Mappers
**职责**：数据模型转换

```
DTO (网络) <--> Entity (业务) <--> Model (SwiftData)
```

---

## 4. Infrastructure Layer

### 4.1 NetworkClient
**职责**：HTTP 请求封装

| 能力 |
|------|
| URLSession + async/await |
| ETag 自动存储/发送 |
| 错误映射（URLError → NetworkError） |
| 超时与重试 |

### 4.2 Logger
**职责**：结构化日志

分类：`network`, `data`, `ui`, `background`, `performance`

### 4.3 BackgroundRefreshManager
**职责**：后台任务调度

| 能力 |
|------|
| BGTaskScheduler 注册 |
| 定时后台刷新 |
| 过期数据清理 |

---

## 5. 数据流

```
View → ViewModel → UseCase → Repository → DataSource
  ↑                                            ↓
  └──────────── 状态更新 ←─── Mapper ←─────────┘
```

**典型流程**：
1. View 触发 ViewModel.refresh()
2. ViewModel 调用 UseCase.execute()
3. UseCase 调用 Repository.fetchTopics()
4. Repository 协调 Local/Remote DataSource
5. Mapper 转换数据格式
6. ViewModel 更新状态，View 自动刷新
