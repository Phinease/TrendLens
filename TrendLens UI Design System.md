# TrendLens UI Design System

> **文档定位：** UI 视觉设计规范与交互模式白皮书（权威参考）
> **技术实现：** 见 [DesignSystem.swift](TrendLens/UIComponents/DesignSystem.swift)
>
> **最后更新：** 2026-01-21
> **设计版本：** v2.0 - Prismatic Flow

---

## 1. 设计理念：Prismatic Flow（棱镜流）

### 1.1 核心概念

**从"透过镜头看热点"升级为"穿越棱镜感受信息能量场"**

TrendLens 像一个多面棱镜——不同平台的热点如同光线穿过棱镜，折射出独特的色彩与能量。我们不再只是"展示数据"，而是让用户**感受**热点的温度、脉动与生命力。

**核心关键词：** 棱镜、渐变、脉动、深度、流动

### 1.2 三大设计支柱

| 支柱 | 表达方式 | 用户感知 |
|------|----------|----------|
| **色彩** | 平台渐变色带 + 热度光谱 | 丰富而不花哨 |
| **形态** | 有机呼吸形态 + 3D 深度 | 有生命力 |
| **动效** | 脉冲/涟漪/流体动画 | 流畅自然 |

### 1.3 设计目标

- **信息传达**：热点的温度、趋势一目了然
- **情感连接**：界面有呼吸感、有生命力
- **视觉愉悦**：色彩丰富但和谐，动效精致但不干扰
- **跨平台一致**：iPhone / iPad / Mac 体验统一

### 1.4 与 Liquid Glass 的关系

Prismatic Flow 建立在 iOS 26 的 Liquid Glass 设计语言基础上，但进行了以下增强：

| Liquid Glass 基础 | Prismatic Flow 增强 |
|-------------------|---------------------|
| 毛玻璃材质 | + 动态渐变背景氛围 |
| 标准圆角 | + 非对称有机圆角 |
| 系统动画 | + 脉冲/涟漪/粒子特效 |
| 单色强调 | + 渐变色带系统 |
| 扁平层次 | + 3D 倾斜与视差 |

---

## 2. 色彩系统：Prismatic Palette

### 2.1 平台渐变色带（Platform Gradient Bands）

每个平台不再是单一品牌色，而是 **3-4 色渐变光谱**：

| 平台 | 渐变色带 | 色值 | 情感表达 |
|------|----------|------|----------|
| **微博** | 珊瑚红 → 琥珀橙 → 金黄 | #FF6B6B → #F59E0B → #FBBF24 | 热烈、广场感 |
| **小红书** | 樱花粉 → 玫瑰红 → 珊瑚 | #FDA4AF → #F43F5E → #FF6B6B | 精致、生活美学 |
| **Bilibili** | 天青蓝 → 青色 → 薄荷绿 | #38BDF8 → #22D3D8 → #34D399 | 活力、年轻 |
| **抖音** | 霓虹粉 → 电紫 → 深黑 | #F472B6 → #A855F7 → #1E1B4B | 潮流、夜生活 |
| **X** | 天蓝 → 靛蓝 → 深蓝 | #38BDF8 → #6366F1 → #1E3A8A | 理性、全球化 |
| **知乎** | 宝石蓝 → 紫罗兰 → 薰衣草 | #3B82F6 → #8B5CF6 → #C4B5FD | 深度、知性 |

**技术实现：**

```swift
// 使用 MeshGradient 创建有机流动渐变
MeshGradient(
    width: 3, height: 3,
    points: [
        [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
        [0.0, 0.5], [0.5, 0.5], [1.0, 0.5],
        [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
    ],
    colors: platformGradientColors
)

// 或使用 LinearGradient
LinearGradient(
    colors: [.coralRed, .amberOrange, .gold],
    startPoint: .topLeading,
    endPoint: .bottomTrailing
)
```

**使用原则：**

- **卡片光带**：左侧 4pt 宽渐变条，标识平台
- **背景氛围**：极淡的渐变，根据当前平台动态变化
- **选中态**：渐变下划线 / 发光边框
- **避免**：大面积纯色块（保持轻盈感）

### 2.2 热度光谱（Heat Spectrum）

热度不再是三档离散值，而是**连续光谱映射**：

```
热度值:  0      10k     30k     50k     100k    200k    500k    1M+
         │       │       │       │       │       │       │       │
色彩:   银灰 → 冰蓝 → 薄荷 → 琥珀 → 橙色 → 珊瑚红 → 猩红 → 金焰✨
         │       │       │       │       │       │       │       │
状态:   冷寂   微温    温热    升温    火热    炽热    爆发   现象级
```

**色值定义：**

| 热度等级 | 范围 | 主色 | 特效 |
|----------|------|------|------|
| 冷寂 | 0 - 10k | #9CA3AF (银灰) | 无 |
| 微温 | 10k - 30k | #93C5FD (冰蓝) | 无 |
| 温热 | 30k - 50k | #6EE7B7 (薄荷) | 无 |
| 升温 | 50k - 100k | #FCD34D (琥珀) | 无 |
| 火热 | 100k - 200k | #FB923C (橙色) | 轻微发光 |
| 炽热 | 200k - 500k | #F87171 (珊瑚红) | 脉冲动画 |
| 爆发 | 500k - 1M | #DC2626 (猩红) | 发光边缘 |
| 现象级 | 1M+ | #FBBF24 (金焰) | 金色粒子飘散 |

### 2.3 动态背景氛围（Dynamic Ambient Background）

背景根据当前浏览内容**实时微调色调**：

- 浏览微博热搜 → 背景隐约泛出暖橙
- 浏览 B 站热门 → 背景流动着青蓝
- 多平台对比模式 → 彩虹光谱缓缓流动

**深色模式特殊处理：**

- 背景：宇宙深邃色调（#0F0A1F 深紫 + #0A1628 深蓝）
- 点缀：极淡的星点效果（可选）
- 渐变：降低饱和度 20%，保护视力

### 2.4 语义色（Semantic Colors）

| 语义 | 浅色模式 | 深色模式 | 用途 |
|------|----------|----------|------|
| 成功 | #10B981 | #34D399 | 操作成功、排名上升 |
| 警告 | #F59E0B | #FBBF24 | 注意提示 |
| 错误 | #EF4444 | #F87171 | 错误、排名下降 |
| 信息 | #3B82F6 | #60A5FA | 提示信息、新上榜 |

### 2.5 中性色（Neutral Colors）

- **主文字**：`.primary`（自动适配深色模式）
- **辅助文字**：`.secondary`
- **占位文字**：`.tertiary`
- **分割线**：`.separator`
- **背景**：`.systemBackground` / `.systemGroupedBackground`

---

## 3. 字体系统

### 3.1 字体族

| 用途 | 字体 | 说明 |
|------|------|------|
| 主字体 | SF Pro | 正文、说明 |
| 标题字体 | SF Pro Rounded | 亲和力、现代感 |
| 数字字体 | SF Mono | 热度值、排名、时间 |

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
- 热度数字使用 SF Mono，保持对齐

---

## 4. 间距系统

### 4.1 基础间距单位

采用 **8pt 网格系统**：

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

### 4.2 组件间距规范

| 场景 | 间距 | 值 |
|------|------|-----|
| 卡片内间距 | md | 16pt |
| 卡片外间距 | md | 16pt |
| 列表项间距 | sm | 12pt |
| 按钮内边距 | lg × sm | 24pt × 12pt |
| 页面边距 | md | 16pt |
| 模块间距 | xl | 32pt |

---

## 5. 圆角系统

### 5.1 标准圆角

| 尺寸 | 半径 | 用途 |
|------|------|------|
| Small | 8pt | 按钮、标签、输入框 |
| Medium | 16pt | 标准卡片 |
| Large | 24pt | 面板、模态框 |
| Extra Large | 32pt | 特殊组件 |

### 5.2 非对称圆角（Asymmetric Corners）

**Morphic Card 专用**——打破呆板感：

```swift
// 非对称圆角定义
struct AsymmetricCorners {
    let topLeading: CGFloat = 20
    let topTrailing: CGFloat = 12
    let bottomTrailing: CGFloat = 20
    let bottomLeading: CGFloat = 12
}

// SwiftUI 实现
.clipShape(
    UnevenRoundedRectangle(
        topLeadingRadius: 20,
        bottomLeadingRadius: 12,
        bottomTrailingRadius: 20,
        topTrailingRadius: 12
    )
)
```

### 5.3 连续曲线

- 优先使用 `RoundedRectangle(cornerRadius:style: .continuous)`
- 大尺寸圆角视觉更柔和

---

## 6. 阴影与深度：3D Depth System

### 6.1 Z 轴层级

```
Layer 3: 悬浮元素（FAB、Toast、Modal）── 最强阴影 + 模糊
Layer 2: 交互卡片 ──────────────────── 中等阴影
Layer 1: 内容区域 ──────────────────── 轻微阴影
Layer 0: 背景 ────────────────────── 无阴影
```

### 6.2 阴影层级

| 层级 | 模糊 | Y 偏移 | 透明度 | 用途 |
|------|------|--------|--------|------|
| Subtle | 2pt | 1pt | 0.05 | 轻微悬浮 |
| Light | 4pt | 2pt | 0.08 | 卡片默认 |
| Medium | 8pt | 4pt | 0.12 | 悬浮态 |
| Heavy | 16pt | 8pt | 0.16 | 模态框 |
| Glow | 12pt | 0pt | 0.3 | 高热度发光 |

### 6.3 3D 倾斜效果

```swift
// 卡片默认微倾斜
.rotation3DEffect(.degrees(1), axis: (x: 1, y: 0, z: 0))

// 触摸时倾斜
.rotation3DEffect(
    .degrees(isPressed ? 3 : 1),
    axis: (x: pressLocation.y, y: -pressLocation.x, z: 0)
)
```

### 6.4 视差滚动

滚动列表时产生深度错觉：

- 背景氛围层：移动速度 = 内容速度 × 0.3
- 顶部 Header：轻微缩放效果
- 使用 `GeometryReader` + `scrollViewOffset` 实现

---

## 7. 材质效果（Material）

### 7.1 材质层级

| 材质 | 效果 | 用途 |
|------|------|------|
| ultraThinMaterial | 极轻模糊 | 悬浮 TabBar |
| thinMaterial | 轻微模糊 | 标签、Chip |
| regularMaterial | 中等模糊 | 卡片背景 |
| thickMaterial | 较强模糊 | 导航栏 |
| ultraThickMaterial | 最强模糊 | 模态框 |

### 7.2 玻璃效果增强

```swift
// Liquid Glass 基础 + 渐变叠加
view
    .background(.ultraThinMaterial)
    .background(
        platformGradient.opacity(0.1)
    )
    .glassEffect() // iOS 26
```

---

## 8. 组件设计规范

### 8.1 Morphic Card（变形卡片）

**告别死板矩形，拥抱有机形态**

```
╭▓▓╭─────────────────────────────────────╮────╮
│▓▓│ 1  热搜标题在这里显示                │    │
│▓▓│    ══════════════════════░░░  1.2M   │~~~~│
│▓▓│    微博 · 2小时前 · ↑3              │    │
╰▓▓╰─────────────────────────────────────╯────╯
 ↑                              ↑          ↑
 渐变光带                      能量条     迷你曲线
```

**设计细节：**

| 属性 | 规范 |
|------|------|
| 圆角 | 非对称：20/12/20/12 pt |
| 背景 | regularMaterial + 平台渐变 0.05 |
| 光带 | 左侧 4pt 宽，平台渐变色 |
| 内边距 | 16pt |
| 最小高度 | 88pt |
| 阴影 | Light → Medium（悬浮） |

**状态样式：**

| 状态 | 样式变化 |
|------|----------|
| 默认 | Light 阴影，微倾斜 1° |
| 按下 | 缩放 0.98，阴影加深，倾斜 3° |
| 高热度 | 发光边缘（Glow 阴影） |
| 爆发级 | 金色粒子飘散 |

**呼吸效果：**

```swift
// 卡片微呼吸动画（几乎察觉不到但有生命感）
.scaleEffect(breathingScale) // 1.0 ~ 1.005
.animation(
    .easeInOut(duration: 3).repeatForever(autoreverses: true),
    value: breathingScale
)
```

### 8.2 Platform Ribbon（平台彩带选择器）

**替代传统 Chip/SegmentedControl**

```
╭─────────────────────────────────────────────────╮
│  ◉ 全部  ┃  微博  ┃  小红书  ┃  B站  ┃  抖音  → │
│          ╰═══════╯                              │
╰─────────────────────────────────────────────────╯
           ↑ 选中项：渐变下划线 + 文字发光
```

**设计细节：**

| 属性 | 规范 |
|------|------|
| 高度 | 44pt |
| 项间距 | 24pt |
| 背景 | ultraThinMaterial，几乎透明 |
| 选中指示器 | 渐变下划线 3pt + 发光 |
| 滚动 | 水平惯性滚动 |

**切换动画：**

- 下划线使用 `matchedGeometryEffect` 平滑移动
- 颜色渐变过渡 0.3s

### 8.3 Heat Energy Bar（热度能量条）

**替代传统进度条**

```
══════════════════════░░░░  1.2M
└──── 渐变填充 ────┘└ 空 ┘  └ 数字
```

**设计细节：**

| 属性 | 规范 |
|------|------|
| 高度 | 4pt（常规）/ 6pt（详情页） |
| 圆角 | 2pt / 3pt |
| 填充 | 热度光谱渐变 |
| 背景 | 浅灰 0.1 透明度 |

**高热度特效：**

- 100k+：轻微发光
- 500k+：脉冲动画
- 1M+：金色粒子

### 8.4 Heat Pulse Curve（热度脉冲曲线）

#### 8.4.1 迷你版（卡片内嵌）

**尺寸：** 80 × 36pt

**样式：**

- 曲线：2pt 线宽 + 4pt 发光描边
- 颜色：热度光谱渐变
- 最新点：脉冲闪烁
- 无坐标轴

```swift
Chart(heatHistory) { point in
    LineMark(...)
        .interpolationMethod(.catmullRom)
        .foregroundStyle(heatGradient)
}
.chartXAxis(.hidden)
.chartYAxis(.hidden)
// 叠加发光
.shadow(color: platformColor.opacity(0.6), radius: 4)
```

#### 8.4.2 完整版（详情页）

**尺寸：** 全宽 × 200pt

**样式：**

- 渐变填充区域（平台色 0.3 → 透明）
- 曲线发光描边
- 网格背景（淡灰虚线）
- X/Y 轴刻度

**交互：**

- 触摸拖动：垂直光标 + 数据气泡
- 捏合缩放：时间范围切换
- 峰值/骤变：自动标记

### 8.5 Floating Glass TabBar（悬浮玻璃导航栏）

**告别传统底部栏**

```
            ╭───────────────────╮
            │  🏠  📊  🔍  ⚙️  │  ← 距底部 15pt
            │   ●              │
            ╰───────────────────╯
                ↑ 选中指示器随 Tab 滑动
```

**设计细节：**

| 属性 | 规范 |
|------|------|
| 形状 | 胶囊形，圆角 30pt |
| 宽度 | 屏幕宽 - 80pt |
| 高度 | 60pt |
| 距底部 | 15pt（安全区内） |
| 背景 | ultraThinMaterial + 微边框 |
| 阴影 | Medium |

**图标状态：**

| 状态 | 样式 |
|------|------|
| 未选中 | 线条风格，secondary 色 |
| 选中 | 填充风格 + 平台色发光 |

**选中指示器：**

- 底部小圆点 6pt
- `matchedGeometryEffect` 平滑移动

### 8.6 Rank Change Indicator（排名变化指示器）

| 状态 | 图标 | 颜色 | 动画 |
|------|------|------|------|
| 上升 | ↑ / arrow.up | 成功绿 | 轻微上浮 |
| 下降 | ↓ / arrow.down | 错误红 | 轻微下沉 |
| 新增 | NEW 标签 | 信息蓝 | 脉冲发光 |
| 持平 | — | 灰色 | 无 |

### 8.7 按钮系统

**主按钮（Primary）：**

```swift
Button("Action") { }
    .buttonStyle(.borderedProminent)
    .tint(accentGradient) // 渐变填充
```

**次按钮（Secondary）：**

```swift
Button("Action") { }
    .buttonStyle(.bordered)
    .background(.regularMaterial)
```

**图标按钮（Icon）：**

- 圆形 44 × 44pt
- ultraThinMaterial 背景
- 触摸：涟漪效果

### 8.8 输入框（TextField）

| 属性 | 规范 |
|------|------|
| 背景 | regularMaterial |
| 圆角 | 12pt |
| 内边距 | 16pt × 12pt |
| 边框 | 无（聚焦时显示渐变边框） |

---

## 9. 热度曲线深度设计

### 9.1 设计目标

**核心价值：** 让用户直观感受"热点的兴起与衰落"，而非仅看静态数字。

### 9.2 数据采样策略

| 话题等级 | 采样频率 | 存储时长 |
|----------|----------|----------|
| TOP 10 | 10 分钟 | 7 天 |
| TOP 50 | 30 分钟 | 3 天 |
| 长尾 | 1 小时 | 1 天 |

### 9.3 数据结构

```swift
struct HeatDataPoint: Codable, Sendable, Identifiable {
    let id: UUID
    let timestamp: Date
    let heatValue: Int
    let rank: Int?
}
```

### 9.4 动画效果

| 场景 | 动画 | 时长 |
|------|------|------|
| 进入 | 曲线从左到右绘制 | 0.8s |
| 更新 | 新点淡入 + 曲线平滑过渡 | 0.3s |
| 悬浮 | 垂直虚线 + 气泡出现 | 0.2s |

### 9.5 特殊状态

- **数据不足**（< 3 点）：显示"数据收集中..."
- **已下架**（热度归零）：曲线断开 + ⚠️ 图标
- **爆发增长**：曲线该段高亮 + 标记

---

## 10. 动效系统：Living Motion

### 10.1 动画原则

| 类型 | 效果 | 用途 | 参数 |
|------|------|------|------|
| **Pulse** | 周期性缩放/发光 | 实时热点、新数据 | 1.5s 周期 |
| **Ripple** | 从中心向外扩散 | 点击反馈、新上榜 | 0.6s |
| **Flow** | 颜色/形态平滑过渡 | Tab 切换、筛选 | 0.3s |
| **Breathe** | 极微弱持续运动 | 整体生命感 | 3s 周期 |
| **Morph** | 元素形态无缝转换 | 列表→详情过渡 | 0.4s |

### 10.2 动画时长规范

| 类型 | 时长 | 曲线 | 用途 |
|------|------|------|------|
| Instant | 0.1s | linear | 即时反馈 |
| Quick | 0.2s | easeOut | 按钮、开关 |
| Standard | 0.3s | easeInOut | 页面切换 |
| Slow | 0.5s | easeInOut | 模态框 |
| Spring | — | spring(0.5, 0.7) | 弹性交互 |

### 10.3 关键交互动画

#### 下拉刷新

```
下拉 → 顶部出现平台色光晕，越拉越亮
刷新中 → 光晕变成旋转渐变环
完成 → 光晕爆散成粒子，数据淡入
```

#### 收藏操作

```
点击心形 → 放大 1.3x + 颜色填充
         → 粒子从心形四散（平台色）
         → 轻触觉反馈
```

#### 卡片展开到详情

```
使用 matchedGeometryEffect
卡片"生长"成全屏
背景颜色过渡到平台渐变
曲线从迷你版"展开"成完整版
```

### 10.4 触觉反馈

| 操作 | 反馈类型 |
|------|----------|
| 按钮点击 | `.impact(.light)` |
| 收藏成功 | `.impact(.medium)` |
| 错误操作 | `.notification(.error)` |
| 刷新完成 | `.notification(.success)` |

### 10.5 Metal Shader 特效（高级）

| 效果 | 用途 | 实现 |
|------|------|------|
| 热度光晕 | 高热度卡片 | Glow shader |
| 涟漪交互 | 点击位置水波纹 | Ripple shader |
| 色彩位移 | 爆发级卡片边缘 | RGB shift shader |

---

## 11. 响应式设计

### 11.1 断点定义

| 设备 | 宽度范围 | 布局方式 |
|------|----------|----------|
| iPhone | < 428pt | 单列 + 悬浮 TabBar |
| iPad | 428pt - 1024pt | 双列 + NavigationSplitView |
| Mac | > 1024pt | 三列 + Sidebar |

### 11.2 布局适配

**iPhone：**

- 单列卡片流
- 悬浮玻璃 TabBar
- 下拉展开筛选器

**iPad：**

- 双/三列瀑布流
- 侧边栏用渐变背景区分
- 卡片 hover 有 3D 倾斜

**Mac：**

- 三列布局 + 可调宽度
- 鼠标悬停效果丰富
- 键盘快捷键支持

### 11.3 横屏适配

| 设备 | 横屏布局 |
|------|----------|
| iPhone | 双列网格 |
| iPad | 三列网格 |
| Mac | 保持三列（列宽增加） |

---

## 12. 深色模式

### 12.1 颜色映射

| 元素 | 浅色模式 | 深色模式 |
|------|----------|----------|
| 背景 | #FFFFFF | #0F0A1F (宇宙紫) |
| 卡片 | #F3F4F6 | #1E1B4B (深紫) |
| 文字 | #111827 | #F9FAFB |
| 阴影 | 黑 0.12 | 白 0.05 |
| 发光 | 平台色 0.3 | 平台色 0.4 |

### 12.2 渐变调整

- 深色模式：饱和度 -20%
- 发光效果：强度 +10%
- 背景氛围：更加微妙

---

## 13. 无障碍设计

### 13.1 VoiceOver

- 所有交互元素提供语义化 `accessibilityLabel`
- 图标按钮提供文字说明
- 热度曲线提供数据摘要朗读

### 13.2 颜色对比

- WCAG AA：文字对比度 ≥ 4.5:1
- 关键元素对比度 ≥ 7:1
- 不仅依赖颜色传达信息（配合图标/文字）

### 13.3 动画控制

- 尊重系统"减弱动态效果"设置
- 关键信息不依赖动画传递
- 提供动画关闭选项

### 13.4 触摸目标

- 最小触摸区域：44 × 44pt
- 按钮间距：≥ 8pt

---

## 14. 特殊状态设计

### 14.1 空状态

- **动态插画**：Lottie 动画（搜索中放大镜、空列表风滚草）
- **渐变背景**：淡淡平台色氛围
- **引导文案**：带趣味性

### 14.2 加载状态

**骨架屏 2.0：**

- 渐变闪烁（非灰色块）
- 形状模拟真实卡片
- 1.5s 闪烁周期

```swift
.shimmer(
    gradient: Gradient(colors: [.gray.opacity(0.3), .gray.opacity(0.1), .gray.opacity(0.3)]),
    duration: 1.5
)
```

### 14.3 错误状态

- **友好插画**：断线网线、迷路图标
- **渐变强调**：红 → 橙渐变（不刺眼但醒目）
- **重试按钮**：脉冲动画引导

---

## 15. 组件库清单

### 15.1 已实现组件

- [x] DesignSystem（基础 Token）
- [x] SplashView（启动页）
- [x] MainNavigationView（跨平台导航）
- [x] FeedView（占位）
- [x] CompareView（占位）
- [x] SearchView（占位）
- [x] SettingsView（占位）

### 15.2 待实现组件（Prismatic Flow）

**核心组件：**

- [ ] MorphicCard（变形卡片）
- [ ] PlatformRibbon（平台彩带选择器）
- [ ] HeatEnergyBar（热度能量条）
- [ ] HeatPulseCurve（热度脉冲曲线）
- [ ] FloatingGlassTabBar（悬浮玻璃导航）
- [ ] RankChangeIndicator（排名变化）

**辅助组件：**

- [ ] PlatformGradientBand（平台渐变光带）
- [ ] DynamicAmbientBackground（动态背景）
- [ ] GlowEffect（发光效果修饰符）
- [ ] PulseAnimation（脉冲动画修饰符）
- [ ] RippleEffect（涟漪效果）
- [ ] ParticleEmitter（粒子发射器）

**状态组件：**

- [ ] ShimmerSkeleton（骨架屏）
- [ ] EmptyStateView（空状态）
- [ ] ErrorStateView（错误状态）

---

## 16. SF Symbols 使用

| 功能 | 图标名称 | 备注 |
|------|----------|------|
| 热榜 | `flame` / `flame.fill` | |
| 对比 | `chart.bar.xaxis` | |
| 搜索 | `magnifyingglass` | |
| 设置 | `gear` / `gearshape.fill` | |
| 收藏 | `heart` / `heart.fill` | |
| 分享 | `square.and.arrow.up` | |
| 排名上升 | `arrow.up` | 配合绿色 |
| 排名下降 | `arrow.down` | 配合红色 |
| 热度曲线 | `chart.line.uptrend.xyaxis` | |
| 刷新 | `arrow.clockwise` | |
| 筛选 | `line.3.horizontal.decrease` | |

---

## 17. 技术实现要点

| 效果 | SwiftUI 实现 |
|------|--------------|
| 平台渐变光带 | `LinearGradient` + `mask` |
| 动态背景 | `MeshGradient` + `TimelineView` |
| 发光效果 | 多层 `shadow` + `blur` 叠加 |
| 3D 倾斜 | `rotation3DEffect` |
| 脉冲动画 | `PhaseAnimator` |
| 涟漪效果 | Metal Shader 或 `Canvas` |
| 流体过渡 | `matchedGeometryEffect` |
| 粒子效果 | `TimelineView` + `Canvas` |
| 非对称圆角 | `UnevenRoundedRectangle` |
| 玻璃效果 | `.glassEffect()` (iOS 26) |

---

## 18. 参考资源

**Apple 官方：**

- [Human Interface Guidelines - iOS 26](https://developer.apple.com/design/human-interface-guidelines/ios)
- [SF Symbols](https://developer.apple.com/sf-symbols/)
- [Swift Charts](https://developer.apple.com/documentation/Charts)
- [WWDC25 - Liquid Glass](https://developer.apple.com/wwdc25)

**设计灵感：**

- Spotify（数据可视化、渐变运用）
- Apple Music（流体动画）
- Apple Stocks（曲线交互）
- Arc Browser（创新交互）

---

## 19. 版本历史

- **v2.0（2026-01-21）**：Prismatic Flow 设计系统
  - 全新渐变色带系统
  - 热度光谱映射
  - Morphic Card 有机形态
  - Living Motion 动效体系
  - 3D 深度系统
- **v1.0（2026-01-21）**：初始版本，Liquid Glass 基础
