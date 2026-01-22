# TrendLensTests 单元测试架构

> **文档定位：** 测试目录结构、测试规范、Mock 设计
> **测试策略总览：** [TrendLens Testing Guide.md](TrendLens%20Testing%20Guide.md)
> **当前进度：** [TrendLens Progress.md](TrendLens%20Progress.md)
>
> 使用 Swift Testing 框架（iOS 26+, Swift 6.2）

---

## 1. 目录结构

```
TrendLensTests/
├── Domain/
│   ├── Entities/          # TopicTests, SnapshotTests, PlatformTests
│   └── UseCases/          # FetchTrendingUseCaseTests, ComparePlatformsUseCaseTests
├── Data/
│   ├── Repositories/      # TrendingRepositoryTests
│   ├── DataSources/       # TopicLocalDataSourceTests, TrendingRemoteDataSourceTests
│   └── Mappers/           # TopicMapperTests
├── Presentation/
│   └── [Feature]/         # FeedViewModelTests, CompareViewModelTests
├── Infrastructure/
│   └── Network/           # NetworkClientTests
├── Mocks/                 # Mock 对象
└── Helpers/               # TestData, TestModelContainer
```

---

## 2. 测试范围

| 层级 | 测试对象 | Mock 对象 |
|------|----------|-----------|
| Domain/Entities | 计算属性、Equatable、Codable | 无 |
| Domain/UseCases | 业务逻辑、过滤、排序 | MockRepository |
| Data/Repositories | 缓存策略、错误处理、数据协调 | MockDataSource |
| Data/Mappers | DTO↔Entity↔Model 转换 | 无 |
| Presentation/ViewModels | 状态变化、错误处理 | MockUseCase |
| Infrastructure/Network | 请求构建、响应解析、错误映射 | MockURLProtocol |

---

## 3. 测试规范

### 3.1 命名

```
test_[被测方法]_[条件]_[预期结果]
// 例: test_rankChange_whenRankImproved_returnsUp
```

### 3.2 结构（AAA 模式）

```swift
@Test func methodName_condition_expectedResult() async throws {
    // Arrange - 准备数据和 Mock
    // Act - 执行被测方法
    // Assert - 验证结果
}
```

### 3.3 断言

- `#expect(value == expected)`
- `#expect(throws: ErrorType.self) { ... }`
- `#expect(array.isEmpty)`

### 3.4 参数化测试

```swift
@Test("描述", arguments: [case1, case2, case3])
func testMethod(input: Type) { }
```

---

## 4. Mock 设计原则

### 4.1 Mock Repository 结构

```
MockTrendingRepository:
  - 调用记录: fetchTopicsCalled, fetchTopicsArguments
  - 返回值配置: fetchTopicsResult: Result<[Topic], Error>
  - 重置方法: reset()
```

### 4.2 Mock 策略

- UseCase 测试 → Mock Repository
- ViewModel 测试 → Mock UseCase  
- Repository 测试 → Mock DataSource
- Network 测试 → MockURLProtocol

---

## 5. 辅助工具

### 5.1 TestData 工厂

提供静态方法创建测试数据：

- `makeTopic(id:, title:, rank:, platform:)`
- `makeSnapshot(platform:, topicCount:)`
- `makeUserPreference(blockedKeywords:)`

### 5.2 内存 SwiftData 容器

`TestModelContainer.create()` 返回 `isStoredInMemoryOnly: true` 的容器

### 5.3 MockURLProtocol

拦截网络请求，返回预设响应/错误

---

## 6. 关键测试场景

### Entities

- 计算属性（rankChange: up/down/same/new）
- 缓存过期判断（isExpired）

### UseCases

- 正常获取数据
- 屏蔽词过滤
- 排序规则应用
- 错误传播

### Repositories

- 缓存有效时不请求网络
- 缓存过期时请求网络
- 强制刷新时总是请求网络
- 网络失败时返回过期缓存
- 304 时返回缓存

### ViewModels

- 初始状态正确
- 加载时设置 isLoading
- 成功后更新数据
- 失败后设置 error
- 重复加载保护

---

## 7. 已实现文件清单

> **注意：** 本章节记录已实现的源代码文件结构，便于测试文件对应。
> **最后更新：** 2026-01-22（阶段 0.5 完成）

### 7.1 App 层（3 个文件）

| 文件 | 说明 | 状态 |
|------|------|------|
| `TrendLensApp.swift` | 应用入口，SwiftData 容器配置，启动页逻辑 | ✅ 完整 |
| `MainNavigationView.swift` | 跨平台导航（iPhone TabView / iPad+Mac SplitView） | ✅ 完整 |
| `DependencyContainer.swift` | 依赖注入容器，工厂方法 | ✅ 完整 |

### 7.2 Domain 层（12 个文件）

#### Entities（6 个）

| 文件 | 说明 | 状态 |
|------|------|------|
| `Platform.swift` | 平台枚举（6 个平台），显示名、图标、主题色 | ✅ 完整 |
| `TrendTopic.swift` | 话题 Entity + SwiftData Model，RankChange 枚举 | ✅ 完整 |
| `TrendSnapshot.swift` | 快照 Entity，TTL/ETag 支持 | ✅ 完整 |
| `UserPreference.swift` | 用户偏好 SwiftData Model，收藏/屏蔽词管理 | ✅ 完整 |
| `HeatDataPoint.swift` | 热度数据点，用于热度曲线 | ✅ 完整 |
| `Item.swift` | 遗留占位模型 | ⚠️ 待删除 |

#### Repository 协议（2 个）

| 文件 | 说明 | 状态 |
|------|------|------|
| `TrendingRepository.swift` | 热榜数据 Repository 协议 | ✅ 完整 |
| `UserPreferenceRepository.swift` | 用户偏好 Repository 协议 | ✅ 完整 |

#### UseCases（4 个）

| 文件 | 说明 | 状态 |
|------|------|------|
| `FetchTrendingUseCase.swift` | 获取热榜数据 | ✅ 完整 |
| `SearchTrendingUseCase.swift` | 搜索话题 | ✅ 完整 |
| `ComparePlatformsUseCase.swift` | 平台对比（交集/差集，Levenshtein 距离） | ✅ 完整 |
| `ManageFavoritesUseCase.swift` | 收藏管理 | ✅ 完整 |

### 7.3 Data 层（6 个文件）

#### Local DataSources（2 个）

| 文件 | 说明 | 状态 |
|------|------|------|
| `LocalTrendingDataSource.swift` | SwiftData 热榜缓存，getSnapshot/search/clear 已实现 | ⚠️ saveSnapshot() 未实现 |
| `LocalUserPreferenceDataSource.swift` | SwiftData 用户偏好存储 | ✅ 完整 |

#### Remote DataSources（1 个）

| 文件 | 说明 | 状态 |
|------|------|------|
| `RemoteTrendingDataSource.swift` | 网络数据获取，DTO 定义，ETag 支持 | ⚠️ baseURL 硬编码示例地址 |

#### Repository 实现（2 个）

| 文件 | 说明 | 状态 |
|------|------|------|
| `TrendingRepositoryImpl.swift` | 热榜 Repository 实现，缓存策略、并行请求 | ✅ 完整 |
| `UserPreferenceRepositoryImpl.swift` | 用户偏好 Repository 实现 | ✅ 完整 |

#### Mock Data（1 个）

| 文件 | 说明 | 状态 |
|------|------|------|
| `MockData.swift` | 固定 Mock 数据（6 平台各 5-6 条话题） | ⚠️ 阶段 1 将重构为动态生成器 |

### 7.4 Infrastructure 层（1 个文件）

| 文件 | 说明 | 状态 |
|------|------|------|
| `NetworkClient.swift` | Actor 网络客户端，ETag/超时/错误处理 | ✅ 完整 |

### 7.5 Presentation 层（11 个文件）

#### ViewModels（4 个）

| 文件 | 说明 | 状态 |
|------|------|------|
| `FeedViewModel.swift` | Feed 页面 ViewModel，@Observable | ✅ 完整 |
| `CompareViewModel.swift` | 对比页面 ViewModel | ✅ 完整 |
| `SearchViewModel.swift` | 搜索页面 ViewModel | ✅ 完整 |
| `SettingsViewModel.swift` | 设置页面 ViewModel | ✅ 完整 |

#### Views（7 个）

| 文件 | 说明 | 状态 |
|------|------|------|
| `FeedView.swift` | Feed 页面完整 UI | ⚠️ 使用固定 MockData，未连接 ViewModel |
| `CompareView.swift` | 对比页面 | 📋 占位符 |
| `SearchView.swift` | 搜索页面 | 📋 占位符 |
| `SettingsView.swift` | 设置页面 | ⚠️ 部分实现 |
| `SplashView.swift` | 启动页 | ✅ 完整 |
| `ContentView.swift` | 遗留占位 View | ⚠️ 待删除 |
| `TopicDetailSheet.swift` | 话题详情 Sheet（FeedView 内嵌） | ✅ 完整 |

### 7.6 UIComponents 层（9 个文件）

| 文件 | 说明 | 状态 |
|------|------|------|
| `DesignSystem.swift` | Prismatic Flow 设计系统（Typography, Spacing, Colors, Gradients, Animations） | ✅ 完整 |
| `TrendCard.swift` | Morphic 变形卡片组件 | ✅ 完整 |
| `HeatCurveView.swift` | 热度曲线（Mini + Full），Swift Charts | ✅ 完整 |
| `HeatIndicator.swift` | 热度指示器 + 能量条 | ✅ 完整 |
| `PlatformBadge.swift` | 平台徽章 + 渐变光带 | ✅ 完整 |
| `RankChangeIndicator.swift` | 排名变化指示器 + 排名徽章 | ✅ 完整 |
| `EmptyStateView.swift` | 空状态视图（多种状态） | ✅ 完整 |
| `ErrorView.swift` | 错误状态视图 + 内联横幅 | ✅ 完整 |
| `LoadingView.swift` | 加载状态 + 骨架屏 | ✅ 完整 |

### 7.7 总计

- **总文件数：** 42 个 Swift 文件（不含测试）
- **完整实现：** 34 个 ✅
- **部分实现/待完善：** 6 个 ⚠️
- **占位符/待删除：** 2 个 📋

### 7.8 阶段 1 重点关注文件

| 文件 | 改动类型 | 优先级 |
|------|----------|--------|
| `LocalTrendingDataSource.swift` | 实现 saveSnapshot() | 🔴 高 |
| `MockData.swift` | 重构为 MockDataGenerator | 🔴 高 |
| `FeedView.swift` | 连接 ViewModel，移除固定数据 | 🔴 高 |
| `CompareView.swift` | 完整实现 UI | 🟡 中 |
| `SearchView.swift` | 完整实现 UI | 🟡 中 |
| `SettingsView.swift` | 完成子页面 | 🟡 中 |
| `Item.swift` | 删除 | 🟢 低 |
| `ContentView.swift` | 删除 | 🟢 低 |

---

## 8. 测试文件计划

> 阶段 5 将创建以下测试文件结构

### 8.1 Domain 层测试

```
TrendLensTests/Domain/
├── Entities/
│   ├── PlatformTests.swift
│   ├── TrendTopicTests.swift
│   ├── TrendSnapshotTests.swift
│   ├── UserPreferenceTests.swift
│   └── HeatDataPointTests.swift
└── UseCases/
    ├── FetchTrendingUseCaseTests.swift
    ├── SearchTrendingUseCaseTests.swift
    ├── ComparePlatformsUseCaseTests.swift
    └── ManageFavoritesUseCaseTests.swift
```

### 8.2 Data 层测试

```
TrendLensTests/Data/
├── Repositories/
│   ├── TrendingRepositoryImplTests.swift
│   └── UserPreferenceRepositoryImplTests.swift
├── DataSources/
│   ├── LocalTrendingDataSourceTests.swift
│   ├── LocalUserPreferenceDataSourceTests.swift
│   └── RemoteTrendingDataSourceTests.swift
└── Mappers/
    └── TrendTopicMapperTests.swift
```

### 8.3 Presentation 层测试

```
TrendLensTests/Presentation/
├── Feed/
│   └── FeedViewModelTests.swift
├── Compare/
│   └── CompareViewModelTests.swift
├── Search/
│   └── SearchViewModelTests.swift
└── Settings/
    └── SettingsViewModelTests.swift
```

### 8.4 Infrastructure 层测试

```
TrendLensTests/Infrastructure/
└── Network/
    └── NetworkClientTests.swift
```

### 8.5 辅助文件

```
TrendLensTests/
├── Mocks/
│   ├── MockTrendingRepository.swift
│   ├── MockUserPreferenceRepository.swift
│   ├── MockLocalDataSource.swift
│   ├── MockRemoteDataSource.swift
│   └── MockNetworkClient.swift
└── Helpers/
    ├── TestData.swift
    ├── TestModelContainer.swift
    └── MockURLProtocol.swift
```
