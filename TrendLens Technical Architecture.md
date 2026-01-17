# TrendLens 技术架构文档

> 本文档基于 iOS 26 / iPadOS 26 / macOS 26 SDK（Xcode 26, Swift 6.2）编写，作为项目的技术规范与参考。

---

## 1. 整体架构

采用 **Clean Architecture + MVVM** 分层架构，确保关注点分离、可测试性和可维护性。

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  SwiftUI    │  │  ViewModels │  │  Navigation/Router  │ │
│  │  Views      │  │ @Observable │  │                     │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                      Domain Layer                           │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  UseCases   │  │  Entities   │  │  Repository Proto   │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                       Data Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │ Repository  │  │   Local     │  │      Remote         │ │
│  │   Impl      │  │ DataSource  │  │    DataSource       │ │
│  │             │  │ (SwiftData) │  │  (Network/CDN)      │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                   Infrastructure Layer                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐ │
│  │  Networking │  │   Logging   │  │  Background Tasks   │ │
│  │  (URLSession)│ │   (OSLog)   │  │  (BGTaskScheduler)  │ │
│  └─────────────┘  └─────────────┘  └─────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

---

## 2. 目录与文件结构

```
TrendLens/
├── App/
│   ├── TrendLensApp.swift              # App 入口，依赖注入
│   ├── AppDelegate.swift               # 后台任务注册（如需要）
│   └── DependencyContainer.swift       # 依赖注入容器
│
├── Features/                           # 功能模块（按页面划分）
│   ├── Feed/
│   │   ├── FeedView.swift
│   │   ├── FeedViewModel.swift
│   │   └── Components/
│   │       ├── TopicCard.swift
│   │       └── PlatformBadge.swift
│   ├── Compare/
│   │   ├── CompareView.swift
│   │   ├── CompareViewModel.swift
│   │   └── Components/
│   ├── Search/
│   │   ├── SearchView.swift
│   │   └── SearchViewModel.swift
│   ├── Settings/
│   │   ├── SettingsView.swift
│   │   └── SettingsViewModel.swift
│   └── Timeline/
│       ├── TimelineView.swift
│       └── TimelineViewModel.swift
│
├── Core/
│   ├── Domain/
│   │   ├── Entities/
│   │   │   ├── Topic.swift             # 热点话题实体
│   │   │   ├── Snapshot.swift          # 快照实体
│   │   │   ├── Platform.swift          # 平台枚举
│   │   │   └── UserPreference.swift    # 用户偏好实体
│   │   ├── UseCases/
│   │   │   ├── FetchTrendingUseCase.swift
│   │   │   ├── ComparePlatformsUseCase.swift
│   │   │   ├── SearchTopicsUseCase.swift
│   │   │   └── ManageFavoritesUseCase.swift
│   │   └── Repositories/
│   │       ├── TrendingRepositoryProtocol.swift
│   │       └── UserPreferenceRepositoryProtocol.swift
│   │
│   ├── Data/
│   │   ├── Repositories/
│   │   │   ├── TrendingRepository.swift
│   │   │   └── UserPreferenceRepository.swift
│   │   ├── DataSources/
│   │   │   ├── Local/
│   │   │   │   ├── SwiftDataContainer.swift
│   │   │   │   ├── TopicLocalDataSource.swift
│   │   │   │   └── Models/              # SwiftData @Model
│   │   │   │       ├── TopicModel.swift
│   │   │   │       ├── SnapshotModel.swift
│   │   │   │       └── UserPreferenceModel.swift
│   │   │   └── Remote/
│   │   │       ├── TrendingRemoteDataSource.swift
│   │   │       ├── RemoteEndpointPolicy.swift
│   │   │       └── DTOs/                # 网络传输对象
│   │   │           ├── SnapshotDTO.swift
│   │   │           └── TopicDTO.swift
│   │   └── Mappers/
│   │       ├── TopicMapper.swift        # DTO <-> Entity <-> Model
│   │       └── SnapshotMapper.swift
│   │
│   └── Infrastructure/
│       ├── Network/
│       │   ├── NetworkClient.swift      # URLSession 封装
│       │   ├── APIEndpoint.swift
│       │   └── NetworkError.swift
│       ├── Logging/
│       │   └── Logger.swift             # OSLog 封装
│       └── BackgroundTasks/
│           └── BackgroundRefreshManager.swift
│
├── UIComponents/                        # 可复用 UI 组件
│   ├── SkeletonView.swift
│   ├── RefreshableScrollView.swift
│   ├── PlatformChip.swift
│   ├── RankChangeIndicator.swift
│   ├── GlassCard.swift                  # Liquid Glass 风格卡片
│   └── EmptyStateView.swift
│
├── Resources/
│   ├── Assets.xcassets/
│   ├── Localizable.xcstrings            # 国际化
│   └── Fonts/
│
├── Extensions/
│   ├── Date+Extensions.swift
│   ├── View+Extensions.swift
│   └── String+Extensions.swift
│
└── Supporting Files/
    └── Info.plist
```

---

## 3. 技术栈明细

### 3.1 核心框架

| 类别 | 技术 | 版本/说明 |
|------|------|----------|
| UI | SwiftUI | iOS 26 SDK，支持 Liquid Glass、3D Layout、WebView |
| 状态管理 | Observation (`@Observable`) | Swift 5.9+ 原生宏，替代 ObservableObject |
| 持久化 | SwiftData | iOS 26 新增 Model Inheritance、Persistent History |
| 网络 | URLSession + async/await | 原生，支持 ETag/If-None-Match |
| 图表 | Swift Charts | iOS 26 新增 3D 图表支持 |
| 小组件 | WidgetKit | 桌面 Top1/Top5 速览 |
| 后台刷新 | BGTaskScheduler | iOS/iPadOS |
| 日志 | OSLog | 系统原生，支持分类与级别 |

### 3.2 Swift 6.2 并发模型

**关键变化：**

```swift
// Xcode 26 新项目默认: 所有代码运行在 @MainActor
// 需要后台执行时，显式标记 nonisolated

// ViewModel 示例（自动在 MainActor）
@Observable
final class FeedViewModel {
    var topics: [Topic] = []
    var isLoading = false
    
    // 默认已在 MainActor，无需额外标记
    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        
        // 调用 nonisolated 的数据层方法
        topics = await fetchTrendingUseCase.execute()
    }
}

// 数据层需要显式标记 nonisolated
nonisolated func fetchFromNetwork() async throws -> [TopicDTO] {
    // 网络请求在后台线程执行
}
```

**项目设置建议：**
- Default Actor Isolation: `MainActor`（新项目默认）
- Strict Concurrency Checking: `Complete`
- Swift Language Mode: `6`

### 3.3 SwiftData 模型设计（利用 Model Inheritance）

```swift
// 基类：共享属性
@Model
class BaseContent {
    var id: UUID
    var title: String
    var createdAt: Date
    var platform: Platform
    
    init(id: UUID, title: String, createdAt: Date, platform: Platform) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.platform = platform
    }
}

// 子类：热点话题
@Model
final class TopicModel: BaseContent {
    var rank: Int
    var hotScore: Double
    var url: String?
    var snapshotId: UUID
    
    init(id: UUID, title: String, createdAt: Date, platform: Platform,
         rank: Int, hotScore: Double, url: String?, snapshotId: UUID) {
        self.rank = rank
        self.hotScore = hotScore
        self.url = url
        self.snapshotId = snapshotId
        super.init(id: id, title: title, createdAt: createdAt, platform: platform)
    }
}
```

### 3.4 Liquid Glass UI 实现

```swift
// 按钮样式
Button("刷新") { }
    .buttonStyle(.glass)               // iOS 26 新增
    .buttonStyle(.borderedProminent)   // 自动获得 Liquid Glass

// 自定义 Glass Card
struct GlassCard<Content: View>: View {
    let content: Content
    
    var body: some View {
        content
            .padding()
            .background(.ultraThinMaterial)
            .glassEffect()              // iOS 26 新增
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// TabView 自动适配 Liquid Glass
TabView {
    FeedView()
        .tabItem { Label("热榜", systemImage: "flame") }
    CompareView()
        .tabItem { Label("对比", systemImage: "square.split.2x1") }
}
```

---

## 4. 模块职责边界

### 4.1 Presentation Layer

| 组件 | 职责 | 禁止事项 |
|------|------|----------|
| View | 纯 UI 渲染、用户交互响应 | 不得包含业务逻辑、网络请求、数据持久化 |
| ViewModel | 页面状态管理、调用 UseCase | 不得直接访问 DataSource、不得持有 View 引用 |
| Router | 页面导航、Deep Link 处理 | 不得包含业务逻辑 |

### 4.2 Domain Layer

| 组件 | 职责 | 禁止事项 |
|------|------|----------|
| Entity | 纯业务数据结构 | 不得依赖任何框架（SwiftData、UIKit 等） |
| UseCase | 单一业务操作封装 | 不得直接访问网络或数据库 |
| Repository Protocol | 定义数据访问接口 | 只定义协议，不实现 |

### 4.3 Data Layer

| 组件 | 职责 | 禁止事项 |
|------|------|----------|
| Repository Impl | 协调 Local/Remote DataSource | 不得包含 UI 代码 |
| Local DataSource | SwiftData CRUD 操作 | 不得发起网络请求 |
| Remote DataSource | 网络请求、DTO 解析 | 不得直接操作本地数据库 |
| Mapper | 数据模型转换 | 不得包含业务逻辑 |

### 4.4 Infrastructure Layer

| 组件 | 职责 |
|------|------|
| NetworkClient | HTTP 请求封装、重试、超时、ETag 缓存 |
| Logger | 日志分类与输出 |
| BackgroundRefreshManager | 后台任务注册与调度 |

---

## 5. 编码规范

### 5.1 命名规范

```swift
// 类型：PascalCase
struct TopicCard: View { }
class FeedViewModel { }
enum Platform { }
protocol TrendingRepositoryProtocol { }

// 变量/函数：camelCase
let topicList: [Topic]
func fetchTrending() async { }

// 常量：camelCase 或 UPPER_SNAKE_CASE（全局常量）
let defaultRefreshInterval: TimeInterval = 600
static let API_BASE_URL = "https://api.example.com"

// 文件命名：与主类型一致
// TopicCard.swift, FeedViewModel.swift, TrendingRepository.swift
```

### 5.2 SwiftUI View 规范

```swift
struct FeedView: View {
    // 1. 状态属性（按类型分组）
    @State private var viewModel: FeedViewModel
    @Environment(\.modelContext) private var modelContext
    
    // 2. 常规属性
    let platform: Platform
    
    // 3. body
    var body: some View {
        content
            .navigationTitle("热榜")
            .task { await viewModel.refresh() }
    }
    
    // 4. 子视图（@ViewBuilder 计算属性）
    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading {
            SkeletonView()
        } else {
            topicList
        }
    }
    
    private var topicList: some View {
        List(viewModel.topics) { topic in
            TopicCard(topic: topic)
        }
    }
}
```

### 5.3 ViewModel 规范

```swift
@Observable
@MainActor
final class FeedViewModel {
    // MARK: - Published State
    private(set) var topics: [Topic] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var lastUpdatedAt: Date?
    
    // MARK: - Dependencies
    private let fetchTrendingUseCase: FetchTrendingUseCase
    
    // MARK: - Init
    init(fetchTrendingUseCase: FetchTrendingUseCase) {
        self.fetchTrendingUseCase = fetchTrendingUseCase
    }
    
    // MARK: - Public Methods
    func refresh() async {
        guard !isLoading else { return }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            topics = try await fetchTrendingUseCase.execute()
            lastUpdatedAt = .now
        } catch {
            self.error = error
        }
    }
}
```

### 5.4 错误处理规范

```swift
// 定义领域错误
enum TrendingError: LocalizedError {
    case networkUnavailable
    case invalidData
    case cacheExpired
    case rateLimited
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "网络不可用"
        case .invalidData: return "数据格式错误"
        case .cacheExpired: return "缓存已过期"
        case .rateLimited: return "请求过于频繁"
        }
    }
}

// Repository 中统一转换错误
func fetchTrending() async throws -> [Topic] {
    do {
        return try await remoteDataSource.fetch()
    } catch let error as URLError where error.code == .notConnectedToInternet {
        throw TrendingError.networkUnavailable
    } catch {
        throw error
    }
}
```

### 5.5 日志规范

```swift
import OSLog

extension Logger {
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Network")
    static let data = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Data")
    static let ui = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "UI")
}

// 使用
Logger.network.debug("Fetching trending from \(url)")
Logger.network.error("Request failed: \(error.localizedDescription)")
Logger.data.info("Cache hit for platform: \(platform.rawValue)")
```

---

## 6. 可能用到的技术点

### 6.1 iOS 26 新特性（按需采用）

| 特性 | 用途 | 优先级 |
|------|------|--------|
| WebView (SwiftUI) | 热点详情页内嵌网页 | 高 |
| Swift Charts 3D | 跨平台热度对比可视化 | 中 |
| `@Animatable` 宏 | 排名变化动画 | 中 |
| In-App Browser | 点击热点在 App 内打开链接 | 高 |
| Persistent History (SwiftData) | 跟踪数据变更、支持撤销 | 低 |

### 6.2 性能优化

| 场景 | 方案 |
|------|------|
| 列表滚动 | `List` + `LazyVStack`，避免一次性加载所有数据 |
| 图片加载 | AsyncImage + 内存/磁盘缓存 |
| 网络请求 | ETag/If-None-Match 减少重复传输 |
| SwiftData 查询 | 使用 `#Predicate`，避免全表扫描 |
| 首屏加载 | 先显示缓存，后台静默更新 |

### 6.3 测试策略

| 层级 | 测试类型 | 工具 |
|------|----------|------|
| Domain | 单元测试（UseCase、Entity 逻辑） | XCTest |
| Data | 单元测试（Mapper、Repository Mock） | XCTest |
| Presentation | UI 测试（关键流程） | XCUITest |
| Integration | 端到端测试 | XCTest + Mock Server |

---

## 7. 依赖注入

```swift
// DependencyContainer.swift
@MainActor
final class DependencyContainer {
    static let shared = DependencyContainer()
    
    // MARK: - Infrastructure
    lazy var networkClient = NetworkClient()
    lazy var logger = Logger.self
    
    // MARK: - Data Sources
    lazy var trendingRemoteDataSource = TrendingRemoteDataSource(networkClient: networkClient)
    lazy var trendingLocalDataSource = TopicLocalDataSource()
    
    // MARK: - Repositories
    lazy var trendingRepository: TrendingRepositoryProtocol = TrendingRepository(
        remoteDataSource: trendingRemoteDataSource,
        localDataSource: trendingLocalDataSource
    )
    
    // MARK: - Use Cases
    lazy var fetchTrendingUseCase = FetchTrendingUseCase(repository: trendingRepository)
    lazy var comparePlatformsUseCase = ComparePlatformsUseCase(repository: trendingRepository)
    
    // MARK: - ViewModels
    func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(fetchTrendingUseCase: fetchTrendingUseCase)
    }
    
    func makeCompareViewModel() -> CompareViewModel {
        CompareViewModel(comparePlatformsUseCase: comparePlatformsUseCase)
    }
}

// App 入口使用
@main
struct TrendLensApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [TopicModel.self, SnapshotModel.self])
    }
}
```

---

## 8. 版本与兼容性

| 项目 | 最低版本 | 说明 |
|------|----------|------|
| iOS | 26.0 | 利用 Liquid Glass、SwiftData Inheritance |
| iPadOS | 26.0 | NavigationSplitView 主从布局 |
| macOS | 26.0 (Tahoe) | Catalyst 或原生 SwiftUI |
| Xcode | 26.0 | Swift 6.2 |
| Swift | 6.2 | 默认 MainActor 隔离 |

---

*文档版本: 1.0*  
*最后更新: 2026-01-17*
