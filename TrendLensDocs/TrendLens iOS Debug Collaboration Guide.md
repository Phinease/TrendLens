# TrendLens iOS 开发协作指南

> **文档定位：** 人机协作调试流程与最佳实践
> **创建日期：** 2026-03-30
> **核心问题：** Claude 看不到运行中的 App，用户看不到代码细节——如何高效配合？

---

## 1. 核心挑战

| 角色 | 能看到的 | 看不到的 |
|------|---------|---------|
| **你（用户）** | 模拟器/真机画面、点击响应延迟、动画流畅度、布局问题 | 代码逻辑、状态变化时序、网络请求细节、SwiftUI body 重绘原因 |
| **Claude** | 全部源代码、编译错误、Preview 渲染截图、控制台日志 | 运行时画面、交互延迟、手势反馈、导航过渡效果 |

**解决方案：让 App 自己说话——通过结构化日志和 Preview 渲染弥补双方的盲区。**

---

## 2. 协作工具箱

### 2.1 Claude 可用的工具

| 工具 | 用途 | 何时使用 |
|------|------|---------|
| `mcp__xcode__BuildProject` | 编译检查 | 每次代码修改后 |
| `mcp__xcode__RenderPreview` | 渲染 Preview 截图 | 验证静态布局/样式 |
| `mcp__xcode__XcodeListNavigatorIssues` | 查看编译警告/错误 | 构建失败时 |
| `mcp__xcode__RunAllTests` | 运行测试 | 验证逻辑正确性 |
| `mcp__supabase__execute_sql` | 直接查询数据库 | 验证数据层问题 |
| 代码中的 `AppLog` | 结构化日志 | 运行时状态诊断 |

### 2.2 用户的反馈模板

当你发现问题时，请用这个格式反馈：

```
**问题描述：** [一句话说明]
**操作步骤：** [1. 点击xx 2. 等待 3. 看到xx]
**预期行为：** [应该怎样]
**实际行为：** [实际怎样]
**控制台日志：** [粘贴相关日志，用 Cmd+/ 在 Xcode 打开控制台]
**截图/录屏：** [如有]
```

**精简版（日常使用）：**
```
问题：趋势页点击迟缓
操作：点击"女顶流解约费"卡片 → 等待 3 秒 → 无反应 → 再点 → 进入
控制台：[粘贴带 ⏱️ 的日志]
```

---

## 3. 结构化日志系统（AppLog）

### 3.1 日志工厂

在 `Core/Infrastructure/Logging/AppLog.swift` 中建立统一日志：

```swift
import OSLog

/// 集中化日志工厂
enum AppLog {
    static let network   = Logger(subsystem: "com.trendlens", category: "Network")
    static let data      = Logger(subsystem: "com.trendlens", category: "Data")
    static let ui        = Logger(subsystem: "com.trendlens", category: "UI")
    static let cache     = Logger(subsystem: "com.trendlens", category: "Cache")
    static let nav       = Logger(subsystem: "com.trendlens", category: "Navigation")
    static let lifecycle = Logger(subsystem: "com.trendlens", category: "Lifecycle")
    static let perf      = Logger(subsystem: "com.trendlens", category: "Performance")
}
```

### 3.2 日志格式约定

统一格式：`操作 状态 key=value key=value`

```swift
// 好 — 结构化、可过滤、可解析
AppLog.network.info("FETCH_TOPICS START platform=\(platform.rawValue) forceRefresh=\(forceRefresh)")
AppLog.network.info("FETCH_TOPICS SUCCESS count=\(topics.count) elapsed=\(elapsed)ms")
AppLog.network.error("FETCH_TOPICS FAILED error=\(error) platform=\(platform.rawValue)")

AppLog.cache.info("CACHE_CHECK result=\(isValid ? "HIT" : "MISS") age=\(age)s")
AppLog.nav.info("NAV_PUSH destination=\(destination) stackDepth=\(path.count)")
```

### 3.3 关键日志点

| 层级 | 日志点 | 信息 |
|------|--------|------|
| **ViewModel** | `fetchXxx START/SUCCESS/FAILED` | 加载触发、结果、错误 |
| **Repository** | `CACHE_CHECK HIT/MISS`, `REMOTE_FETCH` | 缓存命中率、网络耗时 |
| **Navigation** | `NAV_PUSH/POP destination stackDepth` | 导航栈变化 |
| **View lifecycle** | `VIEW_APPEAR/DISAPPEAR` | 视图生命周期 |
| **性能** | `BODY_EVAL viewName elapsed` | SwiftUI body 求值耗时 |

---

## 4. 调试 SwiftUI 的利器

### 4.1 `Self._printChanges()`

在任何 View 的 `body` 开头加一行，就能看到**是哪个属性变化触发了重绘**：

```swift
var body: some View {
    let _ = Self._printChanges()  // 控制台输出：FeedView: @State viewModel changed
    VStack { ... }
}
```

**使用场景：** 怀疑某个视图频繁重绘时。**用完记得删除。**

### 4.2 Debug 边框

```swift
extension View {
    func debugBorder(_ color: Color = .red) -> some View {
        #if DEBUG
        self.border(color, width: 1)
        #else
        self
        #endif
    }
}
```

对任何视图加 `.debugBorder()` 就能在模拟器上看到边界。

### 4.3 性能计时

```swift
/// 在关键操作前后打点
func timed<T>(_ label: String, operation: () async throws -> T) async rethrows -> T {
    let start = CFAbsoluteTimeGetCurrent()
    let result = try await operation()
    let elapsed = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
    AppLog.perf.info("\(label) elapsed=\(elapsed)ms")
    return result
}

// 使用
let topics = try await timed("fetchTrending") {
    try await repository.fetchAllLatestSnapshots(forceRefresh: true)
}
```

---

## 5. Preview 驱动验证

### 5.1 Claude 可渲染 Preview

Claude 可以通过 Xcode MCP 的 `RenderPreview` 渲染任何 SwiftUI Preview 并查看截图：

```
Claude: "让我渲染 TrendsView 的 Preview 看看布局..."
→ mcp__xcode__RenderPreview(sourceFilePath: "TrendLens/Features/Trends/Views/TrendsView.swift")
→ 看到截图 → 发现布局问题 → 修复
```

**适用场景：** 静态布局、色彩、字体、间距问题
**不适用：** 交互延迟、动画、导航流程

### 5.2 每个视图的多状态 Preview

为每个关键视图创建覆盖所有状态的 Preview：

```swift
#Preview("Feed - 加载中") { ... }
#Preview("Feed - 加载完成") { ... }
#Preview("Feed - 空状态") { ... }
#Preview("Feed - 错误状态") { ... }
```

Claude 可以逐一渲染验证每个状态的视觉效果。

---

## 6. 协作流程

### 6.1 标准开发循环

```
┌─────────────────────────────────────────────────┐
│  1. Claude 实现功能/修复                          │
│     ↓                                           │
│  2. Claude 构建 (mcp__xcode__BuildProject)       │
│     ↓ 编译通过                                   │
│  3. Claude 渲染 Preview (可选，验证静态布局)       │
│     ↓                                           │
│  4. 你在模拟器/真机上测试                          │
│     ↓                                           │
│  5. 你反馈结果：                                  │
│     ├─ ✅ 正常 → 下一个任务                       │
│     └─ ❌ 有问题 → 填写反馈模板 → 回到步骤 1      │
└─────────────────────────────────────────────────┘
```

### 6.2 调试交互问题（延迟、无响应、闪烁）

这类问题 Claude 无法通过 Preview 看到，需要你的帮助：

```
你：点击趋势卡片有 3 秒延迟
Claude：让我在按钮 action 和 ViewModel 中加入计时日志
→ 修改代码，加入 AppLog.perf 日志
→ 构建
你：运行后粘贴控制台日志
Claude：分析日志，定位瓶颈（网络？UI线程？手势冲突？）
→ 修复
你：确认修复
```

### 6.3 调试数据问题（数据缺失、格式错误）

```
你：关联话题显示 0 个
Claude：让我直接查 Supabase 数据库
→ mcp__supabase__execute_sql("SELECT count(*) FROM topic_trend_links WHERE keyword_id = 'xxx'")
→ 发现数据存在但查询条件过滤了
→ 修复查询
```

---

## 7. 常见问题速查

| 症状 | Claude 首先检查 | 你需要提供 |
|------|----------------|-----------|
| **白屏/闪退** | 编译错误、fatalError | Xcode 控制台崩溃日志 |
| **点击无响应** | 手势冲突、Button 缺失、导航注册 | 操作步骤 + 控制台日志 |
| **布局错乱** | padding/spacing/frame 值 | 截图 |
| **数据缺失** | Supabase 查询条件、DTO 映射 | 控制台网络日志 |
| **加载慢** | 网络耗时、缓存策略 | AppLog.perf 日志 |
| **重复渲染** | @State 变化、body 依赖 | `Self._printChanges()` 输出 |

---

## 8. 推荐工作习惯

### 对你（用户）

1. **Xcode 控制台常开**（`Cmd+Shift+C`）—— 方便随时粘贴日志
2. **发现问题先截图** —— 一张图胜过千言万语
3. **描述操作步骤** —— "点击第 3 个卡片"比"点击某个东西"有用 10 倍
4. **粘贴日志时过滤** —— 在 Xcode 控制台用 Filter 搜 `com.trendlens` 只看 App 日志

### 对 Claude

1. **每次改动后必须 Build** —— 不要让编译错误累积
2. **UI 变更先渲染 Preview** —— 能发现 70% 的布局问题
3. **交互问题先加日志** —— 不要猜测原因，让数据说话
4. **数据问题先查数据库** —— 用 Supabase MCP 直接验证

---

## 9. 接下来要做的

- [ ] 创建 `AppLog.swift` 日志工厂（替换所有 `print()`）
- [ ] 在 ViewModel 层添加结构化日志
- [ ] 在 Repository 层添加缓存/网络计时日志
- [ ] 创建 Debug 辅助工具（debugBorder、timed 等）
