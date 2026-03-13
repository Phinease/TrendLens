# TrendLensUITests UI 测试架构

> 使用 XCUITest 框架的 UI 测试规范。
>
> 测试策略总览见 `TrendLens Testing Guide.md`

---

## 1. 目录结构

```
TrendLensUITests/
├── Tests/                 # 按功能模块组织
│   ├── Feed/              # FeedUITests
│   ├── Compare/           # CompareUITests
│   ├── Search/            # SearchUITests
│   └── Settings/          # SettingsUITests
├── Flows/                 # 端到端流程测试
│   └── CoreUserFlowTests
├── Pages/                 # Page Objects
│   ├── BasePage
│   ├── FeedPage, ComparePage, SearchPage, SettingsPage
│   └── Components/        # TabBar, TopicCard, PlatformChip
├── Helpers/               # 扩展与工具
│   ├── XCUIApplication+Extensions
│   ├── AccessibilityIdentifiers
│   └── LaunchArguments
└── Performance/           # 性能测试
    └── LaunchPerformanceTests
```

---

## 2. Page Object 模式

### 2.1 设计原则

- 每个页面封装为一个类
- 元素查找逻辑集中管理
- 提供语义化的操作方法
- 支持链式调用

### 2.2 Page 结构

```
BasePage:
  - app: XCUIApplication
  - waitForExistence()
  - goBack()

FeedPage(BasePage):
  Elements: topicList, topicCells, refreshIndicator, emptyStateView
  Actions: refresh(), selectPlatform(), tapTopic()
  Assertions: assertNotEmpty(), assertTopicExists()
```

### 2.3 组件封装

```
TabBar: goToFeed(), goToCompare(), goToSearch(), goToSettings()
TopicCard: title, rank, favoriteButton, tap(), toggleFavorite()
```

---

## 3. Accessibility Identifiers

在 App 代码中定义并使用：

```
Feed: FeedView, TopicList, EmptyStateView, PlatformTab_{name}
Topic: TopicTitle, TopicRank, FavoriteButton
Compare: CompareView, PlatformChip_{name}, IntersectionSection
Search: SearchView, SearchField, SearchResults
```

---

## 4. 启动配置

### 4.1 Launch Arguments

```
-UITesting        # 测试模式
-UseMockData      # 使用 Mock 数据
-ForceError       # 强制错误状态
-ForceEmpty       # 强制空状态
-SkipOnboarding   # 跳过引导
```

### 4.2 App 端支持

```swift
if ProcessInfo.processInfo.arguments.contains("-UITesting") {
    // 禁用动画
    // 配置 Mock 数据源
}
```

---

## 5. 测试场景

### 5.1 优先级

| P0（必须） | P1（重要） | P2（可选） |
|------------|------------|------------|
| 首页加载显示 | 空状态展示 | 设置生效验证 |
| 下拉刷新 | 错误状态与重试 | 多语言测试 |
| 切换平台 | 收藏功能 | 辅助功能测试 |
| 热点详情导航 | 搜索功能 | |
| 对比页交集显示 | | |

### 5.2 核心流程测试

```
启动 → 查看热榜 → 下拉刷新 → 点击热点 → 查看详情
    → 切换到对比 → 选择平台 → 查看交集
    → 收藏热点 → 搜索热点
```

---

## 6. 测试规范

### 6.1 命名

```
test_[页面]_[操作]_[预期结果]
// 例: test_feedPage_pullToRefresh_updatesTopicList
```

### 6.2 结构

```swift
func test_feedPage_scenario() {
    // Given - 前置条件
    waitForAppToLoad()
    
    // When - 用户操作
    feedPage.refresh()
    
    // Then - 验证结果
    feedPage.assertNotEmpty()
}
```

### 6.3 等待策略

- `element.waitForExistence(timeout:)`
- `element.waitForDisappearance(timeout:)`
- 避免 `Thread.sleep`，使用 Predicate 等待

### 6.4 截图

关键步骤调用 `takeScreenshot(name:)` 用于调试和视觉回归

---

## 7. 性能测试

| 指标 | 目标 | 测试方法 |
|------|------|----------|
| App 启动 | < 1.5s | `XCTApplicationLaunchMetric` |
| 列表滚动 | ≥ 60fps | `XCTOSSignpostMetric.scrollDecelerationMetric` |
| Tab 切换 | < 200ms | `measure { }` |

---

## 8. 最佳实践

1. **聚焦关键流程**：只测试用户核心路径
2. **独立稳定**：使用 Mock 数据，不依赖网络
3. **快速反馈**：控制测试数量，保持执行速度
4. **易维护**：Page Object 集中管理元素定位
5. **处理异步**：使用等待而非固定延时
