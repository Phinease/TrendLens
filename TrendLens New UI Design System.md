# TrendLens New UI Design System

> **文档定位：** 新一代 UI 设计系统完整规范（可直接落地）
> **设计版本：** v3.0 - Ethereal Insight (灵动洞察)
> **创建日期：** 2026-01-23
> **技术实现：** 见 TrendLens/UIComponents/
>
> **实现状态：**
>
> - ✅ 第 3-6 章（色彩系统、字体、间距、材质）：已实现于 DesignSystem.swift
> - ✅ 第 7.2-7.3 章（FluidRibbon、HeroCard、StandardCard、PlatformIcon、MiniTrendLine）：已实现
> - ✅ 第 8 章（布局系统）：使用官方 TabView 实现
> - ⏳ 第 7.4-7.6 章（其他组件、空/加载态、交互）：Phase 4-5 开发中
>
> **注意：** 本文档为设计规范，已实现部分以代码为准，未实现部分作为开发指引

---

## 目录

1. [设计理念](#1-设计理念ethereal-insight灵动洞察)
2. [核心设计原则](#2-核心设计原则)
3. [色彩系统重构](#3-色彩系统重构)
4. [字体系统](#4-字体系统)
5. [间距与圆角](#5-间距与圆角)
6. [材质与深度](#6-材质与深度)
7. [核心组件设计](#7-核心组件设计)
8. [布局系统](#8-布局系统)
9. [交互与动效](#9-交互与动效)
10. [响应式设计](#10-响应式设计)
11. [深色模式](#11-深色模式)
12. [无障碍设计](#12-无障碍设计)
13. [实现指南](#13-实现指南)

---

## 1. 设计理念：Ethereal Insight (灵动洞察)

### 1.1 核心愿景

**从"展示数据的聚合器"转型为"智能化的热点阅读器"**

TrendLens 不再只是"展示热搜数据"，而是帮助用户**快速理解、智能洞察**多平台热点的本质与趋势。

### 1.2 设计隐喻

**从"棱镜折射"到"深海/太空般的沉浸式探索"**

- **Prismatic Flow（保留精髓）**：流动性、深度感、微呼吸动效
- **Ethereal Insight（新增维度）**：克制、沉浸、空间感、内容为中心

### 1.3 设计关键词

| 旧版关键词 | 新版关键词 | 变化说明 |
|-----------|-----------|----------|
| 棱镜、炫光、渐变 | 沉浸、克制、呼吸 | 从"视觉冲击"到"信息效率" |
| 平台色主导 | 语义色主导 | 从"识别平台"到"理解趋势" |
| 数据堆砌 | AI 摘要优先 | 从"展示所有"到"智能筛选" |
| 标准列表 | 空间化卡片 | 从"等宽列表"到"杂志化布局" |

---

## 2. 核心设计原则

### 2.1 信息层级金字塔（优先级从高到低）

```
    ┌─────────────────────────┐
    │  1. AI 摘要 / 核心内容   │  ← 必须第一眼看到
    ├─────────────────────────┤
    │  2. 热度趋势（数值+曲线） │  ← 辅助决策
    ├─────────────────────────┤
    │  3. 平台/时间等元信息     │  ← 上下文信息
    ├─────────────────────────┤
    │  4. 详细数据（按需展开）  │  ← 隐藏在交互后
    └─────────────────────────┘
```

**实施规则：**

- 卡片必须在首屏显示"标题 + AI 摘要"
- 热度可视化仅保留最简形式（迷你曲线 + 数值）
- 平台色仅用于识别，不干扰阅读

### 2.2 色彩使用铁律

| 色彩类型 | 允许使用场景 | 禁止使用场景 |
|---------|------------|------------|
| **平台色** | Icon 小徽章、选中态细线、极细光带（≤2pt） | 卡片背景、大面积区域、趋势图 |
| **热度色** | 趋势曲线、热度数值、状态指示器 | 平台标识 |
| **中性色** | 全局背景、卡片基底、文字 | 强调元素 |

### 2.3 动效使用规范

```
Breathe（微呼吸） → 全局生命感       [强度: 0.5%缩放, 3s周期]
Flow（流动过渡）  → 状态切换         [时长: 0.3s, easeInOut]
Ripple（涟漪）    → 点击反馈         [仅用于交互瞬间]
Pulse（脉冲）     → 仅 Top 3 爆发项  [条件: 热度 > 500k]
```

**禁用场景：**

- 常规列表滚动时不添加额外动画
- 用户开启"减弱动态效果"时禁用所有非必要动效

---

## 3. 色彩系统重构

### 3.1 全局色彩架构

```
全局背景 (Neutral Base)
    ↓
    ├─ 卡片基底 (Container)
    │     ↓
    │     ├─ 内容文字 (Primary/Secondary Text)
    │     ├─ 平台微标识 (Platform Hint) ← 极小面积
    │     └─ 热度可视化 (Heat Spectrum) ← 数据驱动
    │
    └─ 浮层元素 (Floating Elements)
          └─ 导航 Dock / Modal
```

### 3.2 中性色基底（Neutral Palette）

#### 浅色模式

| 名称 | 色值 | 用途 |
|-----|------|------|
| Background Primary | `#FAFBFC` | 全局背景 |
| Background Secondary | `#F3F4F6` | 分组区域背景 |
| Container | `#FFFFFF` | 卡片基底 |
| Container Hover | `rgba(255, 255, 255, 0.95)` | 卡片悬浮态 |
| Border Subtle | `rgba(0, 0, 0, 0.06)` | 轻微分割线 |
| Text Primary | `#111827` | 主文字 |
| Text Secondary | `#6B7280` | 辅助文字 |
| Text Tertiary | `#9CA3AF` | 占位文字 |

#### 深色模式

| 名称 | 色值 | 用途 |
|-----|------|------|
| Background Primary | `#0A0E14` | 全局背景（宇宙深蓝黑） |
| Background Secondary | `#13171F` | 分组区域背景 |
| Container | `#1A1F2E` | 卡片基底 |
| Container Hover | `rgba(26, 31, 46, 0.95)` | 卡片悬浮态 |
| Border Subtle | `rgba(255, 255, 255, 0.08)` | 轻微分割线 |
| Text Primary | `#F9FAFB` | 主文字 |
| Text Secondary | `#D1D5DB` | 辅助文字 |
| Text Tertiary | `#9CA3AF` | 占位文字 |

### 3.3 平台识别色（Platform Hint Colors）

**设计原则：仅用于 Icon / 小徽章 / 选中态细线**

| 平台 | Icon 色值（单色） | 选中态渐变（极细，2pt） | 使用场景 |
|------|-----------------|----------------------|---------|
| 微博 | `#E74C3C` | `#E74C3C → #F39C12` | 16×16pt Icon, 选中下划线 |
| 小红书 | `#E91E63` | `#E91E63 → #EC407A` | 16×16pt Icon, 选中下划线 |
| Bilibili | `#00A1D6` | `#00A1D6 → #22D3D8` | 16×16pt Icon, 选中下划线 |
| 抖音 | `#000000` (浅) / `#FFFFFF` (深) | `#F472B6 → #A855F7` | 16×16pt Icon, 选中下划线 |
| X | `#1DA1F2` | `#1DA1F2 → #3B82F6` | 16×16pt Icon, 选中下划线 |
| 知乎 | `#0084FF` | `#0084FF → #8B5CF6` | 16×16pt Icon, 选中下划线 |

**实现规范：**

```swift
// ✅ 正确用法：仅用于 Icon
Image(platform.iconName)
    .foregroundStyle(platform.hintColor)
    .frame(width: 16, height: 16)

// ❌ 错误用法：大面积背景
.background(platform.hintColor) // 禁止
```

### 3.4 热度光谱（Heat Spectrum）

**用途：趋势曲线、热度数值、状态指示器**

| 热度区间 | 色值 | 文字描述 | 视觉效果 |
|---------|------|---------|---------|
| 0 - 10k | `#9CA3AF` | 冷寂 | 无特效 |
| 10k - 50k | `#60A5FA` | 微温 | 无特效 |
| 50k - 100k | `#34D399` | 温热 | 无特效 |
| 100k - 200k | `#FBBF24` | 升温 | 轻微发光 (blur: 2pt) |
| 200k - 500k | `#FB923C` | 火热 | 发光 (blur: 4pt) |
| 500k - 1M | `#F87171` | 炽热 | 脉冲动画 + 发光 |
| 1M+ | `#EF4444` | 爆发 | 强脉冲 + 粒子效果 |

**映射函数：**

```swift
func heatColor(for value: Int) -> Color {
    switch value {
    case 0..<10_000: return Color(hex: "#9CA3AF")
    case 10_000..<50_000: return Color(hex: "#60A5FA")
    case 50_000..<100_000: return Color(hex: "#34D399")
    case 100_000..<200_000: return Color(hex: "#FBBF24")
    case 200_000..<500_000: return Color(hex: "#FB923C")
    case 500_000..<1_000_000: return Color(hex: "#F87171")
    default: return Color(hex: "#EF4444")
    }
}

func heatEffectLevel(for value: Int) -> HeatEffect {
    switch value {
    case 0..<100_000: return .none
    case 100_000..<200_000: return .glow(radius: 2)
    case 200_000..<500_000: return .glow(radius: 4)
    case 500_000..<1_000_000: return .pulse
    default: return .burst // 粒子效果
    }
}
```

### 3.5 语义色（Semantic Colors）

| 语义 | 浅色模式 | 深色模式 | 用途 |
|-----|---------|---------|------|
| Success | `#10B981` | `#34D399` | 排名上升 |
| Warning | `#F59E0B` | `#FBBF24` | 注意提示 |
| Error | `#EF4444` | `#F87171` | 排名下降、错误 |
| Info | `#3B82F6` | `#60A5FA` | 新上榜、提示 |

### 3.6 动态氛围背景（可选，极轻微）

**设计原则：** 仅在全平台视图显示极淡的渐变氛围，饱和度 ≤ 5%，不干扰阅读。

```swift
// 全平台模式：彩虹光谱缓缓流动
MeshGradient(
    width: 3, height: 3,
    points: meshPoints,
    colors: [
        Color(hex: "#E74C3C").opacity(0.03),
        Color(hex: "#00A1D6").opacity(0.03),
        Color(hex: "#E91E63").opacity(0.03),
        // ...
    ]
)

// 单平台模式：该平台色的极淡氛围
LinearGradient(
    colors: [
        platform.hintColor.opacity(0.02),
        Color.clear
    ],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

---

## 4. 字体系统

保持原设计系统的字体定义，增强层级对比。

### 4.1 字体族

| 用途 | 字体 | 说明 |
|------|------|------|
| 标题 | SF Pro Rounded | 更柔和、现代 |
| 正文 | SF Pro | 标准正文 |
| 数据 | SF Mono | 热度数值、排名 |

### 4.2 字体层级（新增 AI 摘要规范）

| 层级 | 字号 | 字重 | 行高 | 用途 |
|------|------|------|------|------|
| **Hero Title** | 28pt | Bold | 1.2 | Top 3 焦点卡片标题 |
| **Hero Summary** | 17pt | Regular | 1.4 | Top 3 焦点卡片摘要 |
| **Card Title** | 17pt | Semibold | 1.3 | 标准卡片标题 |
| **Card Summary** | 15pt | Regular | 1.4 | 标准卡片 AI 摘要（2行截断） |
| **Meta Info** | 13pt | Regular | 1.2 | 平台、时间、热度文字 |
| **Caption** | 12pt | Regular | 1.2 | 辅助说明 |
| **Data Number** | 15pt | Medium (SF Mono) | 1.0 | 热度数值 |

**截断规则：**

```swift
// 标题：单行截断
Text(topic.title)
    .font(.system(size: 17, weight: .semibold))
    .lineLimit(1)
    .truncationMode(.tail)

// AI 摘要：2 行截断 + 渐变淡出
Text(topic.summary ?? "")
    .font(.system(size: 15))
    .lineLimit(2)
    .truncationMode(.tail)
    .foregroundStyle(.secondary)
```

---

## 5. 间距与圆角

### 5.1 间距系统（8pt Grid）

```swift
enum Spacing {
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 48
}
```

### 5.2 圆角系统

| 组件类型 | 圆角半径 | 说明 |
|---------|---------|------|
| Hero Card | 24pt | 焦点卡片 |
| Standard Card | 16pt | 标准卡片 |
| Floating Dock | 30pt | 胶囊形导航 |
| Button | 12pt | 按钮 |
| Input Field | 10pt | 输入框 |
| Platform Icon | 6pt | 小图标背景 |

**统一使用连续曲线：**

```swift
.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
```

---

## 6. 材质与深度

### 6.1 材质层级

| 材质 | SwiftUI 实现 | 用途 |
|------|-------------|------|
| Ultra Thin | `.ultraThinMaterial` | Floating Dock |
| Thin | `.thinMaterial` | Platform Ribbon |
| Regular | `.regularMaterial` | 标准卡片背景（可选） |
| Thick | `.thickMaterial` | Modal 背景 |

**卡片材质策略：**

```swift
// 优先使用纯色 Container，仅在需要透视时使用 Material
ZStack {
    // 方案 A：纯色（推荐，性能更好）
    RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(Color.container)

    // 方案 B：玻璃效果（特殊场景）
    RoundedRectangle(cornerRadius: 16, style: .continuous)
        .fill(.regularMaterial)
}
```

### 6.2 阴影层级（统一使用柔和阴影）

| 层级 | 参数 | 用途 |
|------|------|------|
| **Subtle** | `color: .black.opacity(0.04), radius: 2, y: 1` | 轻微悬浮感 |
| **Card** | `color: .black.opacity(0.06), radius: 8, y: 4` | 标准卡片 |
| **Elevated** | `color: .black.opacity(0.10), radius: 16, y: 8` | 悬浮态、Modal |
| **Glow** | `color: heatColor.opacity(0.3), radius: 12, y: 0` | 高热度发光 |

**深色模式调整：**

```swift
// 深色模式使用白色阴影 + 更低透明度
.shadow(
    color: colorScheme == .dark
        ? .white.opacity(0.03)
        : .black.opacity(0.06),
    radius: 8,
    y: 4
)
```

---

## 7. 核心组件设计

### 7.1 导航系统 ~~Floating Dynamic Dock~~ → 官方 TabView

> **⚠️ 设计变更（2026-01-24）**
>
> - **原设计：** Floating Dynamic Dock（自定义悬浮导航）
> - **最终实现：** 使用官方 SwiftUI TabView
> - **原因：** 系统原生体验更稳定、触觉反馈更自然、开发成本低
> - **状态：** 以下 7.1 章节内容仅作设计存档，实际使用标准 TabView

<details>
<summary>原 Floating Dock 设计规范（已弃用，点击展开）</summary>

**设计目标：** 释放屏幕空间，让内容"通透"到底部。

#### 7.1.1 视觉规范

```
┌─────────────────────────────────────┐
│                                     │
│         [Content Area]              │
│                                     │
│                                     │
│              ╭────────╮             │  ← 距底部 20pt
│              │ 🏠📊🔍 │             │  ← 高度 56pt
│              │    ●   │             │  ← 选中指示器
│              ╰────────╯             │  ← 圆角 28pt (胶囊)
│                                     │
└─────────────────────────────────────┘
        Safe Area Bottom
```

| 属性 | 值 | 说明 |
|------|-----|------|
| 形状 | Capsule | 完全圆角的胶囊 |
| 宽度 | 动态（内容宽度 + 48pt padding） | 最大 280pt |
| 高度 | 56pt | 固定 |
| 距底部 | 20pt（安全区内） | 适配 Home Indicator |
| 背景 | `.ultraThinMaterial` + 边框 | 磨砂玻璃 |
| 边框 | `1pt, .white.opacity(0.1)` | 轻微高光 |
| 阴影 | Elevated | 强悬浮感 |

#### 7.1.2 图标规范

| Tab | 图标（未选中） | 图标（选中） | 尺寸 |
|-----|--------------|-------------|------|
| Feed | `flame` | `flame.fill` | 24×24pt |
| Compare | `chart.bar.xaxis` | `chart.bar.xaxis.ascending` | 24×24pt |
| Search | `magnifyingglass` | `magnifyingglass.circle.fill` | 24×24pt |

**颜色：**

- 未选中：`.secondary`（灰色）
- 选中：`.primary`（黑/白）

#### 7.1.3 选中指示器

```
位置：图标底部中心
形状：圆形
尺寸：6pt 直径
颜色：.primary
动画：matchedGeometryEffect + spring(0.5, 0.7)
```

```swift
// 实现示例
Circle()
    .fill(.primary)
    .frame(width: 6, height: 6)
    .offset(y: 20)
    .matchedGeometryEffect(id: "indicator", in: namespace)
    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedTab)
```

#### 7.1.4 动态行为（自动隐藏）

| 状态 | 触发条件 | 视觉变化 |
|------|---------|---------|
| **显示** | 滚动停止 > 0.5s | opacity: 1, offset: 0 |
| **隐藏** | 向下滚动且速度 > 50pt/s | opacity: 0, offset: +20pt |
| **强制显示** | 用户上滑或触底 | 立即显示 |

```swift
// 实现伪代码
.offset(y: isHidden ? 20 : 0)
.opacity(isHidden ? 0 : 1)
.animation(.easeOut(duration: 0.2), value: isHidden)
```

</details>

---

### 7.2 平台选择器：Fluid Ribbon

**设计目标：** 可滑动、流体化、高效切换。

#### 7.2.1 视觉规范

```
╭──────────────────────────────────────────╮
│  ◉ 全部  │  微博  │  小红书  │  B站  →  │
│           ╰══════╯                        │
╰──────────────────────────────────────────╯
            ↑
      渐变下划线（2pt 高，平台色渐变）
```

| 属性 | 值 | 说明 |
|------|-----|------|
| 高度 | 48pt | 固定 |
| 背景 | `.thinMaterial` 或 透明 | 轻微模糊 |
| 项间距 | 24pt | 水平间距 |
| 内边距 | 水平 16pt | 左右留白 |
| 文字（未选中） | 15pt, Medium, .secondary | 灰色 |
| 文字（选中） | 15pt, Semibold, .primary | 黑/白 |

#### 7.2.2 选中指示器

```swift
// 渐变下划线
Capsule()
    .fill(
        LinearGradient(
            colors: selectedPlatform.gradientColors,
            startPoint: .leading,
            endPoint: .trailing
        )
    )
    .frame(height: 2)
    .offset(y: 4) // 文字下方 4pt
    .matchedGeometryEffect(id: "selector", in: namespace)
    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedPlatform)
```

#### 7.2.3 手势交互

**支持两种切换方式：**

1. **点击切换**（主要）
   - 点击项 → 切换平台
   - 触觉反馈：`.impact(.light)`

2. **页面滑动切换**（辅助）
   - 在内容区域左右滑动（Pan Gesture）
   - 达到阈值（屏幕宽度 30%）→ 切换到相邻平台
   - 触觉反馈：`.impact(.medium)`

```swift
// 滑动手势伪代码
.gesture(
    DragGesture()
        .onEnded { value in
            if value.translation.width < -100 {
                // 切换到下一个平台
                switchToNext()
            } else if value.translation.width > 100 {
                // 切换到上一个平台
                switchToPrevious()
            }
        }
)
```

---

### 7.3 卡片系统：Hero Card + Standard Card

#### 7.3.1 Hero Card（焦点卡片，用于 Rank 1-3）

**视觉规范：**

```
╭──────────────────────────────────────────╮
│  [背景：渐变氛围 or 图片蒙层]             │
│                                          │
│  1                                    🔥 │ ← 排名 + 热度图标
│                                          │
│  这是一个超级热门话题的标题               │ ← 28pt Bold
│  ─────────────────────────────          │
│                                          │
│  AI 生成的核心摘要，简明扼要地说明        │ ← 17pt Regular
│  这个话题的关键信息和背景...              │    (最多 3 行)
│                                          │
│  [迷你趋势曲线]          1.2M  ↑ 5      │ ← 热度值 + 排名变化
│                                          │
│  微博 · 2小时前                          │ ← 元信息
╰──────────────────────────────────────────╯
```

| 属性 | 值 | 说明 |
|------|-----|------|
| 高度 | 最小 240pt | 自适应内容 |
| 圆角 | 24pt (continuous) | 大圆角 |
| 内边距 | 24pt | 内容留白 |
| 背景 | 方案 A：热度渐变氛围  方案 B：纯色 + 轻微纹理 | 根据热度值映射 |
| 阴影 | Elevated | 强调焦点 |
| 排名数字 | 48pt, Bold, .primary.opacity(0.2) | 水印式大号排名 |

**背景氛围规则：**

```swift
// 根据热度值生成背景
func heroBackground(heat: Int) -> some View {
    let color = heatColor(for: heat)

    return LinearGradient(
        colors: [
            color.opacity(0.15),
            color.opacity(0.05),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}
```

**内容布局：**

```swift
VStack(alignment: .leading, spacing: 16) {
    // 顶部：排名 + 热度图标
    HStack {
        Text("\(rank)")
            .font(.system(size: 48, weight: .bold))
            .foregroundStyle(.primary.opacity(0.2))

        Spacer()

        if heat > 500_000 {
            Image(systemName: "flame.fill")
                .foregroundStyle(heatColor(for: heat))
        }
    }

    // 标题
    Text(title)
        .font(.system(size: 28, weight: .bold, design: .rounded))
        .lineLimit(2)

    // AI 摘要
    Text(summary)
        .font(.system(size: 17))
        .foregroundStyle(.secondary)
        .lineLimit(3)

    Spacer()

    // 底部：趋势 + 热度
    HStack {
        MiniTrendLine(data: heatHistory)
            .frame(width: 80, height: 32)

        Spacer()

        HStack(spacing: 8) {
            Text(formatHeat(heat))
                .font(.system(size: 15, weight: .medium, design: .monospaced))

            RankChangeIndicator(change: rankChange)
        }
    }

    // 元信息
    HStack(spacing: 8) {
        PlatformIcon(platform: platform)
        Text("·")
        Text(relativeTime)
    }
    .font(.system(size: 13))
    .foregroundStyle(.tertiary)
}
.padding(24)
```

#### 7.3.2 Standard Card（标准卡片，用于 Rank 4+）

**视觉规范：**

```
╭──────────────────────────────────────────╮
│  5    这是一个热搜话题标题            🔥 │ ← 排名 + 标题 + Icon
│                                          │
│       AI 核心摘要：简明扼要地说明        │ ← 15pt, 2行截断
│       这个话题的关键信息...              │
│                                          │
│       微博 · 1小时前 · 850k  ↑ 2    ╱╲  │ ← 元信息 + 迷你曲线
╰──────────────────────────────────────────╯
         ↑                           ↑
    16×16pt Icon              32×24pt 趋势线
```

| 属性 | 值 | 说明 |
|------|-----|------|
| 高度 | 最小 100pt | 自适应内容 |
| 圆角 | 16pt (continuous) | 标准圆角 |
| 内边距 | 16pt | 内容留白 |
| 背景 | `.container` | 纯色卡片 |
| 阴影 | Card | 标准阴影 |
| 间距 | 卡片间 12pt | 列表间距 |

**内容布局：**

```swift
VStack(alignment: .leading, spacing: 12) {
    // 第一行：排名 + 标题 + 热度图标
    HStack(alignment: .top, spacing: 12) {
        // 排名
        Text("\(rank)")
            .font(.system(size: 20, weight: .bold))
            .foregroundStyle(.tertiary)
            .frame(width: 32, alignment: .leading)

        // 标题
        Text(title)
            .font(.system(size: 17, weight: .semibold))
            .lineLimit(1)

        Spacer(minLength: 8)

        // 热度图标（仅高热度显示）
        if heat > 200_000 {
            Image(systemName: "flame.fill")
                .font(.system(size: 14))
                .foregroundStyle(heatColor(for: heat))
        }
    }

    // 第二行：AI 摘要
    if let summary = summary {
        Text(summary)
            .font(.system(size: 15))
            .foregroundStyle(.secondary)
            .lineLimit(2)
            .padding(.leading, 44) // 对齐标题
    }

    // 第三行：元信息 + 趋势
    HStack(spacing: 8) {
        // 平台 Icon
        PlatformIcon(platform: platform)

        Text("·")
            .foregroundStyle(.tertiary)

        // 时间
        Text(relativeTime)
            .font(.system(size: 13))
            .foregroundStyle(.tertiary)

        Text("·")
            .foregroundStyle(.tertiary)

        // 热度值
        Text(formatHeat(heat))
            .font(.system(size: 13, design: .monospaced))
            .foregroundStyle(.secondary)

        // 排名变化
        RankChangeIndicator(change: rankChange)

        Spacer()

        // 迷你趋势线
        MiniTrendLine(data: heatHistory)
            .frame(width: 32, height: 24)
    }
    .padding(.leading, 44) // 对齐标题
}
.padding(16)
.background(.container)
.clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
.shadow(color: .black.opacity(0.06), radius: 8, y: 4)
```

#### 7.3.3 Platform Icon（平台微标识）

**设计规范：**

| 属性 | 值 | 说明 |
|------|-----|------|
| 尺寸 | 16×16pt | 小图标 |
| 背景 | 平台色 | 单色，非渐变 |
| 圆角 | 4pt | 轻微圆角 |
| 图标 | SF Symbol 或自定义 | 白色，10pt |

```swift
struct PlatformIcon: View {
    let platform: Platform

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(platform.hintColor)

            Image(systemName: platform.iconName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white)
        }
        .frame(width: 16, height: 16)
    }
}
```

---

### 7.4 趋势可视化：Mini Trend Line

**设计目标：** 极简、不干扰阅读、仅展示起伏形态。

#### 7.4.1 视觉规范

```
尺寸：
  - Hero Card：80×32pt
  - Standard Card：32×24pt

样式：
  - 线宽：1.5pt
  - 颜色：Heat Spectrum（根据当前热度）
  - 填充：无（仅线条）
  - 坐标轴：无
  - 网格：无
  - 插值：catmullRom（平滑曲线）
```

#### 7.4.2 实现规范

```swift
struct MiniTrendLine: View {
    let data: [HeatDataPoint] // 最近 6-12 个点
    let currentHeat: Int

    var body: some View {
        Chart(data) { point in
            LineMark(
                x: .value("Time", point.timestamp),
                y: .value("Heat", point.heatValue)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(heatColor(for: currentHeat))
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartXScale(domain: .automatic)
        .chartYScale(domain: .automatic)
    }
}
```

**数据要求：**

- 最少 3 个点（否则不显示）
- 最多 12 个点（超过则抽样）
- 时间跨度：最近 24 小时

---

### 7.5 排名变化指示器

**视觉规范：**

| 状态 | 图标 | 颜色 | 文字 | 尺寸 |
|------|------|------|------|------|
| 上升 | `arrow.up` | Success Green | `+5` | 12pt Icon + 13pt Text |
| 下降 | `arrow.down` | Error Red | `-3` | 12pt Icon + 13pt Text |
| 新上榜 | `star.fill` | Info Blue | `NEW` | 12pt Icon + 11pt Text |
| 持平 | (无) | (无) | (无) | (无) |

```swift
struct RankChangeIndicator: View {
    let change: RankChange

    var body: some View {
        HStack(spacing: 2) {
            switch change {
            case .up(let value):
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                Text("+\(value)")
                    .font(.system(size: 13, weight: .medium))
            case .down(let value):
                Image(systemName: "arrow.down")
                    .font(.system(size: 12, weight: .semibold))
                Text("-\(value)")
                    .font(.system(size: 13, weight: .medium))
            case .new:
                Image(systemName: "star.fill")
                    .font(.system(size: 11))
                Text("NEW")
                    .font(.system(size: 11, weight: .bold))
            case .same:
                EmptyView()
            }
        }
        .foregroundStyle(change.color)
    }
}

enum RankChange {
    case up(Int)
    case down(Int)
    case new
    case same

    var color: Color {
        switch self {
        case .up: return .green
        case .down: return .red
        case .new: return .blue
        case .same: return .secondary
        }
    }
}
```

---

### 7.6 空状态与加载状态

#### 7.6.1 空状态

```
┌─────────────────────────────┐
│                             │
│         [Lottie 动画]        │ ← 96×96pt
│                             │
│      暂无热点数据            │ ← 17pt, Secondary
│                             │
│   下拉刷新以获取最新内容      │ ← 15pt, Tertiary
│                             │
└─────────────────────────────┘
```

| 属性 | 值 |
|------|-----|
| 图标尺寸 | 96×96pt |
| 主文字 | 17pt, Medium, .secondary |
| 副文字 | 15pt, Regular, .tertiary |
| 间距 | 16pt |

#### 7.6.2 加载状态（骨架屏）

**设计原则：** 模拟真实卡片形态，使用渐变闪烁（非灰色块）。

```swift
struct SkeletonCard: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // 排名占位
                RoundedRectangle(cornerRadius: 4)
                    .fill(.tertiary.opacity(0.3))
                    .frame(width: 32, height: 20)

                // 标题占位
                RoundedRectangle(cornerRadius: 4)
                    .fill(.tertiary.opacity(0.3))
                    .frame(height: 20)
            }

            // 摘要占位
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.tertiary.opacity(0.2))
                    .frame(height: 16)

                RoundedRectangle(cornerRadius: 4)
                    .fill(.tertiary.opacity(0.2))
                    .frame(width: 200, height: 16)
            }
            .padding(.leading, 44)
        }
        .padding(16)
        .background(.container)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            // 闪烁渐变
            LinearGradient(
                colors: [
                    .clear,
                    .white.opacity(0.3),
                    .clear
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .offset(x: isAnimating ? 300 : -300)
            .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: isAnimating)
        )
        .onAppear {
            isAnimating = true
        }
    }
}
```

---

## 8. 布局系统

### 8.1 Feed 页面布局（单列 + 焦点区）

```
┌─────────────────────────────────────┐
│ [Fluid Ribbon - 平台选择器]          │ ← 48pt 高
├─────────────────────────────────────┤
│                                     │
│ ╭─────── Hero Card (Rank 1) ─────╮ │ ← 240pt 高
│ │                                 │ │
│ ╰─────────────────────────────────╯ │
│                                     │
│ ╭─────── Hero Card (Rank 2) ─────╮ │
│ │                                 │ │
│ ╰─────────────────────────────────╯ │
│                                     │
│ ╭─── Standard Card (Rank 4) ───╮   │ ← 100pt 高
│ ╰───────────────────────────────╯   │
│                                     │
│ ╭─── Standard Card (Rank 5) ───╮   │
│ ╰───────────────────────────────╯   │
│                                     │
│             ...                     │
│                                     │
└─────────────────────────────────────┘
```

**布局参数：**

| 元素 | 间距/尺寸 |
|------|----------|
| 顶部 Ribbon | 固定顶部，48pt 高 |
| 内容区内边距 | 左右 16pt |
| Hero Card 间距 | 16pt |
| Standard Card 间距 | 12pt |
| Hero → Standard 转换点 | Rank 4 开始 |
| 列表底部留白 | TabView 自动处理（系统原生） |

### 8.2 iPad / Mac 布局（双列 / 三列）

**iPad（宽度 768pt - 1024pt）：**

```
┌───────────────┬───────────────┐
│ Hero Card (1) │ Hero Card (2) │
├───────────────┼───────────────┤
│ Card (4)      │ Card (5)      │
│ Card (6)      │ Card (7)      │
│ ...           │ ...           │
└───────────────┴───────────────┘
```

**Mac（宽度 > 1024pt）：**

```
┌─────────┬─────────┬─────────┐
│ Sidebar │ Card(1) │ Card(2) │
│         ├─────────┼─────────┤
│ - 全部   │ Card(3) │ Card(4) │
│ - 微博   │ ...     │ ...     │
│ - 小红书 │         │         │
│         │         │         │
└─────────┴─────────┴─────────┘
```

---

## 9. 交互与动效

### 9.1 卡片交互

#### 9.1.1 点击交互

**视觉反馈：**

```swift
@State private var isPressed = false

var body: some View {
    CardContent()
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeOut(duration: 0.1), value: isPressed)
        .onTapGesture {
            // 触觉反馈
            UIImpactFeedbackGenerator(style: .light).impactOccurred()

            // 导航到详情
            navigateToDetail()
        }
        .onLongPressGesture(minimumDuration: 0.01) {
            // 长按开始
        } onPressingChanged: { pressing in
            isPressed = pressing
        }
}
```

#### 9.1.2 滑动操作（仅 iPhone）

**左滑 → 屏蔽话题：**

```
┌──────────────────────────────┐
│ 卡片内容                 [🚫] │ ← 右侧出现红色删除按钮
└──────────────────────────────┘
```

**右滑 → 收藏/稍后读：**

```
┌──────────────────────────────┐
│ [⭐] 卡片内容                 │ ← 左侧出现蓝色收藏按钮
└──────────────────────────────┘
```

**实现：**

```swift
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    Button(role: .destructive) {
        blockTopic()
    } label: {
        Label("屏蔽", systemImage: "eye.slash")
    }
}
.swipeActions(edge: .leading, allowsFullSwipe: false) {
    Button {
        favoriteTopic()
    } label: {
        Label("收藏", systemImage: "star.fill")
    }
    .tint(.blue)
}
```

### 9.2 下拉刷新

**视觉效果：**

1. 下拉距离 0-60pt：顶部出现平台色光晕，渐变增强
2. 释放刷新：光晕转为旋转渐变环
3. 刷新完成：光晕爆散成粒子，内容淡入

```swift
// 使用系统 refreshable modifier
.refreshable {
    await refreshData()
}
```

**触觉反馈：**

- 达到刷新阈值：`.impact(.medium)`
- 刷新完成：`.notification(.success)`

### 9.3 详情页转场

**使用 matchedGeometryEffect 实现卡片展开动画：**

```swift
@Namespace private var namespace

// 列表卡片
CardView()
    .matchedGeometryEffect(id: topic.id, in: namespace)
    .onTapGesture {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            selectedTopic = topic
        }
    }

// 详情页
if let selected = selectedTopic {
    DetailView(topic: selected)
        .matchedGeometryEffect(id: selected.id, in: namespace)
        .transition(.opacity)
}
```

### 9.4 动效时长表

| 交互 | 时长 | 曲线 | 触觉反馈 |
|------|------|------|---------|
| 卡片按下 | 0.1s | easeOut | `.impact(.light)` |
| Tab 切换 | 0.3s | easeInOut | `.impact(.light)` |
| 平台切换 | 0.4s | spring(0.4, 0.8) | `.impact(.medium)` |
| 详情展开 | 0.4s | spring(0.4, 0.8) | `.impact(.medium)` |
| 刷新完成 | 0.3s | easeOut | `.notification(.success)` |
| Dock 隐藏 | 0.2s | easeOut | (无) |

### 9.5 微动效（Micro-interactions）

#### 9.5.1 卡片呼吸（仅 Hero Card）

```swift
@State private var breathingScale: CGFloat = 1.0

HeroCard()
    .scaleEffect(breathingScale)
    .onAppear {
        withAnimation(
            .easeInOut(duration: 3.0)
            .repeatForever(autoreverses: true)
        ) {
            breathingScale = 1.005
        }
    }
```

#### 9.5.2 热度脉冲（仅 500k+ 热度）

```swift
@State private var pulseOpacity: Double = 1.0

Circle()
    .stroke(heatColor, lineWidth: 2)
    .frame(width: 20, height: 20)
    .opacity(pulseOpacity)
    .onAppear {
        withAnimation(
            .easeOut(duration: 1.5)
            .repeatForever(autoreverses: false)
        ) {
            pulseOpacity = 0.0
        }
    }
```

---

## 10. 响应式设计

### 10.1 断点定义

| 设备 | 宽度范围 | 布局 | 导航 |
|------|---------|------|------|
| iPhone | < 428pt | 单列 | 底部 TabView |
| iPhone 横屏 | 428pt - 768pt | 双列 | 底部 TabView |
| iPad | 768pt - 1024pt | 双列 | 底部 TabView |
| Mac | > 1024pt | 三列 | 顶部 Tab / Sidebar |

### 10.2 自适应规则

```swift
@Environment(\.horizontalSizeClass) var sizeClass

var columns: Int {
    switch sizeClass {
    case .compact:
        return 1 // iPhone 竖屏
    case .regular:
        return UIDevice.current.userInterfaceIdiom == .pad ? 2 : 3
    default:
        return 1
    }
}

LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: columns)) {
    // 卡片内容
}
```

---

## 11. 深色模式

### 11.1 自动适配

所有颜色使用语义化命名，自动适配深色模式：

```swift
// ✅ 正确
.foregroundStyle(.primary)
.background(.container)

// ❌ 错误
.foregroundStyle(.black)
.background(.white)
```

### 11.2 深色模式特殊调整

| 元素 | 调整 |
|------|------|
| 阴影 | 使用白色阴影，透明度减半 |
| 平台色 | 饱和度 -10% |
| 热度发光 | 强度 +20% |
| 背景氛围 | 透明度减半 |

```swift
@Environment(\.colorScheme) var colorScheme

var shadowColor: Color {
    colorScheme == .dark
        ? .white.opacity(0.03)
        : .black.opacity(0.06)
}
```

---

## 12. 无障碍设计

### 12.1 VoiceOver 标签

```swift
// 卡片
.accessibilityLabel("\(platform.name)，\(title)，热度 \(formatHeat(heat))，排名 \(rank)")

// 趋势图
.accessibilityLabel("热度趋势图，当前热度 \(currentHeat)，\(trendDescription)")

// 平台选择器
.accessibilityHint("双击切换到 \(platform.name)")
```

### 12.2 动态字体支持

```swift
// 标题：限制最大缩放
Text(title)
    .font(.system(size: 17, weight: .semibold))
    .dynamicTypeSize(...DynamicTypeSize.xxxLarge)

// 正文：完全支持
Text(summary)
    .font(.body)
```

### 12.3 减弱动态效果

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .spring(response: 0.4, dampingFraction: 0.8)
}
```

---

## 13. 实现指南

### 13.1 DesignSystem.swift 重构清单

#### 13.1.1 需要新增的定义

```swift
// 1. 中性色基底
extension Color {
    static let backgroundPrimary = Color("BackgroundPrimary")
    static let backgroundSecondary = Color("BackgroundSecondary")
    static let container = Color("Container")
    static let containerHover = Color("ContainerHover")
    static let borderSubtle = Color("BorderSubtle")
}

// 2. 平台 Hint 色（单色，仅用于 Icon）
extension Platform {
    var hintColor: Color {
        switch self {
        case .weibo: return Color(hex: "#E74C3C")
        case .xiaohongshu: return Color(hex: "#E91E63")
        case .bilibili: return Color(hex: "#00A1D6")
        case .douyin: return Color(hex: "#000000") // 需要深色模式适配
        case .x: return Color(hex: "#1DA1F2")
        case .zhihu: return Color(hex: "#0084FF")
        }
    }

    // 选中态渐变（仅用于 2pt 下划线）
    var selectionGradient: LinearGradient {
        // 实现略
    }
}

// 3. 热度光谱函数
func heatColor(for value: Int) -> Color {
    // 见 3.4 节
}

func heatEffectLevel(for value: Int) -> HeatEffect {
    // 见 3.4 节
}

enum HeatEffect {
    case none
    case glow(radius: CGFloat)
    case pulse
    case burst
}

// 4. 阴影预设
extension View {
    func cardShadow(colorScheme: ColorScheme) -> some View {
        self.shadow(
            color: colorScheme == .dark ? .white.opacity(0.03) : .black.opacity(0.06),
            radius: 8,
            y: 4
        )
    }

    func elevatedShadow(colorScheme: ColorScheme) -> some View {
        self.shadow(
            color: colorScheme == .dark ? .white.opacity(0.05) : .black.opacity(0.10),
            radius: 16,
            y: 8
        )
    }
}
```

#### 13.1.2 需要废弃的定义

```swift
// ❌ 移除：Legacy Platform Colors（大面积使用）
// 保留 hintColor 即可

// ❌ 移除：PlatformGradient 用于背景
// 仅保留用于选中态下划线
```

### 13.2 新增组件文件清单

```
TrendLens/UIComponents/
├── Navigation/
│   └── FluidRibbon.swift               # 平台选择器（TopBar）
├── Cards/
│   ├── HeroCard.swift                  # 焦点卡片
│   ├── StandardCard.swift              # 标准卡片
│   ├── PlatformIcon.swift              # 平台微标识
│   └── RankChangeIndicator.swift       # 排名变化指示器
├── Charts/
│   ├── MiniTrendLine.swift             # 迷你趋势线
│   └── FullTrendChart.swift            # 详情页完整图表
├── States/
│   ├── EmptyStateView.swift            # 空状态
│   └── SkeletonCard.swift              # 骨架屏
└── Modifiers/
    ├── CardStyle.swift                 # 卡片样式修饰器
    └── HeatEffectModifier.swift        # 热度特效修饰器
```

### 13.3 实现优先级

**Phase 1（核心基础）：**

1. DesignSystem.swift 重构（色彩 + 阴影 + 间距）
2. PlatformIcon.swift
3. StandardCard.swift（不含 AI 摘要，先用标题）

**Phase 2（进阶组件）：**
4. FluidRibbon.swift
5. MiniTrendLine.swift
6. RankChangeIndicator.swift

**Phase 3（高级特性）：**
7. HeroCard.swift
8. 卡片滑动操作
9. 详情页转场动画
10. 热度特效（发光、脉冲）

**Phase 4（优化）：**
11. 骨架屏
12. 空状态
13. 响应式布局（iPad/Mac）

### 13.4 Mock 数据扩展

```swift
extension TrendTopicEntity {
    // 新增字段
    var summary: String? // AI 摘要
    var mediaUrl: URL? // 媒体图（可选）
    var heatHistory: [HeatDataPoint] // 热度历史（用于趋势图）
}

// Mock 数据示例
static let mockTopics: [TrendTopicEntity] = [
    TrendTopicEntity(
        id: UUID(),
        title: "华为 Mate 70 发布会官宣",
        summary: "华为官方宣布将于本月 26 日举行 Mate 70 系列新品发布会，预计搭载麒麟 9100 芯片。",
        platform: .weibo,
        rank: 1,
        heatValue: 1_250_000,
        rankChange: .up(3),
        fetchedAt: Date(),
        heatHistory: mockHeatHistory
    ),
    // ...
]
```

### 13.5 代码检查清单

**在提交前确认：**

- [ ] 所有平台色仅用于 Icon（16×16pt）或选中态细线（≤2pt）
- [ ] 趋势图颜色使用 `heatColor(for:)` 函数
- [ ] 卡片背景使用 `.container`（非平台色）
- [ ] 阴影使用预设函数，支持深色模式
- [ ] 所有动画尊重 `accessibilityReduceMotion`
- [ ] 文字使用语义化颜色（`.primary`, `.secondary`）
- [ ] VoiceOver 标签完整
- [ ] 动态字体支持（关键区域限制最大值）

---

## 附录 A：与旧版设计系统的对照表

| 维度 | 旧版 (Prismatic Flow v2.0) | 新版 (Ethereal Insight v3.0) |
|------|--------------------------|----------------------------|
| **核心隐喻** | 棱镜折射光谱 | 深海/太空沉浸感 |
| **色彩主导** | 平台渐变色带 | 中性基底 + 热度光谱 |
| **平台色用途** | 卡片光带 + 背景氛围 | 仅 Icon + 选中态细线 |
| **卡片形态** | Morphic Card（非对称圆角） | Hero + Standard（标准圆角） |
| **信息重心** | 热度可视化（进度条 + 曲线） | AI 摘要 + 迷你趋势线 |
| **导航** | 标准 TabBar | 官方 TabView（系统原生） |
| **平台选择** | Chip 组（点击） | Fluid Ribbon（滑动 + 点击） |
| **动效强度** | Pulse/Ripple/Flow/Breathe 全用 | 仅 Breathe + 条件 Pulse |

---

## 附录 B：术语表

| 术语 | 定义 |
|------|------|
| **Ethereal Insight** | 新设计理念：沉浸式、克制、内容为中心 |
| **Hero Card** | 焦点卡片，用于 Rank 1-3，包含 AI 摘要 |
| **Standard Card** | 标准卡片，用于 Rank 4+，紧凑布局 |
| **Platform Hint** | 平台识别色，仅用于小面积点缀 |
| **Heat Spectrum** | 热度光谱，连续映射热度值到颜色 |
| **Fluid Ribbon** | 流体化平台选择器，支持滑动切换 |
| **Mini Trend Line** | 迷你趋势曲线，仅显示起伏形态 |

---

## 附录 C：设计决策记录（ADR）

### ADR-001：为什么抛弃 Morphic Card 的非对称圆角？

**决策：** 使用标准圆角（16pt/24pt continuous）替代非对称圆角。

**理由：**

1. 非对称圆角虽有设计感，但在快速滚动时会产生视觉噪音
2. 标准圆角更符合 iOS 26 Liquid Glass 原生感
3. 简化实现，提升性能

### ADR-002：为什么 AI 摘要只显示 2 行？

**决策：** 标准卡片摘要限制 2 行，Hero Card 限制 3 行。

**理由：**

1. 快速扫描效率：用户平均停留 0.3-0.5 秒/卡片
2. 避免信息过载：摘要是辅助理解，非全文
3. 详细内容在详情页展示

### ADR-003：为什么移除热度进度条？

**决策：** 仅保留热度数值 + 迷你趋势线。

**理由：**

1. 进度条需要"最大值"参照，但热搜无明确上限
2. 横向对比困难：不同平台热度量级差异大
3. 数值 + 趋势线更直观、占用空间更小

### ADR-004：为什么弃用 FloatingDock 改用官方 TabView？

**决策：** 从自定义 FloatingDock 改为使用官方 SwiftUI TabView。

**理由：**

1. **系统原生稳定性**：官方控件经过充分测试，生产级别的稳定性
2. **触觉反馈与动画**：系统自动处理，与其他 iOS 应用一致
3. **开发成本**：无需自定义手势、自动隐藏逻辑、响应式适配
4. **可访问性**：VoiceOver 原生支持，无需额外实现
5. **未来维护**：iOS 26+ 更新时自动受益，无兼容性压力
6. **深色模式和动态字体**：自动适配，无需手动处理

**折衷：** 失去完全自定义的设计风格，但获得了更好的稳定性和可维护性

---

**文档结束**

此文档为 TrendLens v3.0 设计系统的完整规范，所有实现必须严格遵循。如有疑问或需要调整，请先在团队内讨论并更新本文档。
