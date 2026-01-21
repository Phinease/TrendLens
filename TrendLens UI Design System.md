# TrendLens UI Design System

> **文档定位：** UI 视觉设计规范与交互模式白皮书（权威参考）
> **技术实现：** 见 [DesignSystem.swift](TrendLens/UIComponents/DesignSystem.swift)
>
> **最后更新：** 2026-01-21

---

## 1. 设计理念

### 1.1 Liquid Glass（液态玻璃）美学

**核心关键词：** 透明、层次、流动、光影

TrendLens 采用 iOS 26 / macOS 26 的 **Liquid Glass** 设计语言，强调：

- **材质感**：毛玻璃效果、多层叠加、光线折射
- **流动性**：动画流畅、过渡自然、响应式设计
- **层次感**：深度、阴影、视差效果
- **呼吸感**：留白、间距、节奏

**设计目标：**

- 让用户感受到"透过镜头看热点"的体验
- 信息密度高但不拥挤
- 轻量、优雅、现代

---

## 2. 色彩系统

### 2.1 主色调（Primary Colors）

- **Accent Color**：系统默认强调色（支持用户自定义）
  - iOS/iPadOS：蓝色（#007AFF）
  - macOS：系统主题色

### 2.2 平台配色（Platform Identity）

每个平台使用其品牌色作为标识：

| 平台 | 主色 | RGB | Hex |
|------|------|-----|-----|
| 微博 | 橙红 | (217, 58, 56) | #D93A38 |
| 小红书 | 粉红 | (237, 51, 79) | #ED334F |
| Bilibili | 蓝色 | (0, 168, 209) | #00A8D1 |
| 抖音 | 深灰 | (22, 24, 35) | #161823 |
| X | 蓝色 | (29, 161, 242) | #1DA1F2 |
| 知乎 | 蓝色 | (10, 125, 250) | #0A7DFA |

**使用原则：**

- 平台徽标、Tab 指示器：使用平台色
- 卡片边框、高亮：使用平台色 + 透明度（0.3-0.6）
- 避免大面积使用平台色（保持整体风格统一）

### 2.3 语义色（Semantic Colors）

- **成功**：绿色 `.green`
- **警告**：黄色 `.yellow`
- **错误**：红色 `.red`
- **信息**：蓝色 `.blue`

### 2.4 中性色（Neutral Colors）

- **主文字**：`.primary`（深色模式自动适配）
- **辅助文字**：`.secondary`
- **占位文字**：`.tertiary`
- **分割线**：`.separator`
- **背景**：`.systemBackground` / `.systemGroupedBackground`

---

## 3. 字体系统

### 3.1 字体族

- **主字体**：SF Pro / SF Pro Rounded（系统字体）
- **数字字体**：SF Mono（用于热度值、排名）
- **标题字体**：Rounded 设计（增加亲和力）

### 3.2 字体层级

| 层级 | 字号 | 字重 | 用途 |
|------|------|------|------|
| Large Title | 34pt | Bold | 页面主标题 |
| Title | 28pt | Semibold | 卡片标题 |
| Headline | 20pt | Semibold | 段落标题 |
| Body | 17pt | Regular | 正文内容 |
| Caption | 15pt | Regular | 辅助信息 |
| Footnote | 13pt | Regular | 时间戳、标签 |

### 3.3 动态字体

- 支持 Dynamic Type（用户可调节字号）
- 关键信息区域限制最大字号（防止布局崩溃）

---

## 4. 间距系统

### 4.1 基础间距单位

采用 **8pt 网格系统**（8 的倍数）：

```
xxs: 4pt
xs:  8pt
sm:  12pt
md:  16pt
lg:  24pt
xl:  32pt
xxl: 48pt
```

### 4.2 组件间距规范

- **卡片内间距**：16pt（md）
- **卡片外间距**：16pt（md）
- **列表项间距**：12pt（sm）
- **按钮内边距**：水平 24pt（lg），垂直 12pt（sm）
- **页面边距**：16pt（md）

### 4.3 垂直节奏

- **小组件**：8pt 间距
- **相关组件**：16pt 间距
- **段落间**：24pt 间距
- **模块间**：32pt 间距

---

## 5. 圆角系统

### 5.1 圆角规范

| 尺寸 | 半径 | 用途 |
|------|------|------|
| Small | 8pt | 按钮、标签、输入框 |
| Medium | 16pt | 卡片、列表项 |
| Large | 24pt | 面板、模态框 |
| Extra Large | 32pt | 特殊组件（如启动页图标） |

### 5.2 连续曲线

- 优先使用 `RoundedRectangle` 而非 `Circle`（iOS 26 连续曲线优化）
- 大尺寸圆角使用连续曲线（视觉更柔和）

---

## 6. 阴影与深度

### 6.1 阴影层级

| 层级 | 模糊半径 | Y 偏移 | 透明度 | 用途 |
|------|----------|--------|--------|------|
| Subtle | 2pt | 1pt | 0.05 | 轻微悬浮 |
| Light | 4pt | 2pt | 0.08 | 卡片默认 |
| Medium | 8pt | 4pt | 0.12 | 悬浮态 |
| Heavy | 16pt | 8pt | 0.16 | 模态框 |

### 6.2 深度原则

- **Z 轴层级**：背景（0）→ 卡片（1）→ 悬浮按钮（2）→ 模态框（3）
- 避免过度使用阴影（保持轻量感）
- 深色模式下减少阴影强度

---

## 7. 材质效果（Material）

### 7.1 材质层级

| 材质 | 效果 | 用途 |
|------|------|------|
| Thin | 轻微模糊 | 轻量组件（标签） |
| Regular | 中等模糊 | 卡片背景 |
| Thick | 较强模糊 | 导航栏、工具栏 |
| Ultra Thick | 最强模糊 | 模态框背景 |

### 7.2 使用场景

- **导航栏/工具栏**：Thick Material
- **卡片背景**：Regular Material
- **浮动按钮**：Regular Material + 阴影
- **模态框**：Ultra Thick Material

---

## 8. 组件设计规范

### 8.1 卡片（Card）

**结构：**

```
┌─────────────────────────┐
│ [平台图标] 话题标题       │
│ 辅助信息（热度、时间）    │
│ [标签] [收藏图标]        │
└─────────────────────────┘
```

**规范：**

- 圆角：16pt（Medium）
- 背景：Regular Material
- 内边距：16pt
- 阴影：Light（默认）→ Medium（悬浮）
- 最小高度：80pt

**交互：**

- 点击：轻微缩放（0.98） + 阴影增强
- 长按：显示快捷菜单（收藏/分享/屏蔽）

### 8.2 平台徽章（Platform Badge）

**样式：**

- 圆形图标（32pt × 32pt）
- 平台色背景 + 白色图标
- 或：平台色边框 + 透明背景

**位置：**

- 卡片左上角
- Tab 栏图标

### 8.3 热度指示器（Heat Indicator）

**视觉形式：**

1. **数字 + 图标**：🔥 1.2万
2. **进度条**：横向填充条（高度 4pt）
3. **热度曲线**：小型折线图（见第 9 章）

**颜色映射：**

- 低热度（0-10k）：灰色 `.secondary`
- 中热度（10k-100k）：橙色 `.orange`
- 高热度（100k+）：红色 `.red`

### 8.4 排名变化（Rank Change）

**样式：**

- 上升：↑ 绿色 `.green`
- 下降：↓ 红色 `.red`
- 新增：NEW 蓝色 `.blue`
- 持平：— 灰色 `.secondary`

**位置：**

- 卡片右上角
- 排名数字旁边

### 8.5 按钮（Button）

**主按钮（Primary）：**

- 背景：Accent Color
- 文字：白色
- 圆角：8pt（Small）
- 内边距：水平 24pt，垂直 12pt

**次按钮（Secondary）：**

- 背景：Regular Material
- 文字：Primary
- 圆角：8pt
- 内边距：水平 24pt，垂直 12pt

**图标按钮（Icon）：**

- 圆形（40pt × 40pt）
- Regular Material
- 图标：20pt

### 8.6 输入框（TextField）

**样式：**

- 背景：Regular Material
- 圆角：8pt（Small）
- 内边距：水平 16pt，垂直 12pt
- 边框：无（聚焦时显示 Accent Color 边框）

---

## 9. 热度曲线设计（新增功能）

### 9.1 设计目标

**核心价值：** 让用户直观感受"热点的兴起与衰落"，而非仅看到静态数字。

**设计原则：**

- **轻量级**：不喧宾夺主，作为辅助信息
- **实时感**：动画流畅，传递"脉动"感
- **可交互**：支持点击查看历史详情

### 9.2 视觉样式

#### 9.2.1 小型曲线（卡片内嵌）

**尺寸：** 80pt × 32pt（宽 × 高）

**样式：**

- 折线图，无填充
- 线条颜色：根据热度映射（灰/橙/红）
- 线宽：2pt
- 平滑曲线（使用 Bézier 插值）
- 不显示坐标轴、刻度

**位置：**

- 卡片右下角
- 热度数字下方

**交互：**

- 点击卡片 → 展开详情页 → 显示完整曲线

#### 9.2.2 完整曲线（详情页）

**尺寸：** 全屏宽 × 200pt

**样式：**

- 渐变填充区域（从曲线到底部）
- 渐变色：平台色（顶部，透明度 0.3）→ 透明（底部）
- 虚线网格背景（淡灰色）
- Y 轴刻度：显示热度值（1k, 10k, 100k）
- X 轴刻度：显示时间（12:00, 18:00, 00:00）

**交互：**

- 拖动：显示精确时间点的热度值（悬浮气泡）
- 捏合缩放：调整时间范围（1小时 / 6小时 / 24小时 / 7天）

### 9.3 数据采样策略

**采样频率：**

- 高热话题（TOP 10）：每 10 分钟一个数据点
- 普通话题（TOP 50）：每 30 分钟一个数据点
- 长尾话题：每 1 小时一个数据点

**数据存储：**

- 扩展 `TrendTopic` 实体，增加 `heatHistory: [HeatDataPoint]`
- `HeatDataPoint` 结构：时间戳 + 热度值

```swift
struct HeatDataPoint: Codable, Sendable {
    let timestamp: Date
    let heatValue: Int
}
```

### 9.4 动画效果

**进入动画：**

- 曲线从左到右逐渐绘制（持续 0.8 秒）
- 使用 `trim(from:to:)` 动画

**更新动画：**

- 新数据点淡入
- 曲线平滑过渡（使用 `.easeInOut`）

**悬浮态：**

- 鼠标/手指悬停时，显示竖直虚线 + 数据气泡
- 气泡显示：时间、热度值、排名变化

### 9.5 技术实现

**使用框架：** Swift Charts（iOS 26 原生支持）

**核心代码结构：**

```swift
Chart(heatHistory) { dataPoint in
    LineMark(
        x: .value("时间", dataPoint.timestamp),
        y: .value("热度", dataPoint.heatValue)
    )
    .interpolationMethod(.catmullRom) // 平滑曲线
    .foregroundStyle(gradientColor)   // 渐变色

    AreaMark(
        x: .value("时间", dataPoint.timestamp),
        y: .value("热度", dataPoint.heatValue)
    )
    .foregroundStyle(areaGradient)
    .opacity(0.3)
}
.chartXAxis { ... }
.chartYAxis { ... }
```

### 9.6 特殊状态

**数据不足：**

- 少于 3 个数据点 → 不显示曲线
- 显示提示："数据收集中..."

**数据异常：**

- 热度值突降为 0 → 标记为"已下架"
- 曲线断开，显示 ⚠️ 图标

---

## 10. 动画与过渡

### 10.1 动画时长

| 类型 | 时长 | 曲线 | 用途 |
|------|------|------|------|
| Quick | 0.2s | easeInOut | 按钮点击、开关 |
| Standard | 0.3s | easeInOut | 页面切换、卡片展开 |
| Slow | 0.5s | easeInOut | 模态框出现 |
| Spring | — | spring(0.4, 0.8) | 弹性交互 |

### 10.2 页面过渡

- **TabView 切换**：淡入淡出（0.3s）
- **NavigationStack push/pop**：平移 + 淡入淡出（0.3s）
- **模态框**：从底部滑入（0.5s）

### 10.3 手势反馈

- **触觉反馈**：按钮点击（`.impact(.light)`）
- **视觉反馈**：缩放（0.95 → 1.0）
- **声音反馈**：关键操作（可选，默认关闭）

---

## 11. 响应式设计

### 11.1 断点（Breakpoints）

| 设备 | 宽度范围 | 布局方式 |
|------|----------|----------|
| iPhone | < 428pt | 单列，TabView 导航 |
| iPad | 428pt - 1024pt | 双列，NavigationSplitView |
| Mac | > 1024pt | 三列，Sidebar + Detail |

### 11.2 适配策略

- **iPhone**：单列卡片，全宽度
- **iPad**：双列网格，侧边栏 + 内容区
- **Mac**：三列布局，可调整列宽

### 11.3 横屏适配

- **iPhone 横屏**：双列网格
- **iPad 横屏**：三列网格
- **Mac**：保持三列（列宽增加）

---

## 12. 深色模式

### 12.1 颜色映射

| 元素 | 浅色模式 | 深色模式 |
|------|----------|----------|
| 背景 | 白色 | 黑色 |
| 卡片 | 浅灰 | 深灰 |
| 文字 | 黑色 | 白色 |
| 阴影 | 黑色 0.12 | 白色 0.05 |

### 12.2 平台色调整

- 深色模式下，平台色降低饱和度（-20%）
- 避免过亮的颜色（保护视力）

---

## 13. 无障碍设计

### 13.1 VoiceOver

- 所有交互元素提供语义化标签
- 图标按钮提供文字说明

### 13.2 颜色对比

- WCAG AA 级别：文字对比度 ≥ 4.5:1
- 关键元素对比度 ≥ 7:1

### 13.3 动画控制

- 尊重系统"减弱动态效果"设置
- 关键信息不依赖动画传递

---

## 14. 组件库清单

### 14.1 已实现组件

- [x] DesignSystem（字体、间距、圆角、材质）
- [x] SplashView（启动页）
- [x] MainNavigationView（跨平台导航）
- [x] FeedView（占位）
- [x] CompareView（占位）
- [x] SearchView（占位）
- [x] SettingsView（占位）

### 14.2 待实现组件

- [ ] TrendCard（热点卡片）
- [ ] PlatformBadge（平台徽章）
- [ ] HeatIndicator（热度指示器）
- [ ] HeatCurveView（热度曲线 - 小型）
- [ ] HeatCurveDetailView（热度曲线 - 完整）
- [ ] RankChangeIndicator（排名变化）
- [ ] EmptyStateView（空状态）
- [ ] ErrorView（错误态）
- [ ] LoadingView（加载态）
- [ ] FilterChips（平台筛选器）
- [ ] PullToRefreshView（下拉刷新）

---

## 15. 设计交付物

### 15.1 Figma 设计稿（推荐）

**包含内容：**

- 全部页面设计（iPhone / iPad / Mac）
- 组件库（可复用组件）
- 交互原型（页面跳转、动画）
- 设计规范标注

### 15.2 SF Symbols 使用

**推荐图标：**

- 热榜：`flame`
- 对比：`chart.bar.xaxis`
- 搜索：`magnifyingglass`
- 设置：`gear`
- 收藏：`heart` / `heart.fill`
- 分享：`square.and.arrow.up`
- 排名上升：`arrow.up.circle.fill`
- 排名下降：`arrow.down.circle.fill`
- 热度曲线：`chart.line.uptrend.xyaxis`

---

## 16. 参考资源

**Apple 官方指南：**

- [Human Interface Guidelines - iOS 26](https://developer.apple.com/design/human-interface-guidelines/ios)
- [Human Interface Guidelines - macOS 26](https://developer.apple.com/design/human-interface-guidelines/macos)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Swift Charts](https://developer.apple.com/documentation/Charts)

**设计灵感：**

- Spotify（数据可视化）
- Twitter / X（信息流设计）
- Apple Stocks（曲线图交互）
- Notion（卡片设计）

---

## 17. 版本历史

- **v1.0（2026-01-21）**：初始版本，定义 Liquid Glass 设计系统 + 热度曲线设计规范
