# Trends 功能设计

> **文档定位：** 趋势页面功能设计规范
> **创建日期：** 2026-03-29
> **关联文档：** [Database Schema.md](TrendLens%20Database%20Schema.md)（§2.7-2.9）、[Backend Architecture.md](TrendLens%20Backend%20Architecture.md)（§5.8）

---

## 1. 功能定位

Trends 是与热榜（Feed）、对比（Compare）平行的**核心功能页面**，展示 Google Trends 时序数据驱动的趋势洞察。

| 维度 | 热榜 (Feed) | 对比 (Compare) | 趋势 (Trends) |
|------|------------|----------------|--------------|
| **数据源** | 各平台实时热搜 | 跨平台交叉分析 | Google Trends 时序数据 |
| **时间维度** | 当前快照 | 当前快照对比 | 7 天时序曲线 |
| **核心价值** | "现在什么火" | "各平台差异" | "趋势怎么变" |
| **用户行为** | 浏览扫描 | 选择对比 | 探索趋势 + 跳转关联新闻 |

---

## 2. 信息架构

```
趋势 Tab
├── 趋势关键词列表（按热度排序）
│   ├── 关键词卡片
│   │   ├── 关键词文本
│   │   ├── 迷你趋势曲线（7天）
│   │   ├── 当前趋势值（0-100）
│   │   ├── 趋势方向指示（↑↓→）
│   │   └── 关联话题数量
│   └── 点击 → 趋势详情页
│
└── 趋势详情页
    ├── 关键词 + 元信息（数据源、分辨率、查询时间）
    ├── 完整趋势曲线（可交互，7天）
    ├── 关联话题列表（按相关度排序）
    │   └── StandardCard → 点击跳转 TopicDetailView
    └── 关键词统计（命中率、活跃状态）
```

---

## 3. 页面设计

### 3.1 趋势列表页 (TrendsView)

**导航位置：** 主 TabView 第三个 Tab（热榜 → 对比 → 趋势 → 搜索 → 设置）

**Tab 图标：** `chart.line.uptrend.xyaxis`

**页面结构：**

```
┌──────────────────────────────────────────┐
│  趋势                    [排序] [筛选]    │  ← 导航栏
├──────────────────────────────────────────┤
│  🔥 热门趋势关键词                        │  ← Section Header
├──────────────────────────────────────────┤
│ ┌──────────────────────────────────────┐ │
│ │  美杜莎三千年      ↑ 92    📰 5      │ │  ← TrendKeywordCard
│ │  ╭─────╮                             │ │     迷你曲线 + 值 + 关联数
│ │  │ ╱╲╱ │                             │ │
│ │  ╰─────╯                             │ │
│ └──────────────────────────────────────┘ │
│ ┌──────────────────────────────────────┐ │
│ │  石家庄马拉松      → 67    📰 3      │ │
│ │  ╭─────╮                             │ │
│ │  │  ╱╲ │                             │ │
│ │  ╰─────╯                             │ │
│ └──────────────────────────────────────┘ │
│                  ...                     │
└──────────────────────────────────────────┘
```

**排序选项：**
- 趋势值（默认，当前值降序）
- 涨幅（趋势变化最大的优先）
- 关联数（关联话题最多的优先）

**数据来源：**
- Supabase `trend_keywords` 表（`is_active=true, no_trend_data=false`）
- Supabase `trend_data` 表（最新时序数据）
- Supabase `topic_trend_links` 表（关联话题计数）

### 3.2 趋势关键词卡片 (TrendKeywordCard)

**布局：**

```
┌─────────────────────────────────────────────┐
│                                             │
│  关键词文本                    ↑ 趋势值      │
│                                             │
│  ╭──────────────────╮   📰 N 个关联话题     │
│  │   迷你趋势曲线    │   数据源 · 更新时间   │
│  ╰──────────────────╯                       │
│                                             │
└─────────────────────────────────────────────┘
```

**组件：**
- 关键词文本：`.headline` 字重
- 迷你趋势曲线：复用 `MiniTrendLine`（宽 120pt × 高 36pt）
- 趋势值：0-100，使用热度色谱映射颜色
- 趋势方向：基于 `HeatDataPoint.trend` 计算
- 关联话题数：从 `topic_trend_links` 计数
- 玻璃卡片：`.glassEffect(.regular)`

### 3.3 趋势详情页 (TrendDetailView)

**页面结构：**

```
┌──────────────────────────────────────────┐
│  ← 返回          趋势详情                │
├──────────────────────────────────────────┤
│                                          │
│  关键词文本                              │
│  Google Trends · hourly · 全球           │
│  最后查询：3小时前                        │
│                                          │
├──────────────────────────────────────────┤
│  ┌────────────────────────────────────┐  │
│  │                                    │  │
│  │       完整趋势曲线（300pt 高）      │  │  ← HeatCurveView
│  │       可拖动查看数据点              │  │
│  │                                    │  │
│  └────────────────────────────────────┘  │
├──────────────────────────────────────────┤
│  关联话题 (N)                            │
├──────────────────────────────────────────┤
│  ┌────────────────────────────────────┐  │
│  │  StandardCard (关联话题 1)         │  │  ← 可点击跳转
│  └────────────────────────────────────┘  │
│  ┌────────────────────────────────────┐  │
│  │  StandardCard (关联话题 2)         │  │
│  └────────────────────────────────────┘  │
│                  ...                     │
└──────────────────────────────────────────┘
```

**数据加载：**
1. 趋势曲线：`trend_data` 表的 `timestamps[]` + `trend_values[]`
2. 关联话题：通过 `topic_trend_links` JOIN `topics` 获取

---

## 4. 数据流设计

### 4.1 Clean Architecture 层次

```
TrendsView / TrendDetailView
    ↓
TrendsViewModel
    ↓
FetchTrendsUseCase
    ↓
TrendRepository (protocol)
    ↓
TrendRepositoryImpl
    ↓
RemoteTrendingDataSource（新增方法）
    ↓
Supabase (trend_keywords + trend_data + topic_trend_links)
```

### 4.2 新增 Domain 实体

```swift
/// 趋势关键词
struct TrendKeywordEntity: Identifiable, Sendable {
    let id: String              // keyword_id
    let keyword: String
    let language: String
    let isActive: Bool
    let lastQueriedAt: Date?
    let queryHitRate: Double
    let latestTrendValue: Int?  // 最新趋势值（从 trend_data 取最后一个）
    let trendDirection: TrendDirection
    let linkedTopicCount: Int   // 关联话题数
    let trendPoints: [HeatDataPoint]  // 7天时序数据
}

enum TrendDirection: Sendable {
    case rising
    case falling
    case stable
}
```

### 4.3 新增 Supabase 查询

需要新增一个 RPC 或组合查询：

```sql
-- 获取活跃关键词 + 最新趋势数据 + 关联话题计数
SELECT
    tk.keyword_id,
    tk.keyword,
    tk.language,
    tk.last_queried_at,
    tk.query_hit_rate,
    td.timestamps,
    td.trend_values,
    td.queried_at,
    (SELECT COUNT(*) FROM topic_trend_links ttl
     WHERE ttl.keyword_id = tk.keyword_id) AS linked_topic_count
FROM trend_keywords tk
LEFT JOIN trend_data td ON td.keyword_id = tk.keyword_id
    AND td.data_source = 'google_trends'
    AND td.resolution = 'hourly'
WHERE tk.is_active = TRUE
    AND tk.no_trend_data = FALSE
ORDER BY td.queried_at DESC NULLS LAST;
```

### 4.4 关联话题查询

趋势详情页获取关联话题：

```sql
-- 通过 keyword_id 获取关联的 on-list 话题
SELECT t.*, ttl.relevance
FROM topic_trend_links ttl
JOIN topics t ON t.topic_key = ttl.topic_key
WHERE ttl.keyword_id = :keyword_id
    AND t.is_on_list = TRUE
ORDER BY ttl.relevance DESC, t.heat_value DESC;
```

---

## 5. 组件复用

| 组件 | 来源 | 用途 |
|------|------|------|
| `MiniTrendLine` | 已有 | 趋势关键词卡片中的迷你曲线 |
| `HeatCurveView` | 已有 | 趋势详情页完整曲线 |
| `StandardCard` | 已有 | 关联话题列表中的话题卡片 |
| `HeatDataPoint` | 已有 | 趋势时序数据点 |
| `FluidRibbon` | 已有 | 可选：排序/筛选选择器 |

---

## 6. 新增文件清单

| 文件 | 层级 | 职责 |
|------|------|------|
| `TrendKeywordEntity.swift` | Domain/Entities | 趋势关键词实体 |
| `TrendRepository.swift` | Domain/Repositories | 趋势仓库协议 |
| `FetchTrendsUseCase.swift` | Domain/UseCases | 获取趋势数据用例 |
| `TrendRepositoryImpl.swift` | Data/Repositories | 趋势仓库实现 |
| `TrendsViewModel.swift` | Features/Trends/ViewModels | 趋势页 ViewModel |
| `TrendsView.swift` | Features/Trends/Views | 趋势列表页 |
| `TrendDetailView.swift` | Features/Trends/Views | 趋势详情页 |
| `TrendKeywordCard.swift` | UIComponents/Cards | 趋势关键词卡片 |

---

## 7. 导航变更

### MainNavigationView Tab 顺序

| 位置 | 旧 | 新 |
|------|----|----|
| Tab 1 | 热榜 (flame) | 热榜 (flame) |
| Tab 2 | 对比 (chart.bar.xaxis) | 对比 (chart.bar.xaxis) |
| Tab 3 | 搜索 (magnifyingglass) | **趋势 (chart.line.uptrend.xyaxis)** |
| Tab 4 | 设置 (gear) | 搜索 (magnifyingglass) |
| Tab 5 | — | 设置 (gear) |

### NavigationTab enum 变更

```swift
enum NavigationTab: String, CaseIterable {
    case feed
    case compare
    case trends    // 新增
    case search
    case settings
}
```

---

## 8. 用户故事

### 普通用户
> "打开趋势页，看到按热度排序的关键词列表，一眼就能看到哪些词在上升趋势。点击感兴趣的关键词，看到完整的 7 天曲线，下方还有关联的新闻话题，点击就能看详情。"

### 媒体从业者
> "每天早上打开趋势页，查看哪些关键词在过去 24 小时内趋势上升最快。通过关联话题功能，快速找到各个平台对同一事件的报道差异，辅助选题决策。"

---

## 9. 实现优先级

| 优先级 | 任务 | 依赖 |
|--------|------|------|
| P0 | 新增 Supabase RPC（获取关键词列表 + 趋势数据） | 后端 |
| P0 | Domain 实体 + Repository 协议 | 无 |
| P0 | TrendsView 列表页 + TrendKeywordCard | Domain |
| P1 | TrendDetailView 详情页 | TrendsView |
| P1 | 关联话题查询 + StandardCard 跳转 | TrendDetailView |
| P2 | 排序/筛选功能 | TrendsView |
| P2 | MainNavigationView Tab 集成 | TrendsView |
