# TrendLens User Interaction Design

> **文档定位：** Gesture & Motion System - 用户交互与动画体验完整方案
> **配合文档：** [TrendLens UI Design System.md](TrendLens%20UI%20Design%20System.md)
> **最后更新：** 2026-01-22
> **版本：** v1.0 - Fluid Interaction

---

## 1. 交互哲学：Gesture First, Touch Natural

### 1.1 核心原则

**让交互如水般流动，让意图在指尖自然表达**

| 原则 | 具体表现 | 避免 |
|------|----------|------|
| **手势优先** | 核心操作通过滑动完成，点击为辅 | 过度依赖按钮 |
| **物理隐喻** | 交互遵循现实世界物理规律 | 突兀的数字化跳转 |
| **即时反馈** | 视觉+触觉双重确认，<16ms 响应 | 延迟或断层 |
| **渐进揭示** | 复杂功能通过长按/二级手势访问 | 一次性展示所有功能 |
| **容错设计** | 手势可中断、可撤销 | 不可逆的误触 |

### 1.2 交互分类体系

| 交互类型 | 符号 | 核心场景 | 设计理念 |
|----------|------|----------|----------|
| **垂直滑动** | ↕️ | 内容浏览、刷新 | 自然阅读流 |
| **水平滑动** | ↔️ | 切换、快捷操作 | 空间导航 |
| **点击/轻触** | 👆 | 选择、确认 | 精准操作 |
| **长按** | 👆⏱️ | 上下文菜单、预览 | 深度交互 |
| **捏合** | 🤏 | 缩放、时间范围 | 细节探索 |
| **卡片翻转** | 🔄 | 对比、切换视角 | 信息对照 |

---

## 2. 页面级交互地图

### 2.1 Feed 页面（热榜首页）

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  ┌─ 平台彩带 ─────────────────────────────────────┐    │
│  │ ◉全部 │ 微博 │ 小红书 │ B站 │ 抖音 │ X │ 知乎 → │    │  ← ↔️ 水平滑动切换
│  └───────────────────────────────────────────────┘     │     👆 点击直接选中
│                                                         │
│  ╭─ 卡片列表 ───────────────────────────────────╮      │
│  │                                               │      │  ← ↕️ 垂直滚动浏览
│  │  ╭─────────────────────────────────────╮     │      │     ↕️ 下拉刷新
│  │  │ ▓▓│ #1 卡片标题                    │     │      │     👆 点击进入详情
│  │  │ ▓▓│ ═══════════░░░  1.2M   ~~~~    │     │      │     ↔️ 左滑快捷操作
│  │  │ ▓▓│ 微博 · 2h前 · ↑3              │     │      │     👆⏱️ 长按预览+菜单
│  │  ╰─────────────────────────────────────╯     │      │
│  │      ↑         ↑        ↑      ↑      ↑      │      │
│  │   渐变光带   热度条   数据   迷你曲线         │      │
│  │                                               │      │
│  │  ╭─────────────────────────────────────╮     │      │
│  │  │ ▓▓│ #2 卡片标题                    │     │      │
│  │  ╰─────────────────────────────────────╯     │      │
│  │                                               │      │
│  ╰───────────────────────────────────────────────╯      │
│                                                         │
│            ╭───────────────────╮                        │
│            │  🏠  📊  🔍  ⚙️  │                        │  ← 👆 点击切换 Tab
│            │   ●              │                        │     ↔️ 左右滑动切换
│            ╰───────────────────╯                        │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Compare 页面（对比分析）

```
┌─────────────────────────────────────────────────────────┐
│                                                         │
│  ┌─ 对比模式选择 ────────────────────────────────┐     │
│  │  [跨平台同话题]  [同平台时间线]  [自选对比]   │     │  ← 👆 点击切换模式
│  └───────────────────────────────────────────────┘     │
│                                                         │
│  ╭─ 对比卡片组 ─────────────────────────────────╮      │
│  │                                               │      │
│  │  ╭──────────╮   ←──→   ╭──────────╮          │      │  ← ↔️ 左右滑动翻转
│  │  │ 🔴 微博   │    🔄    │ 🔵 B站    │          │      │     🔄 双击翻转卡片
│  │  │ 1.2M     │          │ 890k     │          │      │     👆⏱️ 长按锁定
│  │  │ ~~曲线~~ │          │ ~~曲线~~ │          │      │
│  │  ╰──────────╯          ╰──────────╯          │      │
│  │                                               │      │
│  │         ↕️ 上下滑动切换对比对象               │      │
│  │                                               │      │
│  ╰───────────────────────────────────────────────╯      │
│                                                         │
│  ╭─ 综合曲线图 ─────────────────────────────────╮      │
│  │  ~~红色线~~                                   │      │  ← 👆 触摸拖动查看
│  │     ~~蓝色线~~                                │      │     🤏 捏合缩放时间
│  │        ~~绿色线~~                             │      │
│  │                                               │      │
│  ╰───────────────────────────────────────────────╯      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2.3 Detail 页面（话题详情）

```
┌─────────────────────────────────────────────────────────┐
│  ← 返回                              ♡ 收藏  ⋮ 更多    │  ← 👆 点击操作
│  ═══════════════════════════════════════════════════   │  ← ↕️ 下拉关闭
│                                                         │
│  ╭─ 话题信息 ───────────────────────────────────╮      │
│  │  标题: XXXXXXXXXXXXXX                        │      │
│  │  平台: 微博  热度: 1.2M  排名: #1 ↑3        │      │
│  ╰───────────────────────────────────────────────╯      │
│                                                         │
│  ╭─ 热度曲线（完整版）──────────────────────────╮      │
│  │                                               │      │  ← 👆 拖动光标
│  │  ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~           │      │     🤏 捏合缩放
│  │       ↑ 峰值标记                             │      │     👆👆 双击重置
│  │                                               │      │
│  ╰───────────────────────────────────────────────╯      │
│                                                         │
│  ┌─ 时间范围 ────────────────────────────────────┐     │
│  │  [1h]  [6h]  [24h]  [7d]  [30d]               │     │  ← 👆 点击切换
│  └───────────────────────────────────────────────┘     │     ↔️ 滑动微调
│                                                         │
│  ╭─ 相关话题 ───────────────────────────────────╮      │
│  │  相关卡片 1                                  │      │  ← ↕️ 垂直滚动
│  │  相关卡片 2                                  │      │     👆 点击跳转
│  ╰───────────────────────────────────────────────╯      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 2.4 Search 页面

```
┌─────────────────────────────────────────────────────────┐
│  ╭─────────────────────────────────────╮  [取消]       │
│  │ 🔍 搜索话题或关键词                 │               │  ← 👆 点击激活
│  ╰─────────────────────────────────────╯               │
│                                                         │
│  ┌─ 搜索历史 ────────────────────────────────────┐     │
│  │  最近搜索 1                            ✕      │     │  ← 👆 点击搜索
│  │  最近搜索 2                            ✕      │     │     ↔️ 左滑删除
│  └───────────────────────────────────────────────┘     │
│                                                         │
│  ╭─ 搜索结果 ───────────────────────────────────╮      │
│  │  结果卡片 1                                  │      │  ← ↕️ 滚动浏览
│  │  结果卡片 2                                  │      │
│  ╰───────────────────────────────────────────────╯      │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

---

## 3. 手势交互详细设计

### 3.1 垂直滑动 ↕️

#### 交互矩阵

| 场景 | 触发条件 | 动作 | 动画效果 | 触觉反馈 |
|------|----------|------|----------|----------|
| **列表滚动** | 单指上下滑动 | 浏览内容 | 惯性滚动 + 弹性回弹 | 无 |
| **下拉刷新** | 顶部继续下拉 > 60pt | 刷新数据 | 光晕 → 旋转 → 粒子爆散 | 触发时 `.impact(.medium)` |
| **上拉加载** | 底部继续上拉 | 加载更多 | 骨架屏渐显 | 无 |
| **详情页关闭** | 详情页下拉 > 100pt | 关闭返回 | 卡片缩小回原位 | `.impact(.light)` |
| **对比切换** | 对比页上下滑动 | 切换对比对象 | 卡片淡出/淡入 | `.selection` |

#### 下拉刷新动画时序

```
下拉距离:  0pt ────────── 60pt ────────── 120pt
           │               │                │
状态:     无反应     →    准备触发    →    已触发
光晕:     不可见     →    渐显(30%)   →    全亮(100%)
阻力:     正常       →    增加        →    锁定
触觉:     无         →    无          →    .impact(.medium)

松手后动画（0.0s - 2.0s）：
├─ 0.0s: 光晕变成旋转渐变环（平台色）
├─ 0.0s-1.5s: 环持续旋转（加载中）
├─ 1.5s: 数据加载完成
├─ 1.5s-1.8s: 光晕爆散成粒子，向下飘落
└─ 1.8s-2.0s: 新内容淡入 + 轻微上浮 10pt
```

**技术实现：**

```swift
@State private var refreshProgress: CGFloat = 0
@State private var isRefreshing = false

ScrollView {
    GeometryReader { geo in
        Color.clear.preference(
            key: ScrollOffsetKey.self,
            value: geo.frame(in: .named("scroll")).minY
        )
    }
    .frame(height: 0)

    // 内容...
}
.coordinateSpace(name: "scroll")
.onPreferenceChange(ScrollOffsetKey.self) { offset in
    if offset > 0 && !isRefreshing {
        refreshProgress = min(offset / 60, 1.5)
        if offset > 60 && !isDragging {
            triggerRefresh()
        }
    }
}
```

#### 详情页下拉关闭

```
下拉距离:  0pt ────── 50pt ────── 100pt ────── 150pt
           │           │            │            │
页面缩放:  1.0   →    0.95    →    0.9     →   关闭
背景透明:  0%    →    30%     →    60%     →   100%
圆角:      0pt   →    16pt    →    24pt    →   恢复卡片
触觉:      无    →    无       →    .impact(.light) → 无

松手判断:
- < 100pt: 弹性回弹到顶部（0.3s spring）
- ≥ 100pt: 继续关闭动画（0.4s easeOut）
```

---

### 3.2 水平滑动 ↔️

#### 交互矩阵

| 场景 | 触发条件 | 动作 | 动画效果 | 触觉反馈 |
|------|----------|------|----------|----------|
| **平台切换** | 彩带左右滑动 | 滚动平台列表 | 惯性滚动 + 渐变下划线跟随 | 无 |
| **卡片快捷操作** | 卡片左滑 > 80pt | 显示操作按钮 | 按钮从右侧滑出 | `.impact(.light)` |
| **对比翻转** | 对比卡片左右滑动 | 切换对比平台 | 3D Y轴翻转 | `.impact(.medium)` |
| **时间范围微调** | 曲线区域左右滑动 | 移动时间窗口 | 曲线平移 + 气泡跟随 | 无 |
| **Tab 切换** | TabBar 区域左右滑动 | 切换主 Tab | 页面滑动 + 指示器移动 | `.selection` |

#### 卡片左滑快捷操作详细设计

```
阶段 1: 正常状态
╭─────────────────────────────────────╮
│ ▓▓│ #1 卡片标题                    │
│ ▓▓│ ═══════════░░░  1.2M   ~~~~    │
│ ▓▓│ 微博 · 2h前 · ↑3              │
╰─────────────────────────────────────╯

阶段 2: 开始左滑（0-40pt）
╭─────────────────────────────────╮ ♡
│ ▓▓│ #1 卡片标题                │ 收藏  ← 收藏按钮露出 40%
╰─────────────────────────────────╯

阶段 3: 继续左滑（40-80pt）
╭───────────────────────────╮ ♡  🔕
│ ▓▓│ #1 卡片标题          │ 收藏 屏蔽  ← 两个按钮可见
╰───────────────────────────╯

阶段 4: 完全展开（80-160pt）
╭─────────────────╮ ♡  🔕  📤
│ ▓▓│ #1 卡片    │ 收藏 屏蔽 分享  ← 三个按钮完全展开
╰─────────────────╯

松手行为:
- < 40pt: 弹性回弹到关闭
- 40-80pt: 弹性定位到 80pt（显示 2 个按钮）
- > 80pt: 锁定在 160pt（显示 3 个按钮）
```

**快捷操作按钮设计：**

| 按钮 | 图标 | 颜色 | 宽度 | 功能 | 点击效果 |
|------|------|------|------|------|----------|
| 收藏 | `heart.fill` | 平台渐变色 | 80pt | 添加/移除收藏 | 放大 + 粒子 |
| 屏蔽 | `eye.slash` | 灰色 | 80pt | 屏蔽话题 | Toast 提示 |
| 分享 | `square.and.arrow.up` | 蓝色 | 80pt | 系统分享 | 分享面板 |

**技术实现：**

```swift
@State private var swipeOffset: CGFloat = 0
@State private var showActions = false

var drag: some Gesture {
    DragGesture()
        .onChanged { value in
            let translation = value.translation.width
            if translation < 0 {  // 仅左滑
                swipeOffset = max(translation, -160)
            }
        }
        .onEnded { value in
            let translation = value.translation.width
            let velocity = value.predictedEndTranslation.width

            if translation < -80 || velocity < -300 {
                // 完全展开
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    swipeOffset = -160
                    showActions = true
                }
                HapticManager.impact(.light)
            } else if translation < -40 {
                // 展开到 2 个按钮
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    swipeOffset = -80
                }
            } else {
                // 回弹
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    swipeOffset = 0
                }
            }
        }
}
```

#### Tab 切换左右滑动

**全局手势：** 在 TabView 内容区域左右滑动切换 Tab

```
滑动方向:  ←──────────────────────→
Tab 顺序:  热榜 → 对比 → 搜索 → 设置

触发条件:
- 滑动距离 > 屏幕宽 25%  或
- 滑动速度 > 300pt/s

动画效果:
- 当前页面向左移出，新页面从右侧滑入
- 页面切换使用 .transition(.asymmetric(...))
- 底部指示器同步移动
- 触觉反馈: .selection
```

---

### 3.3 点击/轻触 👆

#### 交互矩阵

| 场景 | 触发 | 动作 | 视觉反馈 | 触觉反馈 |
|------|------|------|----------|----------|
| **卡片点击** | 单击卡片 | 进入详情页 | 缩放 0.98 → 展开过渡 | `.impact(.light)` |
| **平台选择** | 单击平台名 | 筛选该平台 | 渐变下划线滑动 + 列表刷新 | `.selection` |
| **Tab 切换** | 单击 Tab 图标 | 切换页面 | 图标放大 + 指示器移动 | `.selection` |
| **收藏按钮** | 单击心形 | 切换收藏状态 | 心形放大 + 粒子爆散 | `.impact(.medium)` |
| **时间范围** | 单击时间按钮 | 切换曲线范围 | 按钮高亮 + 曲线动画重绘 | `.selection` |
| **返回** | 单击返回箭头 | 返回上一页 | 页面右滑退出 | `.impact(.light)` |

#### 卡片点击到详情的过渡动画

```
时间轴: 0.0s ──────→ 0.1s ──────→ 0.4s ──────→ 0.7s ──────→ 1.0s
        │            │            │            │            │
步骤 1: 按下         │            │            │            │
        └→ 卡片缩放 0.98，阴影加深，3D 轻微倾斜
        └→ 触觉: .impact(.light)
                     │
步骤 2:              松手         │            │            │
                     └→ 背景遮罩淡入（0 → 60%）
                     └→ 卡片开始"生长"（matchedGeometryEffect）
                                  │
步骤 3:                           展开到全屏   │            │
                                  └→ 卡片填满屏幕
                                  └→ 背景渐变到平台色
                                               │
步骤 4:                                       内容淡入     │
                                               └→ 详情信息淡入
                                               └→ 顶部栏从上方滑入
                                                            │
步骤 5:                                                    曲线绘制
                                                            └→ 迷你曲线"展开"成完整曲线
                                                            └→ 曲线从左到右绘制
```

**技术实现：**

```swift
struct CardDetailTransition: View {
    @Namespace private var namespace
    @State private var showDetail = false

    var body: some View {
        ZStack {
            if !showDetail {
                // 卡片缩略态
                CardView(topic: topic)
                    .matchedGeometryEffect(id: "card", in: namespace)
                    .onTapGesture {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showDetail = true
                        }
                        HapticManager.impact(.light)
                    }
            } else {
                // 详情页
                DetailView(topic: topic)
                    .matchedGeometryEffect(id: "card", in: namespace)
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .scale(scale: 0.98)),
                        removal: .opacity
                    ))
            }
        }
    }
}
```

#### 收藏操作动画

```
时间轴: 0.0s ──→ 0.05s ──→ 0.15s ──→ 0.3s ──→ 0.8s ──→ 1.0s
        │        │         │         │        │        │
步骤:   点击     触觉      颜色填充  心形回弹 粒子飘散 粒子消失
        │        │         │         │        │        │
心形:   1.0x → 1.1x  →  1.3x   →   1.0x  →  1.0x  → 1.0x
颜色:   ♡    →  ♡    →   ♥     →    ♥   →   ♥   →  ♥
触觉:   —    →  .impact(.medium) →  —   →   —   →  —
粒子:   —    →   —    →   发射   → 扩散  → 透明  → 消失
```

**粒子效果参数：**

```swift
struct HeartParticle {
    let count: Int = Int.random(in: 8...12)
    let initialVelocity: CGFloat = 300  // pt/s
    let angle: Range<Double> = 0..<360
    let lifetime: TimeInterval = 0.8
    let fadeOut: TimeInterval = 0.3  // 最后 0.3s 淡出
    let size: CGFloat = 12
    let color: Color = platformGradient.colors.randomElement()
    let rotation: Bool = true
}
```

---

### 3.4 长按 👆⏱️

#### 交互矩阵

| 场景 | 触发条件 | 动作 | 视觉反馈 | 触觉反馈 |
|------|----------|------|----------|----------|
| **卡片预览** | 长按卡片 > 0.5s | 显示预览 + 菜单 | 卡片放大 1.1x + 背景模糊 | `.impact(.medium)` |
| **平台长按** | 长按平台名 > 0.5s | 显示平台详情 | 气泡弹出 | `.impact(.light)` |
| **曲线长按** | 长按曲线点 | 锁定显示数据 | 垂直虚线 + 数据气泡 | `.impact(.light)` |
| **排名长按** | 长按排名数字 | 显示排名历史 | 迷你历史卡片 | `.impact(.light)` |

#### 长按预览菜单（Context Menu）

```
长按时间线: 0.0s ──────→ 0.5s ──────→ 0.7s
            │            │            │
状态:       正常         触发         菜单显示
触觉:       —           .impact(.medium)  —
视觉:       —           卡片放大      菜单淡入

菜单布局:
╭─────────────────────────────────────────────────╮
│                                                 │
│   ╭───────────────────────────────────╮        │
│   │                                   │        │  ← 卡片放大预览 1.1x
│   │   #1 卡片标题                     │        │    带详细信息
│   │   ═══════════░░░  1.2M            │        │
│   │   微博 · 2小时前 · ↑3             │        │
│   │                                   │        │
│   ╰───────────────────────────────────╯        │
│                                                 │
├─────────────────────────────────────────────────┤
│  ♡ 收藏话题         →  添加到收藏夹            │
│  📤 分享           →  系统分享面板              │
│  🔕 屏蔽话题       →  不再显示此话题            │
│  🚫 屏蔽关键词     →  添加关键词到屏蔽列表      │
│  📋 复制标题       →  复制到剪贴板              │
│  📊 查看趋势       →  跳转到详情页              │
╰─────────────────────────────────────────────────╯
                 ↑
        背景: 60% 模糊遮罩
```

**菜单项设计：**

| 图标 | 文字 | 动作 | 二级确认 |
|------|------|------|----------|
| ♡ | 收藏话题 | 切换收藏状态 | 无 |
| 📤 | 分享 | 打开系统分享 | 无 |
| 🔕 | 屏蔽话题 | 屏蔽此话题 | Toast 提示 |
| 🚫 | 屏蔽关键词 | 打开关键词编辑 | 输入框确认 |
| 📋 | 复制标题 | 复制文本 | Toast 提示 |
| 📊 | 查看趋势 | 进入详情页 | 无 |

**技术实现：**

```swift
CardView(topic: topic)
    .contextMenu {
        Button(action: { toggleFavorite() }) {
            Label("收藏话题", systemImage: "heart.fill")
        }

        Button(action: { share() }) {
            Label("分享", systemImage: "square.and.arrow.up")
        }

        Divider()

        Button(role: .destructive, action: { blockTopic() }) {
            Label("屏蔽话题", systemImage: "eye.slash")
        }
    } preview: {
        CardPreviewView(topic: topic)
            .frame(width: 320, height: 180)
    }
```

---

### 3.5 捏合手势 🤏

#### 交互矩阵

| 场景 | 触发 | 动作 | 动画效果 | 范围 |
|------|------|------|----------|------|
| **曲线时间缩放** | 双指捏合/张开 | 调整时间范围 | 曲线平滑缩放 | 1h ↔ 30d |
| **列表密度**（可选） | 双指捏合/张开 | 调整卡片大小 | 卡片重排动画 | 紧凑 ↔ 舒适 |

#### 曲线缩放档位

```
捏合 ←──────────────────────────────────────────────────→ 张开

 1h      3h      6h      12h     24h     3d      7d      30d
 │       │       │       │       │       │       │       │
 最细粒度                                                 最长时间

缩放行为:
- 捏合距离 < -20pt: 向左切换一档（更长时间）
- 张开距离 > +20pt: 向右切换一档（更短时间）
- 动画: 曲线平滑变形（0.4s spring）
- X 轴刻度淡出 → 重新计算 → 淡入（0.3s）
```

**技术实现：**

```swift
@State private var timeRange: TimeRange = .day24h
@State private var magnification: CGFloat = 1.0

var magnificationGesture: some Gesture {
    MagnificationGesture()
        .onChanged { value in
            magnification = value
        }
        .onEnded { value in
            let newRange: TimeRange
            if value < 0.8 {
                // 捏合 → 更长时间
                newRange = timeRange.longer()
            } else if value > 1.2 {
                // 张开 → 更短时间
                newRange = timeRange.shorter()
            } else {
                newRange = timeRange
            }

            if newRange != timeRange {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    timeRange = newRange
                }
                HapticManager.selection()
            }

            magnification = 1.0
        }
}
```

---

### 3.6 双击 👆👆

#### 交互矩阵

| 场景 | 触发 | 动作 | 动画效果 |
|------|------|------|----------|
| **曲线重置** | 双击曲线区域 | 重置为默认时间范围 | 曲线缩放动画（0.3s） |
| **对比翻转** | 双击对比卡片 | 翻转显示另一面 | 3D Y轴翻转（0.6s） |
| **快速收藏**（可选） | 双击卡片 | 快速收藏/取消 | 心形放大 + 粒子 |
| **状态栏** | 双击状态栏 | 滚动到顶部 | 系统默认动画 |

---

## 4. 卡片翻转交互 🔄

### 4.1 对比模式卡片翻转

**应用场景：** Compare 页面的跨平台对比

**交互方式：**

| 手势 | 效果 | 动画参数 |
|------|------|----------|
| 左右滑动 | 翻转到另一平台数据 | 跟手翻转，释放后完成 |
| 双击 | 快速翻转 | 自动完成 180° 翻转 |
| 按住拖动 | 自由控制翻转角度 | 实时跟随手指 |

**翻转动画：**

```swift
// 3D Y轴翻转
.rotation3DEffect(
    .degrees(flipAngle),  // 0° → 180°
    axis: (x: 0, y: 1, z: 0),
    perspective: 0.5
)
.animation(.spring(response: 0.6, dampingFraction: 0.7), value: flipAngle)

// 翻转过程中切换内容
if flipAngle > 90 {
    // 显示背面内容（平台 B）
    BackContent()
        .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
} else {
    // 显示正面内容（平台 A）
    FrontContent()
}
```

**卡片正反面内容：**

```
正面 (平台 A)                    背面 (平台 B)
╭─────────────────╮            ╭─────────────────╮
│ 🔴 微博          │            │ 🔵 B站          │
│                 │    翻转    │                 │
│ 热度: 1.2M      │    ←→     │ 热度: 890k      │
│ 排名: #1        │    🔄     │ 排名: #3        │
│ 讨论: 45k       │            │ 讨论: 28k       │
│                 │            │                 │
│ ~~~ 热度曲线    │            │ ~~~ 热度曲线    │
╰─────────────────╯            ╰─────────────────╯

翻转时间: 0.6s spring
触觉: .impact(.medium) 在 90° 时
```

### 4.2 信息卡片翻转（详情页可选功能）

**应用场景：** 查看话题的更多维度信息

```
正面: 热度数据                  背面: 舆情分析
╭─────────────────╮            ╭─────────────────╮
│ 热度曲线        │            │ 情感分析        │
│ ~~~~~~~~~~~~    │    翻转    │                 │
│                 │    ←→     │ 😊 正面 60%     │
│ 峰值: 2.1M      │    🔄     │ 😐 中性 30%     │
│ 均值: 1.5M      │            │ 😞 负面 10%     │
│ 增长: +35%      │            │                 │
╰─────────────────╯            ╰─────────────────╯
```

---

## 5. 导航交互设计

### 5.1 主导航（Floating Glass TabBar）

```
╭───────────────────────────────────────╮
│     🏠        📊        🔍        ⚙️  │
│      ●                                │ ← 选中指示器
╰───────────────────────────────────────╯
     ↑          ↑         ↑         ↑
   热榜       对比       搜索      设置
```

**交互方式：**

| 手势 | 动作 | 动画 | 触觉 |
|------|------|------|------|
| 👆 点击图标 | 切换 Tab | 指示器滑动 + 颜色流动 | `.selection` |
| ↔️ TabBar 上滑动 | 切换相邻 Tab | 惯性切换 | `.selection` |
| 👆👆 双击当前 Tab | 滚动到顶部/刷新 | 列表动画滚动 | `.impact(.medium)` |

**指示器动画：**

```swift
Circle()
    .fill(platformColor)
    .frame(width: 6, height: 6)
    .matchedGeometryEffect(id: "tabIndicator", in: namespace)
    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
```

### 5.2 页面内导航

#### 详情页返回

| 手势 | 动作 | 动画 |
|------|------|------|
| 👆 点击返回箭头 | 标准返回 | 页面右滑退出 |
| ↔️ 屏幕边缘右滑 | 手势返回 | iOS 标准边缘返回 |
| ↕️ 下拉超过 100pt | 下拉关闭 | 交互式关闭动画 |

#### 下拉关闭动画详细参数

```
下拉距离:  0pt ────── 50pt ────── 100pt ────── 150pt
           │           │            │            │
页面缩放:  1.0   →    0.95    →    0.9     →   关闭
背景透明:  0%    →    30%     →    60%     →   100%
圆角:      0pt   →    16pt    →    24pt    →   恢复卡片
Y偏移:     0pt   →    50pt    →   100pt    →   150pt

触觉反馈:
- 100pt 时: .impact(.light)
- 关闭完成: 无（避免干扰）
```

### 5.3 模态页面

| 场景 | 触发 | 关闭方式 | 动画 |
|------|------|----------|------|
| 分享面板 | 点击分享按钮 | 点击外部 / 下滑 | 从底部弹出 |
| 筛选器 | 点击筛选图标 | 点击确认 / 外部 | 从底部弹出 |
| 设置详情 | 点击设置项 | 导航返回 | Push 动画 |
| 搜索 | 点击搜索框 | 点击取消 | 全屏模态 |

---

## 6. 反馈系统设计

### 6.1 触觉反馈矩阵

| 操作类型 | 反馈类型 | 强度 | 时机 | 使用频率 |
|----------|----------|------|------|----------|
| 普通点击 | `.impact` | light | 按下瞬间 | 高频 |
| 重要操作 | `.impact` | medium | 操作完成 | 中频 |
| 长按触发 | `.impact` | medium | 达到时长 | 低频 |
| 切换选择 | `.selection` | — | 状态改变 | 高频 |
| 成功 | `.notification` | success | 完成时 | 低频 |
| 错误 | `.notification` | error | 失败时 | 低频 |
| 警告 | `.notification` | warning | 需注意时 | 低频 |
| 下拉刷新触发 | `.impact` | medium | 超过阈值 | 中频 |

**触觉策略：**

```swift
enum HapticManager {
    static func impact(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.prepare()
        generator.selectionChanged()
    }

    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}
```

### 6.2 视觉反馈

| 操作 | 即时反馈 | 过程反馈 | 完成反馈 |
|------|----------|----------|----------|
| 按钮点击 | 缩放 0.95 | — | 恢复 + 涟漪 |
| 卡片点击 | 缩放 0.98 + 阴影加深 | 展开动画 | 详情页显示 |
| 收藏 | 心形高亮 | 放大动画 | 粒子爆散 |
| 刷新 | 光晕出现 | 旋转动画 | 粒子爆散 + 数据淡入 |
| 滑动操作 | 按钮滑出 | 跟随手指 | 操作完成/回弹 |
| 翻转 | 卡片开始旋转 | 3D 翻转中 | 背面内容显示 |

### 6.3 声音反馈（可选，默认关闭）

| 操作 | 声音 | 音量 | 条件 |
|------|------|------|------|
| 收藏成功 | 轻柔"叮" | 低 | 用户开启 |
| 刷新完成 | 轻柔提示音 | 低 | 用户开启 |
| 错误操作 | 轻柔警示音 | 低 | 用户开启 |

---

## 7. 手势冲突处理

### 7.1 优先级规则

```
优先级从高到低:
1. 系统手势（边缘返回、控制中心）────── 最高，不可覆盖
2. 模态关闭手势（下拉、点击外部）───── 模态层级
3. 内容交互手势（曲线拖动、捏合）───── 内容区域
4. 列表滚动手势（上下滚动）────────── 容器层级
5. 卡片操作手势（左滑快捷操作）────── 项目层级
6. 背景交互手势（Tab 切换滑动）────── 最低，可被覆盖
```

### 7.2 冲突场景处理

| 冲突场景 | 处理方式 | 判断条件 |
|----------|----------|----------|
| **列表滚动 vs 卡片左滑** | 判断初始滑动角度 | 角度 > 45° → 垂直滚动<br>角度 < 45° → 左滑操作 |
| **下拉刷新 vs 详情下拉关闭** | 根据页面类型 | Feed 页 → 刷新<br>详情页 → 关闭 |
| **曲线拖动 vs 页面滚动** | 区域判断 | 曲线区域内 → 锁定为曲线交互<br>外部 → 页面滚动 |
| **捏合缩放 vs 系统缩放** | 区域判断 | 曲线区域内 → 捕获捏合手势<br>外部 → 系统行为 |
| **左滑操作 vs 边缘返回** | 距离判断 | 距离屏幕边缘 < 20pt → 系统返回<br>> 20pt → 卡片左滑 |

**技术实现：**

```swift
// 判断滑动方向
func dragDirection(from translation: CGSize) -> DragDirection {
    let angle = atan2(translation.height, translation.width) * 180 / .pi
    if abs(angle) < 45 {
        return .horizontal
    } else {
        return .vertical
    }
}

// 高优先级手势示例
ScrollView {
    // 内容
}
.simultaneousGesture(
    DragGesture(minimumDistance: 20)
        .onChanged { value in
            if dragDirection(from: value.translation) == .horizontal {
                // 处理左滑操作
            }
        }
)
```

### 7.3 手势识别阈值

| 手势 | 触发阈值 | 取消阈值 | 时间限制 |
|------|----------|----------|----------|
| **点击** | 移动 < 10pt | 移动 > 10pt | < 0.3s |
| **长按** | 静止 > 0.5s | 移动 > 10pt | — |
| **滑动** | 移动 > 10pt | — | — |
| **快速滑动** | 速度 > 300pt/s | — | — |
| **左滑操作** | 左滑 > 80pt | 回弹 < 40pt | — |
| **下拉刷新** | 下拉 > 60pt | 松手 < 60pt | — |
| **详情关闭** | 下拉 > 100pt | 回弹 < 100pt | — |
| **捏合** | 距离变化 > 20pt | — | — |

---

## 8. 交互状态流程图

### 8.1 卡片生命周期

```
         ┌─────────────────────────────────────────────────┐
         │                                                 │
         ▼                                                 │
     ┌───────┐    点击    ┌─────────┐    松手    ┌───────┐ │
     │ 默认态 │ ────────→ │ 按下态   │ ────────→ │ 详情页 │ │
     └───────┘            └─────────┘            └───────┘ │
         │                     │                     │     │
         │ 长按 0.5s          │ 移动 > 10pt         │ 下拉 > 100pt
         ▼                     ▼                     │     │
     ┌───────┐            ┌─────────┐               │     │
     │ 预览态 │            │ 恢复默认 │               │     │
     └───────┘            └─────────┘               │     │
         │                                           │     │
         │ 选择菜单项                                │     │
         ▼                                           ▼     │
     ┌───────┐                                  ┌───────┐ │
     │ 执行操作│ ─────────────────────────────→ │ 默认态 │──┘
     └───────┘                                  └───────┘
```

### 8.2 左滑操作流程

```
默认态 ──→ 开始滑动 ──→ 滑动中 ──┬──→ 超过 40pt ──→ 显示按钮 ──┬──→ 点击按钮 ──→ 执行操作
                              │                          │
                              │                          └──→ 继续滑动 ──→ 全展开（160pt）
                              │
                              └──→ 未超过 40pt ──→ 回弹恢复（0.3s）

状态转换:
- 0-40pt:   部分显示，回弹概率 80%
- 40-80pt:  显示 2 个按钮，锁定到 80pt
- 80-160pt: 显示 3 个按钮，锁定到 160pt
- > 160pt:  锁定到 160pt（不再继续滑动）
```

### 8.3 下拉刷新流程

```
正常滚动 ──→ 到达顶部 ──→ 继续下拉 ──┬──→ < 60pt ──→ 松手回弹
                                    │
                                    └──→ ≥ 60pt ──→ 松手触发刷新 ──→ 加载数据 ──┬──→ 成功 ──→ 粒子爆散
                                                                             │
                                                                             └──→ 失败 ──→ Toast 提示

下拉中视觉反馈:
- 0-30pt:   光晕不可见
- 30-60pt:  光晕渐显（30% → 100%）
- 60pt:     触觉反馈 .impact(.medium)
- 60pt+:    光晕保持 100%，等待松手

刷新中动画:
- 光晕变成旋转环
- 持续旋转直到数据返回
- 成功 → 粒子爆散（0.8s）
- 失败 → 环消失 + Toast
```

---

## 9. 平台差异化交互

### 9.1 iPhone vs iPad vs Mac

| 交互 | iPhone | iPad | Mac |
|------|--------|------|-----|
| **主导航** | 悬浮 TabBar | Sidebar + TabBar | Sidebar（常驻） |
| **卡片操作** | 左滑 | 左滑 / 右键 | 右键菜单 |
| **详情打开** | 全屏 Push | 侧边 Sheet | 侧边面板（不遮挡列表） |
| **曲线交互** | 触摸拖动 | 触摸 / Pencil | 鼠标悬停自动显示 |
| **刷新** | 下拉 | 下拉 / 按钮 | 按钮 / 快捷键 ⌘R |
| **搜索** | 全屏模态 | 侧边面板 | 顶部内嵌 + ⌘F |
| **缩放** | 捏合 | 捏合 | 滚轮 + Option |

### 9.2 Mac 专属交互

#### 键盘快捷键

| 快捷键 | 功能 | 作用域 |
|--------|------|--------|
| `⌘R` | 刷新 | 全局 |
| `⌘F` | 搜索 | 全局 |
| `⌘D` | 收藏 | 详情页/卡片选中时 |
| `⌘[` 或 `Esc` | 返回/关闭 | 详情页/模态 |
| `⌘1/2/3/4` | Tab 切换 | 全局 |
| `⌘↑` | 回到顶部 | 列表页 |
| `⌘,` | 打开设置 | 全局 |
| `Space` | 快速预览 | 卡片焦点时 |
| `Enter` | 打开详情 | 卡片焦点时 |

#### 鼠标交互

| 操作 | 效果 | 动画 |
|------|------|------|
| **悬停卡片** | 3D 轻微倾斜（根据鼠标位置） | 实时跟随 |
| **悬停按钮** | 背景淡淡发光 | 0.2s 淡入 |
| **悬停曲线** | 自动显示垂直光标线 | 跟随鼠标 |
| **右键卡片** | 打开上下文菜单 | 系统默认 |
| **滚轮** | 列表滚动 | 惯性滚动 |
| **Shift + 滚轮** | 水平滚动（平台彩带） | 惯性滚动 |

---

## 10. 动画参数库

### 10.1 标准动画曲线

```swift
extension Animation {
    // 快速响应（按钮、开关）
    static let quickResponse = Animation.spring(response: 0.2, dampingFraction: 0.7)

    // 平滑过渡（页面切换、内容变化）
    static let smoothTransition = Animation.easeInOut(duration: 0.3)

    // 弹性效果（卡片、模态）
    static let elasticPop = Animation.spring(response: 0.4, dampingFraction: 0.6)

    // 柔和弹簧（展开动画）
    static let gentleSpring = Animation.spring(response: 0.5, dampingFraction: 0.8)

    // 流畅弹簧（列表重排）
    static let fluidSpring = Animation.spring(response: 0.6, dampingFraction: 0.7)

    // 特殊效果
    static let gentleBreathing = Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
    static let pulsing = Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)
}
```

### 10.2 动画时长标准

| 类型 | 时长 | 曲线 | 用途 |
|------|------|------|------|
| **Instant** | 0.1s | linear | 即时反馈、高亮 |
| **Quick** | 0.2s | easeOut | 按钮、开关、小元素 |
| **Standard** | 0.3s | easeInOut | 页面切换、内容变化 |
| **Moderate** | 0.5s | easeInOut | 卡片展开、模态出现 |
| **Slow** | 0.8s | easeInOut | 粒子效果、复杂动画 |
| **Spring** | — | spring(0.5, 0.7) | 弹性交互、物理效果 |

---

## 11. 无障碍交互支持

### 11.1 VoiceOver 手势映射

| 标准手势 | VoiceOver 替代 | 实现 |
|----------|----------------|------|
| 点击 | 双击 | `.accessibilityAction(.default)` |
| 长按 | 三指双击 | `.accessibilityAction(.magicTap)` |
| 左滑快捷操作 | 向上/下轻扫切换操作 + 双击执行 | `.accessibilityCustomActions` |
| 下拉刷新 | 两指下滑 | `.refreshable` 自动支持 |
| 捏合缩放 | 双击切换档位 | 自定义 Action |

**实现示例：**

```swift
CardView(topic: topic)
    .accessibilityLabel("热搜话题：\(topic.title)")
    .accessibilityValue("热度 \(topic.heat)，排名第 \(topic.rank)")
    .accessibilityHint("双击查看详情")
    .accessibilityAction(.default) {
        showDetail()
    }
    .accessibilityCustomActions([
        AccessibilityCustomAction(name: "收藏") {
            toggleFavorite()
            return .success
        },
        AccessibilityCustomAction(name: "分享") {
            share()
            return .success
        }
    ])
```

### 11.2 减弱动态效果模式

```swift
@Environment(\.accessibilityReduceMotion) var reduceMotion

var animation: Animation? {
    reduceMotion ? nil : .spring(response: 0.3)
}
```

**降级策略：**

| 原动画 | 替代方案 |
|--------|----------|
| 卡片展开过渡 | 简单淡入淡出（0.2s） |
| 粒子效果 | 禁用 |
| 呼吸动画 | 禁用 |
| 脉冲效果 | 静态高亮 |
| 3D 翻转 | 简单 opacity 切换 |
| 涟漪效果 | 禁用 |
| 光晕动画 | 静态圆环 |

### 11.3 触摸目标尺寸

| 元素 | 最小尺寸 | 推荐尺寸 | 间距 |
|------|----------|----------|------|
| 按钮 | 44 × 44pt | 48 × 48pt | ≥ 8pt |
| Tab 图标 | 44 × 44pt | 60 × 60pt | ≥ 24pt |
| 卡片 | 全宽 × 88pt | 全宽 × 120pt | ≥ 12pt |
| 快捷操作按钮 | 80 × 全高 | 80 × 全高 | 0pt |

---

## 12. 性能优化策略

### 12.1 动画性能

| 场景 | 优化方法 | 目标帧率 |
|------|----------|----------|
| **列表滚动** | `LazyVStack` + `.drawingGroup()` | 60 FPS |
| **复杂渐变** | 缓存 Gradient 对象 | 60 FPS |
| **粒子效果** | 最多 15 个粒子，超出裁剪 | 60 FPS |
| **3D 倾斜** | 仅当可见时计算 | 60 FPS |
| **卡片阴影** | 使用预渲染图层 | 60 FPS |

**技术实现：**

```swift
// 列表性能优化
ScrollView {
    LazyVStack(spacing: 12) {
        ForEach(items) { item in
            CardView(item)
                .id(item.id)
                .drawingGroup()  // 栅格化复杂内容
        }
    }
}
.scrollTargetLayout()

// 粒子数量限制
struct ParticleSystem {
    static let maxParticles = 15

    func emit() {
        guard activeParticles.count < Self.maxParticles else { return }
        // 发射粒子...
    }
}
```

### 12.2 手势响应优化

```swift
// 防抖搜索
@State private var searchTask: Task<Void, Never>?

func search(_ text: String) {
    searchTask?.cancel()
    searchTask = Task {
        try? await Task.sleep(for: .milliseconds(300))
        if !Task.isCancelled {
            await performSearch(text)
        }
    }
}

// 滚动性能
.onAppear {
    // 预加载下一批数据
    if isNearBottom {
        Task {
            await loadMore()
        }
    }
}
```

---

## 13. 边界情况与异常交互

### 13.1 网络异常

| 场景 | 用户操作 | 反馈 | 后续行为 |
|------|----------|------|----------|
| **刷新失败** | 下拉刷新 | Toast 提示 + 保留旧数据 | 可重试 |
| **详情加载失败** | 点击卡片 | 错误占位图 + 重试按钮 | 点击重试 |
| **图片加载失败** | 自动 | 渐变占位符 | 静默失败 |
| **搜索失败** | 输入搜索 | "网络连接失败" + 重试 | 可重试 |

### 13.2 空状态交互

| 场景 | 视觉 | 交互元素 | 引导 |
|------|------|----------|------|
| **首次打开** | 空列表插画 | "下拉刷新" 提示 | 带动画箭头 |
| **搜索无结果** | 搜索插画 | "换个关键词试试" | 历史热搜推荐 |
| **收藏为空** | 心形插画 | "收藏感兴趣的话题" | 跳转到热榜按钮 |
| **网络断开** | 断线插画 | "检查网络连接" + 重试按钮 | 点击重试 |

---

## 14. 开发实现清单

### 14.1 核心手势组件

- [ ] `SwipeableCard.swift` - 左右滑动卡片容器
- [ ] `InteractiveCurve.swift` - 可拖动的热度曲线图
- [ ] `FlipCard.swift` - 3D 翻转卡片（对比模式）
- [ ] `ElasticScrollView.swift` - 弹性滚动容器
- [ ] `PullToRefreshView.swift` - 自定义下拉刷新

### 14.2 动画修饰符

- [ ] `PulseEffect.swift` - 脉冲动画修饰符
- [ ] `RippleEffect.swift` - 涟漪效果
- [ ] `ParticleEmitter.swift` - 粒子发射器
- [ ] `GlowModifier.swift` - 发光效果
- [ ] `BreathingModifier.swift` - 呼吸动画

### 14.3 手势处理器

- [ ] `GestureManager.swift` - 手势协调管理器
- [ ] `DragGestureHandler.swift` - 统一的拖拽逻辑
- [ ] `LongPressHandler.swift` - 长按检测与预览
- [ ] `HapticManager.swift` - 触觉反馈管理器
- [ ] `MagnificationHandler.swift` - 捏合手势处理

### 14.4 交互组件

- [ ] `ContextMenuPreview.swift` - 长按预览视图
- [ ] `QuickActionButtons.swift` - 左滑快捷按钮组
- [ ] `FloatingTabBar.swift` - 悬浮玻璃 TabBar
- [ ] `PlatformRibbon.swift` - 平台彩带选择器
- [ ] `TimeRangeSelector.swift` - 时间范围选择器

---

## 15. 用户测试验证点

### 15.1 可用性测试任务

| 任务 | 预期操作 | 成功标准 | 备注 |
|------|----------|----------|------|
| 切换平台 | 点击彩带选择器 | < 2s 完成 | 观察是否理解下划线 |
| 查看详情 | 点击卡片 | 动画流畅，< 1s | 注意是否等待加载 |
| 收藏话题 | 左滑或详情页点击 | 反馈明确 | 是否发现左滑功能 |
| 对比热榜 | 切换到对比 Tab | 理解双列布局 | 是否尝试翻转卡片 |
| 刷新数据 | 下拉 | 触发刷新 | 是否理解光晕提示 |

### 15.2 性能测试指标

| 指标 | 目标值 | 测试方法 | 工具 |
|------|--------|----------|------|
| **滚动帧率** | ≥ 60 FPS | 快速滚动列表 | Instruments (Core Animation) |
| **手势响应延迟** | < 16ms | 触摸高亮时间 | 高速摄像 |
| **动画掉帧率** | < 5% | 录屏分析 | Xcode Debug Navigator |
| **内存占用** | < 150MB | 长时间使用 | Instruments (Allocations) |

---

## 16. 版本规划

### v1.0 - 基础交互（MVP）

- [x] Tab 切换（点击）
- [x] 卡片点击进入详情
- [x] 基础列表滚动
- [ ] 下拉刷新
- [ ] 简单触觉反馈
- [ ] 平台彩带切换

### v1.1 - 手势增强

- [ ] 卡片左滑快捷操作
- [ ] Tab 左右滑动切换
- [ ] 详情页向下滑动返回
- [ ] 曲线拖动交互
- [ ] 长按预览菜单

### v1.2 - 高级动效

- [ ] 粒子效果系统
- [ ] 3D 倾斜与视差
- [ ] 卡片翻转对比
- [ ] 捏合缩放曲线
- [ ] 收藏动画完善

### v2.0 - 跨平台完善

- [ ] Mac 键盘快捷键
- [ ] iPad 分屏适配
- [ ] Apple Pencil 支持
- [ ] 鼠标悬停效果
- [ ] 手表伴随体验（可选）

---

## 17. 参考文献

### Apple 官方文档

- [Human Interface Guidelines - Gestures](https://developer.apple.com/design/human-interface-guidelines/gestures)
- [Human Interface Guidelines - Animation](https://developer.apple.com/design/human-interface-guidelines/motion)
- [UIKit Dynamics](https://developer.apple.com/documentation/uikit/animation_and_haptics/uikit_dynamics)
- [Core Haptics](https://developer.apple.com/documentation/corehaptics)
- [SwiftUI Gestures](https://developer.apple.com/documentation/swiftui/gestures)

### 设计灵感来源

- **Tinder** - 卡片滑动交互
- **Clear** - 手势优先设计
- **Reeder** - 优雅的阅读交互
- **Things** - 微交互细节
- **Spark** - 左滑快捷操作
- **Flipboard** - 翻页与翻转动画

---

## 18. 附录：交互速查表

### 18.1 手势速查矩阵

| 手势 | 全局 | 列表 | 卡片 | 详情页 | 曲线 | 对比 | 设置 |
|------|:----:|:----:|:----:|:------:|:----:|:----:|:----:|
| **单击** | — | — | 展开详情 | 关闭 | — | 翻转 | 选择项 |
| **双击** | — | — | 快速收藏 | — | 重置 | 快速翻转 | — |
| **长按** | — | — | 预览菜单 | — | 锁定数据 | 锁定对比 | — |
| **左滑** | Tab切换 | — | 快捷操作 | — | — | 翻转 | 删除 |
| **右滑** | Tab切换 | — | 屏蔽 | — | — | 翻转 | 返回 |
| **上滑** | — | 滚动 | — | — | — | 切换 | 滚动 |
| **下滑** | — | 刷新 | — | 关闭 | — | 切换 | 滚动 |
| **捏合** | — | — | — | — | 缩放时间 | — | — |
| **拖拽** | — | — | 重排 | — | 光标 | — | 滑块 |

### 18.2 触觉反馈速查

| 操作 | 触觉类型 | 时机 |
|------|----------|------|
| Tab 切换 | `.selection` | 切换完成 |
| 卡片点击 | `.impact(.light)` | 按下瞬间 |
| 长按触发 | `.impact(.medium)` | 0.5s 时 |
| 收藏 | `.impact(.medium)` | 切换瞬间 |
| 刷新触发 | `.impact(.medium)` | 超过 60pt |
| 左滑展开 | `.impact(.light)` | 展开到位 |
| 屏蔽确认 | `.notification(.warning)` | 确认时 |
| 操作成功 | `.notification(.success)` | 完成时 |
| 操作失败 | `.notification(.error)` | 失败时 |

### 18.3 动画时长速查

| 场景 | 时长 | 曲线 |
|------|------|------|
| 按钮点击 | 0.2s | spring(0.2, 0.7) |
| 页面切换 | 0.3s | easeInOut |
| 卡片展开 | 0.5s | spring(0.5, 0.8) |
| 下拉刷新 | 1.5s | 分阶段 |
| 粒子效果 | 0.8s | easeOut |
| 卡片翻转 | 0.6s | spring(0.6, 0.7) |
| 详情关闭 | 0.4s | easeOut |
| 收藏动画 | 0.3s | spring(0.3, 0.6) |

---

## 19. 交互设计原则总结

### 核心理念

```
┌──────────────────────────────────────────────────────────┐
│  手势优先 > 点击为辅 > 菜单兜底                          │
│                                                          │
│  流畅自然 > 炫酷特效                                     │
│                                                          │
│  即时反馈 > 动画精美                                     │
│                                                          │
│  容错设计 > 精准操作                                     │
└──────────────────────────────────────────────────────────┘
```

### 设计检查清单

**每个交互设计必须回答：**

- [ ] 这个手势是否符合用户直觉？
- [ ] 是否有即时的视觉/触觉反馈？
- [ ] 误触后是否可以撤销？
- [ ] 动画时长是否合理（< 0.5s）？
- [ ] 是否考虑了无障碍用户？
- [ ] 性能是否达标（60 FPS）？
- [ ] 是否与系统手势冲突？
- [ ] 是否有降级方案（减弱动效）？

---

**文档状态：** ✅ 已完成
**适用范围：** iOS 26+ / iPadOS 26+ / macOS 26+
**维护者：** TrendLens 设计团队

---

*让每一次触碰都成为与热点共鸣的瞬间。*
