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

### 阶段 1.5.5：高级特效与交互 🚧

**目标：** 发光、脉冲、卡片交互等高级特效完整实现

**设计文档：** [TrendLens New UI Design System.md](TrendLens%20New%20UI%20Design%20System.md)

**前置条件：** Phase 1.5.4 完成 ✅

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

### Phase 1.5.1：基础系统 + 第一个可见卡片 ✅

**完成日期：** 2026-01-23

**核心交付：** DesignSystem 重构、原子级组件库（PlatformIcon、RankChangeIndicator、MiniTrendLine、StandardCard）

**实现细节收纳** → 参见 [TrendLens New UI Design System.md](TrendLens%20New%20UI%20Design%20System.md) 第 3-5 章、第 7.3-7.4 章

---

### Phase 1.5.2：Feed 页面集成 ✅

**完成日期：** 2026-01-23

**核心交付：** HeroCard 实现、FeedView 重构为 Hero+Standard 混合布局

**实现细节收纳** → 参见 [TrendLens New UI Design System.md](TrendLens%20New%20UI%20Design%20System.md) 第 7.3 章

---

### Phase 1.5.3：导航系统升级 ✅

**完成日期：** 2026-01-23

**交付成果：** 官方 TabView + FluidRibbon 完全集成，平台切换顺畅，导航交互流畅

**实现细节收纳** → 参见 [TrendLens New UI Design System.md](TrendLens%20New%20UI%20Design%20System.md) 第 7.2 章、第 8 章

**验收清单：**

- ✅ FluidRibbon 顶部显示，平台切换数据正确筛选
- ✅ 官方 TabView 导航流畅，选中指示器动画自然
- ✅ 三个标签页能正常切换
- ✅ iPhone/iPad/Mac 编译验证通过

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
