# TrendLens 开发指南

> **文档定位：** 日常开发操作手册（构建、测试、环境配置、代码示例）
> **技术规范参考：** [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md)
> **Claude Code 指引：** [CLAUDE.md](CLAUDE.md)
>
> **最后更新：** 2026-01-22

---

## 1. 开发环境

### 1.1 版本要求

| 工具/平台 | 最低版本 |
|-----------|----------|
| Xcode | 26.0+ |
| Swift | 6.2 |
| iOS / iPadOS | 26.0+ |
| macOS | 26.0+ (Tahoe) |

### 1.2 推荐模拟器

| 平台 | 设备 |
|------|------|
| iPhone | iPhone 17 Pro |
| iPad | iPad Pro 13-inch (M5) |
| Mac | macOS 26 Tahoe |

---

## 2. 构建与运行

### 2.1 Xcode 打开项目

```bash
open TrendLens.xcodeproj
```

### 2.2 命令行构建

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

### 2.3 Xcode 快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd + B` | 构建 |
| `Cmd + R` | 运行 |
| `Cmd + .` | 停止运行 |
| `Cmd + Shift + K` | 清理构建 |

---

## 3. 测试

### 3.1 运行测试

```bash
# 运行所有测试
xcodebuild test -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 仅运行单元测试
xcodebuild test -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TrendLensTests

# 仅运行 UI 测试
xcodebuild test -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TrendLensUITests

# 生成代码覆盖率报告
xcodebuild test -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -enableCodeCoverage YES
```

### 3.2 Xcode 测试快捷键

| 快捷键 | 功能 |
|--------|------|
| `Cmd + U` | 运行所有测试 |
| `Ctrl + Opt + Cmd + U` | 重新运行上次失败的测试 |
| `Ctrl + Opt + Cmd + G` | 运行当前测试方法 |

### 3.3 测试策略

详见 [TrendLens Testing Guide.md](TrendLens%20Testing%20Guide.md)。

---

## 4. 依赖注入使用

### 4.1 创建 ViewModel

```swift
// 通过 DependencyContainer 创建（推荐）
let feedVM = DependencyContainer.shared.makeFeedViewModel()

// 在 View 中使用
struct FeedView: View {
    @State private var viewModel = DependencyContainer.shared.makeFeedViewModel()

    var body: some View {
        // ...
    }
}
```

### 4.2 测试时使用 Mock

```swift
// 创建 Mock Repository
let mockRepo = MockTrendingRepository()
mockRepo.fetchTopicsResult = .success([TestData.makeTopic()])

// 注入到 UseCase
let useCase = FetchTrendingUseCase(repository: mockRepo)

// 验证调用
#expect(mockRepo.fetchTopicsCalled == true)
```

---

## 5. 状态管理

### 5.1 使用 @Observable 宏

```swift
@Observable
final class FeedViewModel {
    // 1. 状态属性（外部只读）
    private(set) var items: [TrendTopic] = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // 2. 依赖
    private let fetchTrendingUseCase: FetchTrendingUseCase

    // 3. 初始化
    init(fetchTrendingUseCase: FetchTrendingUseCase) {
        self.fetchTrendingUseCase = fetchTrendingUseCase
    }

    // 4. 公共方法
    func loadTrending() async {
        isLoading = true
        defer { isLoading = false }

        do {
            items = try await fetchTrendingUseCase.execute()
        } catch {
            self.error = error
        }
    }
}
```

### 5.2 在 View 中使用

```swift
struct FeedView: View {
    @State private var viewModel = DependencyContainer.shared.makeFeedViewModel()

    var body: some View {
        List(viewModel.items) { item in
            TopicRow(topic: item)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .task {
            await viewModel.loadTrending()
        }
    }
}
```

---

## 6. 多平台 UI 适配

### 6.1 平台检测

```swift
#if os(iOS)
// iPhone / iPad 专用代码
#elseif os(macOS)
// Mac 专用代码
#endif
```

### 6.2 设备类型检测

```swift
@Environment(\.horizontalSizeClass) var horizontalSizeClass

var body: some View {
    if horizontalSizeClass == .compact {
        // iPhone 竖屏布局
        TabView { ... }
    } else {
        // iPad / Mac 布局
        NavigationSplitView { ... }
    }
}
```

---

## 7. 常用代码模式

### 7.1 错误处理

```swift
// Domain 层定义错误
enum TrendingError: Error, LocalizedError {
    case networkUnavailable
    case invalidData
    case platformNotSupported(Platform)

    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "网络不可用"
        case .invalidData:
            return "数据格式错误"
        case .platformNotSupported(let platform):
            return "\(platform.displayName) 暂不支持"
        }
    }
}

// Repository 层转换错误
func fetchTopics() async throws -> [TrendTopic] {
    do {
        return try await remoteDataSource.fetch()
    } catch let urlError as URLError {
        throw TrendingError.networkUnavailable
    } catch {
        throw TrendingError.invalidData
    }
}
```

### 7.2 缓存检查

```swift
func fetchTopics(forceRefresh: Bool = false) async throws -> [TrendTopic] {
    // 检查缓存
    if !forceRefresh, let cached = try await localDataSource.getLatestSnapshot() {
        if cached.validUntil > Date() {
            return cached.topics
        }
    }

    // 请求网络
    let snapshot = try await remoteDataSource.fetch()

    // 更新缓存
    try await localDataSource.save(snapshot)

    return snapshot.topics
}
```

### 7.3 ETag 支持

```swift
// NetworkClient 自动处理 ETag
let response = try await networkClient.fetch(
    url: endpoint,
    etag: cachedSnapshot?.etag
)

switch response {
case .notModified:
    // 304 - 使用缓存
    return cachedSnapshot!.topics
case .success(let data, let newEtag):
    // 200 - 解析新数据
    let snapshot = try decoder.decode(TrendSnapshot.self, from: data)
    snapshot.etag = newEtag
    return snapshot.topics
}
```

---

## 8. 调试技巧

### 8.1 SwiftData 调试

```swift
// 查看 SwiftData 存储位置
if let url = modelContainer.configurations.first?.url {
    print("SwiftData 存储路径: \(url.path)")
}
```

### 8.2 网络请求日志

```swift
// 在 NetworkClient 中启用日志
#if DEBUG
Logger.network.debug("Request: \(request.url?.absoluteString ?? "")")
Logger.network.debug("Response: \(response.statusCode)")
#endif
```

### 8.3 View 重绘调试

```swift
var body: some View {
    let _ = Self._printChanges() // 打印导致重绘的属性
    // ...
}
```

---

## 9. Git 工作流

### 9.1 分支命名

| 类型 | 格式 | 示例 |
|------|------|------|
| 功能 | `feature/描述` | `feature/compare-view` |
| 修复 | `fix/描述` | `fix/cache-expiry` |
| 重构 | `refactor/描述` | `refactor/network-layer` |

### 9.2 提交信息格式

```
类型: 简短描述

详细说明（可选）

Co-Authored-By: Claude Opus 4.5 <noreply@anthropic.com>
```

类型：`feat`, `fix`, `refactor`, `docs`, `test`, `chore`

---

## 10. 相关文档

| 文档 | 内容 |
|------|------|
| [CLAUDE.md](CLAUDE.md) | Claude Code 工作指引 |
| [Technical Architecture.md](TrendLens%20Technical%20Architecture.md) | 技术规范（架构、并发、编码规范） |
| [Testing Guide.md](TrendLens%20Testing%20Guide.md) | 测试策略与覆盖率要求 |
| [UI Design System.md](TrendLens%20UI%20Design%20System.md) | UI 设计规范 |
| [Progress.md](TrendLens%20Progress.md) | 开发进度追踪 |
