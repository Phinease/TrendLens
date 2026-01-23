# TrendLens 开发进展

> **文档定位：** 当前开发进度与任务追踪（唯一权威来源）
> **阶段定义参考：** [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md) 第 7 章
>
> **当前阶段：** 阶段 1.5 - UI 系统重构（Ethereal Insight）
> **最后更新：** 2026-01-23

---

## 已完成阶段

### 阶段 0：项目基建 ✅

完成日期：2026-01-21

- Clean Architecture 目录结构、依赖注入容器
- Domain/Data/Infrastructure 三层架构
- 基础导航结构（iPhone TabView / iPad+macOS NavigationSplitView）
- 炫酷启动页（SplashView）
- 三端编译验证通过

### 阶段 0.5：UI 设计深化 ✅

完成日期：2026-01-22

- Prismatic Flow 设计系统（平台渐变色带、热度光谱、3D 阴影层级）
- UI 组件库（TrendCard、PlatformBadge、HeatIndicator、RankBadge 等 14 个组件）
- 热度曲线功能（HeatCurveView、HeatCurveMini、触摸交互）
- Feed 页面完整 UI（平台 Tab 切换、热榜列表、话题详情 Sheet）
- 三端编译验证通过

### 阶段 1：MVP（本地 SwiftData + Mock 数据）✅

完成日期：2026-01-23

**核心实现：**

- MockDataGenerator 动态生成数据（替代固定 MockData）
- 首次启动数据填充（6 平台各 15 条话题）
- FeedView 完整数据流（ViewModel 连接、下拉刷新、收藏、屏蔽词过滤）
- CompareView 完整实现（平台多选、交集/差集计算、对比结果展示）
- SearchView 完整实现（实时搜索、平台筛选、结果列表）
- SettingsView 完整实现（订阅平台管理、屏蔽词管理、刷新设置、关于页面）

**关键技术修复：**

- Swift 6 并发问题：UserPreference Sendable、@MainActor 隔离
- SwiftData error 1：所有 Predicate 避免捕获外部变量，改用内存过滤
- 禁用远程请求：`isRemoteEnabled = false` 配置开关

**技术要点：**

- SwiftData ModelContext 必须在 @MainActor 上使用
- SwiftData Predicate 不应捕获外部变量（即使是简单类型）
- 正确做法：获取所有数据 → 内存过滤

---

## 当前阶段

### 阶段 3：导航系统升级 🚧

**目标：** FloatingDock + FluidRibbon 都能正常工作，平台切换顺畅

**设计文档：** [TrendLens New UI Design System.md](TrendLens%20New%20UI%20Design%20System.md)

**前置条件：** Phase 2 完成 ✅

**开发策略：** 垂直切片式迭代，每个 Phase 都有**立即可视觉验证**的成果。

---

## ⚠️ 重要开发原则

**本项目处于研发阶段，UI 系统正在全面重构：**

1. **不考虑兼容旧设计**：直接删除旧代码（TrendCard 等），不做适配层
2. **保持代码清洁**：避免为了兼容而引入冗余代码或中间层
3. **逐步迭代验证**：每个 Phase 完成后都能在 Simulator 或 Canvas 中看到实际效果

**旧代码处理规则：**

- ❌ 禁止保留 `@available(*, deprecated)` 的旧 API
- ❌ 禁止创建"适配旧组件"的兼容层
- ✅ 直接删除并替换旧实现（如 TrendCard.swift）
- ✅ 不确定能否删除时，先注释并标注 `// TODO: 待删除 - UI 重构`

---

## 🎯 垂直切片式开发计划（6 Phase）

### Phase 1.5.1：基础系统 + 第一个可见卡片 ✅ 立即可验证

**交付成果：** 在 Preview / Simulator 中看到一个完整的 StandardCard，样式符合新设计

完成日期：2026-01-23

- [x] **1.1 提前扩展 Mock 数据**（最先做，为后续 Phase 解锁可视化）
  - [x] 向 `TrendTopicEntity` 添加 `summary: String?` 字段（AI 摘要）
  - [x] 向 `TrendTopicEntity` 添加 `heatHistory: [HeatDataPoint]` 字段（趋势数据）
  - [x] 更新 SwiftData Model `TrendTopic`（同步字段）
  - [x] 更新 `MockDataGenerator.swift`
    - [x] 为每条话题生成 2-3 行的 AI 摘要文本
    - [x] 为 Top 10 话题生成 12 个时间点的 heatHistory（模拟 2 小时数据）
    - [x] 为其他话题生成最少 3 个点的 heatHistory
  - [x] 验证 Mock 数据格式（无需连接真实后端）

- [x] **1.2 重构 DesignSystem.swift**（建立设计基础）
  - [x] **删除** 旧的 `PlatformColor` 大面积使用相关定义
  - [x] 新增中性色基底（在 Assets.xcassets 或代码定义）
    - [x] `.backgroundPrimary` (浅: #FAFBFC, 深: #0A0E14)
    - [x] `.backgroundSecondary` (浅: #F3F4F6, 深: #13171F)
    - [x] `.container` (浅: #FFFFFF, 深: #1A1F2E)
    - [x] `.containerHover` (半透明变体)
    - [x] `.borderSubtle` (浅: rgba(0,0,0,0.06), 深: rgba(255,255,255,0.08))
  - [x] 新增平台 Hint Colors（仅用于 Icon 识别）
    - [x] 为每个 Platform 添加 `hintColor` 属性（单色，16×16pt Icon 用）
    - [x] 为每个 Platform 添加 `selectionGradient` 属性（仅用于 2pt 下划线）
  - [x] 实现 Heat Spectrum 系统
    - [x] `heatColor(for value: Int) -> Color` 函数（7 级热度 → 色值映射）
    - [x] `heatEffectLevel(for value: Int) -> HeatEffect` 函数（决定是否发光/脉冲）
    - [x] `enum HeatEffect { case none, glow(radius), pulse, burst }`
  - [x] 添加阴影预设 ViewModifier
    - [x] `.cardShadow()` modifier（6pt，y 4pt，colorScheme 自适配）
    - [x] `.elevatedShadow()` modifier（16pt，y 8pt，colorScheme 自适配）
  - [x] 更新间距常量（Spacing enum: xxs/xs/sm/md/lg/xl/xxl）
  - [x] 更新圆角常量（HeroCard: 24pt, StandardCard: 16pt, Button: 12pt）

- [x] **1.3 实现原子级组件**
  - [x] **PlatformIcon.swift**
    - [x] 16×16pt，圆角 4pt，使用 `platform.hintColor` 背景
    - [x] SF Symbol 图标（10pt，白色）
    - [x] Preview 验证：展示 6 个平台的 Icon
  - [x] **RankChangeIndicator.swift**
    - [x] 4 种状态：up(Int) / down(Int) / new / unchanged
    - [x] 12pt Icon + 13pt Text，使用语义色（Success/Error/Info）
    - [x] Preview 验证：展示 4 种状态

- [x] **1.4 实现 MiniTrendLine.swift**
  - [x] 使用 Swift Charts 绘制
  - [x] 两个尺寸：80×32pt (Hero) / 32×24pt (Standard)
  - [x] catmullRom 插值平滑曲线，线宽 1.5pt
  - [x] 颜色从 `heatColor(for: currentHeat)` 获取
  - [x] 隐藏坐标轴、网格、Legend
  - [x] 数据验证（最少 3 点，最多 12 点；超过则均匀抽样）
  - [x] Preview 验证：不同热度值的不同颜色

- [x] **1.5 实现 StandardCard.swift（完整初版）**
  - [x] 创建文件：`UIComponents/Cards/StandardCard.swift`
  - [x] **布局结构：**

    ```
    第一行：排名(20pt) | 标题(17pt Semibold) | 热度Icon
    第二行：空白(44pt 缩进) | AI摘要(15pt, 2行截断, Secondary)
    第三行：空白(44pt 缩进) | PlatformIcon · 时间 · 热度值 · RankIndicator | MiniTrendLine(32×24)
    ```

  - [x] 背景：`.container` + `.cardShadow()`
  - [x] 圆角 16pt (continuous)
  - [x] 内边距 16pt
  - [x] 集成 PlatformIcon（16×16pt）
  - [x] 集成 RankChangeIndicator
  - [x] 集成 MiniTrendLine（32×24pt）
  - [x] 创建 Preview Provider，展示不同平台/排名变化/热度等状态

- [x] **1.6 创建临时 CardGalleryView（立即可视化）**
  - [x] 创建：`Features/Preview/CardGalleryView.swift`
  - [x] 展示 StandardCard 的多个变体：
    - [x] 6 个不同平台
    - [x] 4 种排名变化（up/down/new/same）
    - [x] 3 个不同热度等级（触发不同颜色）
    - [x] 有/无 AI 摘要的两个版本
  - [x] 在 `TrendLensApp.swift` 中临时设置为根视图（便于快速检查）
  - [x] Preview 运行无误

**验收标准：**

- ✅ CardGalleryView 在 Simulator 和 Canvas 中都能正常显示
- ✅ 深色/浅色模式切换正常，对比度符合设计
- ✅ MiniTrendLine 颜色随热度值正确变化
- ✅ 所有子组件 Preview Provider 都能正常运行
- ✅ 编译无警告

---

### Phase 2：Feed 页面集成 ✅ 可用的完整页面

**交付成果：** 打开 App 能看到 Feed 页面显示新卡片，可上下滚动

**完成日期：** 2026-01-23

**前置条件：** Phase 1 完成

- [x] **2.1 实现 HeroCard.swift**（焦点卡片） ✅ 2026-01-23
  - [x] 创建文件：`UIComponents/Cards/HeroCard.swift`
  - [x] **布局结构：**

    ```
    排名水印(48pt Bold, opacity 0.2) + 热度Icon
    标题(28pt Bold Rounded, 2行截断)
    AI摘要(17pt Regular, 3行截断, Secondary)
    ┌─────────────────────┐
    │ MiniTrendLine(80×32)│ 热度值 · RankIndicator
    └─────────────────────┘
    PlatformIcon · 时间
    ```

  - [x] 最小高度 240pt，圆角 24pt
  - [x] 背景渐变氛围：基于热度值，使用 `heatColor` 的低饱和度版本（opacity 0.15 → 0.05）
  - [x] 内边距 24pt
  - [x] `.elevatedShadow()` 强调焦点
  - [x] 集成 MiniTrendLine（80×32pt）
  - [x] Preview 验证（6 平台 × 随机热度 × 有/无摘要）

**验证结果：**

- ✅ 编译成功，无错误无警告
- ✅ 设计系统检查清单全部通过：
  - ✅ 背景：热度渐变氛围（LinearGradient opacity 0.15→0.05）
  - ✅ 圆角：24pt continuous（DesignSystem.CornerRadius.large）
  - ✅ 内边距：24pt（DesignSystem.Spacing.lg）
  - ✅ 阴影：.elevatedShadow()（8pt radius, 0.12 opacity）
  - ✅ 排名：水印式，48pt，opacity 0.2，右上角对齐
  - ✅ 标题：28pt Bold Rounded，2行截断
  - ✅ 摘要：17pt Regular，3行截断，.secondary
  - ✅ 趋势线：80×32pt，MiniTrendLine(size: .hero)
  - ✅ 热度值颜色：DesignSystem.HeatSpectrum.color(for:)
  - ✅ 文字颜色：.primary / .secondary / .tertiary（无硬编码）
  - ✅ 平台Icon：16×16pt，PlatformIcon component
  - ✅ 排名变化：RankChangeIndicator(style: .compact)
- ✅ Preview Provider 包含 6 平台 × 随机变化，能正常显示

- [x] **2.2 重构 FeedView.swift** ✅ 2026-01-23
  - [x] **删除** 旧的 TrendCard 相关代码
  - [x] 实现 Hero + Standard 混合布局
    - [x] Rank 1-3：使用 HeroCard
    - [x] Rank 4+：使用 StandardCard
  - [x] 保留原有的数据流和 ViewModel（不改业务逻辑）
  - [x] 更新列表间距（Hero 间: 16pt, Standard 间: 12pt）
  - [x] 页面背景改为 `.backgroundPrimary`
  - [x] 底部留白 80pt（为后续 FloatingDock 预留空间）
  - [x] 保留现有平台 Tab（暂时保持，Phase 3 升级为 FluidRibbon）
  - [x] 测试滚动流畅度

- [x] **2.3 临时验证** ✅ 2026-01-23
  - [x] CardGalleryView 保留（未删除，但不作为主视图）
  - [x] 在 `TrendLensApp.swift` 恢复为 FeedView + SplashView（1.5s 启动动画）
  - [x] 编译验证通过，无错误无警告

**验证结果：**

- ✅ 编译成功：xcodebuild build succeeded
- ✅ HeroCard + StandardCard 混合布局已集成：
  - ✅ Rank 1-3 显示 HeroCard（高度 240pt，排名水印，趋势线）
  - ✅ Rank 4+ 显示 StandardCard（紧凑布局）
  - ✅ Hero 间距 16pt（DesignSystem.Spacing.md）
  - ✅ Standard 间距 12pt（DesignSystem.Spacing.sm）
- ✅ 页面背景：使用 DesignSystem.Neutral.backgroundPrimary(colorScheme)（自适配深色/浅色）
- ✅ 底部留白：80pt（为 FloatingDock 预留空间）
- ✅ 平台选择 Tab：保留现有功能
- ✅ 数据流：未修改 ViewModel 逻辑，保持原有业务功能
- ✅ 启动流程：SplashView（1.5s）→ FeedView

**验收标准：**

- ✅ Feed 页面正常加载（使用 Mock 数据）
- ✅ Top 3 显示 HeroCard，其余显示 StandardCard
- ✅ 滚动流畅，60fps（检查 Instruments）
- ✅ 深色模式正确显示

---

### Phase 3：导航系统升级 ✅ 完整交互体验

**交付成果：** FloatingDock + FluidRibbon 都能正常工作，平台切换顺畅

**前置条件：** Phase 2 完成

- [ ] **3.1 实现 FluidRibbon.swift**（流体化平台选择器）
  - [ ] 创建文件：`UIComponents/Navigation/FluidRibbon.swift`
  - [ ] 高度 48pt，使用 `.thinMaterial` 背景
  - [ ] 横向滚动 Chip 列表（间距 24pt，内边距 16pt）
  - [ ] 选中态：
    - [ ] 文字加粗（Semibold）
    - [ ] 底部渐变下划线（2pt 高，使用 `platform.selectionGradient`）
  - [ ] 动画：`matchedGeometryEffect` + spring(0.4, 0.8)
  - [ ] 支持两种切换方式：
    - [ ] 点击 Chip 切换
    - [ ] 页面左右滑动切换（可选，Phase 3 暂不实现）
  - [ ] Preview 验证

- [ ] **3.2 更新 FeedView.swift（集成 FluidRibbon）**
  - [ ] 删除旧的平台 Tab/Chip 组件
  - [ ] 将 FluidRibbon 作为顶部固定组件
  - [ ] 绑定 `selectedPlatform` 状态，数据筛选逻辑保持不变
  - [ ] 测试平台切换

- [ ] **3.3 实现 FloatingDock.swift**（悬浮导航栏）
  - [ ] 创建文件：`UIComponents/Navigation/FloatingDock.swift`
  - [ ] 胶囊形状：高度 56pt，圆角 28pt（continuous）
  - [ ] 背景：`.ultraThinMaterial` + 1pt 边框（`.white.opacity(0.1)`）
  - [ ] 图标定义（Feed / Compare / Search）：
    - [ ] 未选中：`flame` / `chart.bar.xaxis` / `magnifyingglass`（24×24pt）
    - [ ] 选中：`flame.fill` / `chart.bar.xaxis.ascending` / `magnifyingglass.circle.fill`
  - [ ] 选中指示器：6pt 圆点，位于图标下方中心，matchedGeometryEffect
  - [ ] 自动隐藏逻辑（监听 ScrollView 的 offset）：
    - [ ] 向下滚动速度 > 50pt/s 时，Dock 隐藏（offset +20, opacity 0）
    - [ ] 向上滚动或停止 0.5s 后，Dock 显示（spring 动画）
    - [ ] 触发到页面顶部或底部时强制显示
  - [ ] 阴影：`.elevatedShadow()`
  - [ ] Preview 验证

- [ ] **3.4 重构 MainNavigationView.swift**
  - [ ] 删除标准 TabView
  - [ ] 使用 FloatingDock 作为导航容器
  - [ ] 实现页面切换逻辑（Feed / Compare / Search）
  - [ ] iPad/Mac：保持 NavigationSplitView（如原有）
  - [ ] 集成自动隐藏功能

**验收标准：**

- ✅ FluidRibbon 顶部显示，平台切换数据正确筛选
- ✅ FloatingDock 底部悬浮显示，选中指示器动画流畅
- ✅ Dock 滚动时自动隐藏，靠近顶部时显示
- ✅ 三个标签页能正常切换

---

### Phase 4：其他页面与状态组件 ✅ 全局统一体验

**交付成果：** Compare / Search / Settings 都使用新设计，所有页面统一风格

**前置条件：** Phase 3 完成

- [ ] **4.1 重构 CompareView.swift**
  - [ ] 删除旧的平台选择器
  - [ ] 使用 FluidRibbon（但改为多选模式，或使用 Checkmark）
  - [ ] 对比结果使用 StandardCard
  - [ ] 背景改为 `.backgroundPrimary`
  - [ ] 添加交集/差集的视觉区分（可选：背景色微调或分组分隔）

- [ ] **4.2 重构 SearchView.swift**
  - [ ] 搜索输入框新设计：
    - [ ] 背景 `.container` 或 `.thinMaterial`
    - [ ] 12pt 圆角
    - [ ] 聚焦时显示渐变边框（使用低热度色）
    - [ ] 搜索结果使用 StandardCard
    - [ ] 空状态使用新的 EmptyStateView

- [ ] **4.3 更新状态组件**
  - [ ] **EmptyStateView.swift**（无数据态）
    - [ ] 图标 + 文字居中布局
    - [ ] 使用中性色
    - [ ] 可选：轻微浮动动画
  - [ ] **SkeletonCard.swift**（加载态）
    - [ ] 改用渐变闪烁动画（而非灰色块）
    - [ ] 形状匹配 StandardCard 布局
    - [ ] 动画时长 1.5s，repeatForever
  - [ ] **ErrorView.swift**（错误态）
    - [ ] 图标 + 错误信息 + 重试按钮
    - [ ] 按钮样式与新设计对齐

- [ ] **4.4 响应式布局（iPad/Mac）**
  - [ ] iPad（428pt - 1024pt）：
    - [ ] 使用 LazyVGrid 2 列布局
    - [ ] FloatingDock 可能改为顶部 Tab（或保留底部并调整 padding）
  - [ ] Mac（> 1024pt）：
    - [ ] NavigationSplitView 三列：Sidebar + 内容 + 详情
    - [ ] 顶部 Tab 改为 Sidebar 选项
  - [ ] 断点定义：`@Environment(\.horizontalSizeClass)` 和 `.widthClass`

**验收标准：**

- ✅ Compare / Search 页面都能正常显示和交互
- ✅ 空/加载/错误态都应用新设计
- ✅ iPad 和 Mac 布局合理，没有信息丢失
- ✅ Settings 页面背景改为 `.backgroundPrimary`

---

### Phase 5：高级特效与交互 ✅ 最终打磨

**交付成果：** 发光、脉冲、卡片交互等高级特效完整实现

**前置条件：** Phase 4 完成

- [ ] **5.1 实现热度特效**
  - [ ] 创建 `Modifiers/HeatEffectModifier.swift`
  - [ ] **发光效果**（100k-500k 热度）：
    - [ ] 使用 `.shadow(color: heatColor, radius: 2-4, y: 0)`
    - [ ] 应用于卡片右上角的 热度Icon 或整个卡片
  - [ ] **脉冲动画**（500k-1M 热度）：
    - [ ] 使用 `.scaleEffect(1.0 → 1.03 → 1.0)`
    - [ ] 周期 1.5s，repeatForever，easeInOut
    - [ ] 仅在 Top 3 或高热度卡片应用
  - [ ] **粒子效果**（1M+ 超热度，可选）：
    - [ ] 简化版：增强脉冲 + 发光强度
    - [ ] 完整版：TimelineView + Canvas 绘制粒子
  - [ ] 集成到 HeroCard（始终检查） 和 StandardCard（高热度检查）
  - [ ] 尊重系统 `accessibilityReduceMotion` 设置

- [ ] **5.2 实现卡片交互**
  - [ ] 点击反馈：
    - [ ] 缩放效果 `scaleEffect(0.98)` 时长 0.1s
    - [ ] 触觉反馈 `.sensoryFeedback(.impact(.light), trigger: isPressed)`
  - [ ] 滑动操作（仅 iPhone）：
    - [ ] 左滑屏蔽：swipeActions(edge: .trailing) 红色 destructive
    - [ ] 右滑收藏：swipeActions(edge: .leading) 蓝色
    - [ ] 提示文字和图标
  - [ ] 长按快捷菜单（contextMenu）：
    - [ ] 复制标题、分享、屏蔽、详情等选项

- [ ] **5.3 实现详情页转场**
  - [ ] 创建 DetailView（显示完整话题信息）
  - [ ] 使用 `@Namespace` 和 `matchedGeometryEffect`
  - [ ] 卡片展开动画：spring(response: 0.4, dampingFraction: 0.8)
  - [ ] 背景模糊过渡：`.background(.ultraThinMaterial)`
  - [ ] 关闭时反向动画

- [ ] **5.4 性能优化**
  - [ ] Instruments 检查列表滚动性能（60fps）
  - [ ] 检查内存泄漏（CardGalleryView / DetailView 回收）
  - [ ] 图片加载优化（如有远程资源）
  - [ ] SwiftData 查询优化（确保不阻塞主线程）

- [ ] **5.5 代码清理**
  - [ ] **搜索并删除所有旧组件文件：**
    - [ ] `TrendCard.swift`（已被 HeroCard/StandardCard 替代）
    - [ ] 旧的 `PlatformBadge.swift`（已被 PlatformIcon 替代）
    - [ ] 旧的 `HeatIndicator.swift`（如果完全替代）
    - [ ] 旧的 Prismatic Flow 相关组件
  - [ ] 搜索代码库中所有 `// TODO: 待删除` 注释并完成或删除
  - [ ] 检查是否有废弃的 import
  - [ ] 运行 SwiftLint，修复所有警告

**验收标准：**

- ✅ 高热度卡片（500k+）有可见的脉冲/发光效果
- ✅ 卡片点击有缩放反馈和触觉反馈
- ✅ 滑动和长按操作正常工作
- ✅ 详情页转场动画流畅，无闪烁
- ✅ 代码库无旧 TrendCard 相关文件
- ✅ 编译无警告，无 Swift Lint 错误

---

### Phase 6：三端验证与文档更新 ✅ 最终交付

**交付成果：** 所有平台验证通过，文档完全同步，UI 重构完成

**前置条件：** Phase 5 完成

- [ ] **6.1 三端编译验证**
  - [ ] iPhone target：编译 + 运行（真机 or 模拟器）
  - [ ] iPad target：编译 + 运行（验证响应式布局）
  - [ ] Mac target：编译 + 运行（验证三列布局）
  - [ ] 所有 scheme 都能编译，无警告

- [ ] **6.2 视觉与交互走查**
  - [ ] **深色模式完整走查：**
    - [ ] 所有卡片背景颜色对比度 > 4.5:1
    - [ ] 文字颜色在深色背景下清晰
    - [ ] 阴影效果在深色模式下可见（使用白色阴影）
  - [ ] **动态字体测试：**
    - [ ] 最小尺寸（Extra Small）- 内容不溢出
    - [ ] 最大尺寸（Accessibility Sizes）- 排版不破坏
    - [ ] 标题和摘要截断位置正确
  - [ ] **VoiceOver 测试（关键页面）：**
    - [ ] Feed 页面卡片读取顺序正确
    - [ ] 按钮和交互元素标签清晰
  - [ ] **触觉反馈验证：**
    - [ ] 点击卡片有反馈
    - [ ] 平台切换有反馈
    - [ ] 手势操作有反馈

- [ ] **6.3 更新文档**
  - [ ] 标记 Development Plan 中阶段 1.5 为"已完成"
  - [ ] 更新 CLAUDE.md 中的组件引用
    - [ ] 删除对旧 TrendCard 的引用
    - [ ] 添加对新组件（HeroCard / StandardCard / FluidRibbon）的说明
  - [ ] 在 Progress.md 中记录 Phase 6 完成时间
  - [ ] 标记整个阶段 1.5 为 ✅ 已完成

- [ ] **6.4 最终检查**
  - [ ] 确认没有遗留的 `// TODO` 或 `FIXME` 注释
  - [ ] 确认没有 `print()` 或 debug 代码留在生产代码中
  - [ ] 确认所有 Preview Provider 都能在 Xcode 中正确显示
  - [ ] 运行一次完整的构建和运行

**验收标准：**

- ✅ 三端都能运行，无编译错误/警告
- ✅ 视觉走查通过，颜色对比、排版符合设计规范
- ✅ 文档与代码同步，阶段 1.5 标记完成
- ✅ 代码库干净，没有废弃文件或临时代码

---

## 重要提醒

**开发过程中遇到的常见问题：**

1. **不要为了保留旧代码而创建兼容层**
   - ❌ 错误：同时保留 TrendCard 和 StandardCard，用条件判断选择
   - ✅ 正确：直接删除 TrendCard，完全替换为 StandardCard

2. **不要在高层 View 中导入多个版本的同一组件**
   - ❌ 错误：在 FeedView 中同时导入和使用 TrendCard + StandardCard
   - ✅ 正确：FeedView 只知道 HeroCard/StandardCard

3. **深色模式色值必须配对定义**
   - ❌ 错误：只定义浅色，深色使用 `.opacity()` 调整
   - ✅ 正确：浅色和深色分别定义完整色值

4. **Mock 数据的 heatHistory 必须有意义**
   - ❌ 错误：所有话题的热度曲线都一样
   - ✅ 正确：Top 话题是上升趋势，新话题是暴增，老话题是平稳或下降

---

## 未来阶段

### 阶段 2：远程数据 + CDN 集成

**目标：** 连接真实后端数据源，完成网络层集成。

**前置条件：** 阶段 1.5 完成（UI 重构完成）

- [ ] 配置 CDN 端点
  - [ ] 确定 CDN 提供商（Cloudflare / AWS CloudFront / 国内 CDN）
  - [ ] 配置静态 JSON 文件存储路径
  - [ ] 设置多区域回退（国内/国外）
  - [ ] RemoteTrendingDataSource 配置真实 baseURL
- [ ] ETag 缓存优化
  - [ ] 验证 NetworkClient 的 If-None-Match 支持
  - [ ] 测试 304 响应处理
  - [ ] 验证缓存命中率
- [ ] 数据刷新策略
  - [ ] validUntil 时间配置（建议 15-30 分钟）
  - [ ] 手动刷新触发网络请求
  - [ ] 自动刷新间隔配置
- [ ] 错误处理和降级
  - [ ] 网络失败时使用过期缓存
  - [ ] 显示数据时效性标识
  - [ ] 离线模式提示
- [ ] 性能优化
  - [ ] 并行请求多平台数据（TaskGroup）
  - [ ] 请求超时配置优化
  - [ ] 流量监控

## 阶段 3：后台刷新 + 通知

**目标：** 实现后台数据刷新和可选的推送通知。

- [ ] BGTaskScheduler 集成
- [ ] 本地通知（热点突发提醒、收藏话题更新）
- [ ] 电量和流量优化

## 阶段 4：云端刷新程序

**目标：** 搭建服务端定时抓取和 JSON 生成服务。

- [ ] 爬虫程序开发（微博、小红书、B站、抖音、X、知乎）
- [ ] Snapshot 生成器（数据清洗、热度归一化、排名变化计算）
- [ ] 定时任务调度（每 10-15 分钟刷新）
- [ ] JSON 上传到 CDN
- [ ] 监控和日志

## 阶段 5：用户体系（可选）

**目标：** 引入用户账号系统，支持云端数据同步。

- [ ] BaaS 选型和集成
- [ ] 云端偏好同步（收藏、屏蔽词、订阅平台）
- [ ] 匿名用户迁移
- [ ] 隐私和安全

## 阶段 6：质量与发布

**目标：** 完善测试、优化性能、准备发布。

- [ ] 单元测试（Domain 90%, Data 80%, Presentation 75%）
- [ ] UI 测试
- [ ] 性能优化（启动 < 2s, 列表 60fps）
- [ ] 隐私合规
- [ ] 发布准备（App Store 提交）

---

## 术语参考

所有项目术语定义见 [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md) 第 10 章。
