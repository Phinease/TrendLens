# TrendLens 数据需求文档

> **定位：** 管理全部数据类型、接口对接情况与数据表设计（持续更新的活文档）
> **配套文档：** [hot-news-data-sources-v2.md](hot-news-data-sources-v2.md) — 数据源接口规范
> **关联代码：** `TrendLens/Core/Domain/Entities/` — iOS 端实体定义
> **最后更新：** 2026-02-23

---

## 一、iOS 客户端数据字段需求

基于 `TrendTopicEntity`、`HeatDataPoint`、`Comment`、`TrendSnapshotEntity` 分析。

### 1.1 话题数据（TrendTopicEntity）

| # | 字段 | 类型 | 必须 | UI 使用位置 | 数据来源方式 | 覆盖状态 |
|---|------|------|------|-----------|------------|---------|
| 1 | `id` | String | ✅ | 列表唯一标识 | 后端生成（平台+标题哈希） | ✅ 已覆盖 |
| 2 | `platform` | Platform | ✅ | FeedView 平台筛选、PlatformIcon | 后端标记 | ✅ 已覆盖 |
| 3 | `title` | String | ✅ | HeroCard/StandardCard 标题、TopicDetailView | API 直接获取 | ✅ 全源覆盖 |
| 4 | `topicDescription` | String? | 可选 | TopicDetailView 备选内容 | API 直接 / 页面抓取 | ⚠️ 50% 源覆盖 |
| 5 | `heatValue` | Int | ✅ | HeroCard/StandardCard 热度显示、热度配色 | API 直接 / 排名估算 | ⚠️ 50% 源直接提供 |
| 6 | `rank` | Int | ✅ | HeroCard/StandardCard 排名、HeroCard 判断 | 列表索引 / API 直接 | ✅ 全源可计算 |
| 7 | `link` | String? | 可选 | TopicDetailView Safari 按钮 | API 直接 | ✅ 90% 源覆盖 |
| 8 | `tags` | [String] | 可选 | TopicDetailView 标签流式布局 | API / AI 关键词提取 | ⏳ 需实现提取 |
| 9 | `fetchedAt` | Date | ✅ | HeroCard/StandardCard 时间、DataAnalyseView | 后端采集时间戳 | ✅ 已覆盖 |
| 10 | `rankChange` | RankChange | ✅ | RankChangeIndicator（上升/下降/新/不变） | **对比前后快照计算** | ⏳ 需快照对比 |
| 11 | `heatHistory` | [HeatDataPoint] | ✅ | HeatCurveView 热度曲线、MiniTrendLine | **多次快照时间序列积累** | ⏳ 需时间积累 |
| 12 | `summary` | String | ✅ | HeroCard/StandardCard 摘要、TopicDetailView AI 摘要 | **AI 生成** | ⏳ 需 AI 服务 |
| 13 | `content` | String? | 可选 | TopicDetailView 正文区块 | 页面抓取（阶段 2） | ⏳ 需爬虫实现 |
| 14 | `imageURLs` | [String] | 可选 | TopicDetailView 图片画廊 | API / 页面抓取 | ⚠️ 30% 源覆盖 |
| 15 | `comments` | [Comment] | 可选 | TopicDetailView 评论区 | 平台评论 API | ⏳ 规划中 |
| 16 | `isFavorite` | Bool | ✅ | 收藏按钮状态 | **客户端本地存储** | ✅ 不需后端 |

### 1.2 热度数据点（HeatDataPoint）

| # | 字段 | 类型 | 必须 | 说明 | 数据来源方式 |
|---|------|------|------|------|------------|
| 1 | `id` | UUID | ✅ | 数据点标识 | 后端生成 |
| 2 | `timestamp` | Date | ✅ | 数据采集时间点 | 采集时间戳 |
| 3 | `heatValue` | Int | ✅ | 该时间点热度值 | API 热度值 |
| 4 | `rank` | Int? | 可选 | 该时间点排名 | 列表位置 |

> **关键依赖**：HeatCurveView 要求 `heatHistory.count >= 2` 才能渲染图表。
> 这意味着每个话题至少需要 **2 次以上的快照采集** 才能显示热度曲线。

### 1.3 评论（Comment）

| # | 字段 | 类型 | 必须 | 数据来源方式 |
|---|------|------|------|------------|
| 1 | `id` | String | ✅ | 平台评论 ID |
| 2 | `username` | String | ✅ | 评论者用户名 |
| 3 | `content` | String | ✅ | 评论内容 |
| 4 | `createdAt` | Date | ✅ | 评论时间 |
| 5 | `likeCount` | Int | ✅ | 点赞数 |
| 6 | `replyCount` | Int | ✅ | 回复数 |
| 7 | `avatarSymbol` | String | ✅ | 头像图标 |
| 8 | `avatarColorHex` | String | ✅ | 头像颜色 |

> **评论数据规划**：Phase 2 暂不采集评论数据，评论区使用客户端本地 Mock 数据。
> 后续可通过各平台评论 API 获取（需评估合规风险）。

### 1.4 快照（TrendSnapshotEntity）

| # | 字段 | 类型 | 必须 | 数据来源方式 |
|---|------|------|------|------------|
| 1 | `id` | String | ✅ | 后端生成（平台+时间戳） |
| 2 | `platform` | Platform | ✅ | 数据源标识 |
| 3 | `fetchedAt` | Date | ✅ | 采集时间 |
| 4 | `validUntil` | Date | ✅ | 过期时间（fetchedAt + TTL） |
| 5 | `contentHash` | String | ✅ | 话题列表哈希（去重判断） |
| 6 | `etag` | String? | 可选 | 缓存控制 |
| 7 | `schemaVersion` | Int | ✅ | 数据格式版本 |
| 8 | `topics` | [TrendTopic] | ✅ | 该快照包含的话题列表 |

---

## 二、数据类型分类

### 2.1 直接获取类（API → 直接入库）

从数据源 API 可直接获取，无需额外处理。

| 数据 | 说明 | 覆盖率 |
|------|------|--------|
| **title** | 话题标题 | 100%（所有源） |
| **link** | 原文链接 | ~90% |
| **fetchedAt** | 采集时间 | 100%（后端生成） |
| **platform** | 平台标识 | 100%（后端标记） |

### 2.2 需转换/计算类（API → 处理 → 入库）

API 提供原始数据，但需要处理后才能使用。

| 数据 | 处理方式 | 说明 |
|------|---------|------|
| **heatValue** | 归一化计算 | 不同平台热度值量级差异大（知乎 "万热度"、头条数字、B站播放量），需统一量级 |
| **rank** | 列表排序 | 多数 API 返回有序列表，取 `index + 1` |
| **description** | 文本清洗 | 去除 HTML 标签、广告文本、多余空白 |
| **imageURLs** | URL 提取 | 从 API 字段或 HTML 内容提取图片 URL |

### 2.3 积累类（需时间序列，多次快照对比）

无法从单次 API 调用获取，需要后端持续采集并对比计算。

| 数据 | 生成方式 | 最低要求 |
|------|---------|---------|
| **rankChange** | 对比当前快照与前一快照的排名差异 | 需至少 2 次快照 |
| **heatHistory** | 每次快照记录 (timestamp, heatValue, rank) 组成时间序列 | 需至少 2 个数据点（HeatCurveView 最低要求） |

> **采集策略**：
> - 建议每 15 分钟采集一次
> - 每个话题的 heatHistory 保留最近 24 小时数据（约 96 个点）
> - rankChange 仅对比最近两次快照

### 2.4 二次抓取类（需串联请求获取正文）

API 仅返回列表摘要，需跟踪链接二次请求获取完整内容。

| 数据 | 获取方式 | 覆盖率 |
|------|---------|--------|
| **content** | 跟踪 `link` → 解析目标页面正文 | 需为每个源实现专用解析器 |
| **tags**（部分） | 从目标页面提取标签/关键词 | 源页面有标签时提取 |
| **imageURLs**（补充） | 从目标页面提取图片 | 作为 API 图片的补充 |

### 2.5 AI 生成类（需 LLM 处理）

| 数据 | 生成方式 | 输入 | 说明 |
|------|---------|------|------|
| **summary** | Claude API 生成 | title + description + content | 为每条话题生成 2-3 句 AI 摘要 |
| **tags**（补充） | Claude API 提取 | title + content | 当源数据无标签时，AI 提取 3-5 个关键词 |

---

## 三、数据源覆盖矩阵

> 图例：✅ 直接获取 | ⚙️ 需计算转换 | 🔗 二次抓取 | 🤖 AI 生成 | ❌ 不可获取

### 3.1 P0 核心源

| 字段 | zhihu | baidu | weibo | bili-hs | bili-hv | douyin | toutiao |
|------|-------|-------|-------|---------|---------|--------|---------|
| title | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| heatValue | ⚙️ | ✅ | ✅ | ⚙️ | ✅ | ✅ | ✅ |
| rank | ⚙️ | ⚙️ | ⚙️ | ⚙️ | ⚙️ | ⚙️ | ⚙️ |
| description | ✅ | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| content | 🔗 | 🔗 | 🔗 | 🔗 | ✅ | 🔗/🤖 | 🔗 |
| imageURLs | ✅ | ✅ | ❌ | 🔗 | ✅ | ❌ | ✅ |
| tags | 🔗 | ❌ | ✅ | ❌ | ✅ | ✅ | ❌ |
| link | ✅ | ✅ | ✅ | ⚙️ | ⚙️ | ⚙️ | ✅ |
| summary | 🤖 | 🤖 | 🤖 | 🤖 | 🤖 | 🤖 | 🤖 |

### 3.2 P1 重要补充源

| 字段 | sina | thepaper | tencent | hackernews | 36kr | douban |
|------|------|---------|---------|-----------|------|--------|
| title | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| heatValue | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ |
| rank | ⚙️ | ⚙️ | ⚙️ | ⚙️ | ⚙️ | ⚙️ |
| description | ❌ | ❌ | ✅ | ❌ | ✅ | ✅ |
| content | 🔗 | 🔗 | 🔗 | 🔗 | 🔗 | 🔗 |
| imageURLs | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ |
| tags | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| link | ✅ | ⚙️ | ✅ | ✅ | ✅ | ⚙️ |
| summary | 🤖 | 🤖 | 🤖 | 🤖 | 🤖 | 🤖 |

### 3.3 P2 延伸覆盖源

| 字段 | wallstreetcn | cankaoxiaoxi | github | netease | tieba | ithome | kaopu |
|------|-------------|-------------|--------|---------|-------|--------|-------|
| title | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| heatValue | ❌ | ❌ | ✅ | ✅ | ❌ | ❌ | ❌ |
| description | ✅ | ❌ | ✅ | ❌ | ❌ | ❌ | ✅ |
| content | ✅ | 🔗 | ✅ | 🔗 | 🔗 | 🔗 | ✅ |
| link | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| summary | 🤖 | 🤖 | 🤖 | 🤖 | 🤖 | 🤖 | 🤖 |

---

## 四、数据缺口分析

### 4.1 当前已覆盖

| 数据类型 | 覆盖情况 | 说明 |
|---------|---------|------|
| 标题 (title) | ✅ 100% | 所有源均提供 |
| 链接 (link) | ✅ ~90% | 绝大部分源提供或可拼接 |
| 排名 (rank) | ✅ 100% | 全部可通过列表位置计算 |
| 平台标识 (platform) | ✅ 100% | 后端标记 |
| 采集时间 (fetchedAt) | ✅ 100% | 后端生成 |

### 4.2 需实现的数据管道

| 数据类型 | 当前状态 | 实现方案 | 优先级 |
|---------|---------|---------|--------|
| **热度值归一化** | 各源量级不同 | 建立归一化公式，将各平台热度映射到统一量级 | P0 |
| **正文内容** | 大部分源仅有标题 | 为每个源实现阶段 2 抓取器 | P0 |
| **AI 摘要** | 无 | Claude API 批量生成 | P0 |
| **排名变化** | 无 | 对比前后快照 rank 差异 | P1 |
| **热度历史** | 无 | 定时采集积累时间序列 | P1（自然积累） |
| **标签提取** | ~25% 源提供 | AI 关键词提取补充 | P2 |
| **图片补充** | ~30% 源提供 | 阶段 2 页面抓取补充 | P2 |
| **评论数据** | 无 | 各平台评论 API（合规风险高） | P3（暂缓） |

### 4.3 热度值归一化策略

不同平台的热度值量级差异极大：

| 平台 | 原始热度值示例 | 单位 |
|------|-------------|------|
| 知乎 | "2345 万热度" | 万 |
| 百度 | 4853291 | 搜索指数 |
| 微博 | 2345678 | 热搜指数 |
| 今日头条 | 1234567 | HotValue |
| B站播放量 | 5000000 | 播放次数 |
| Hacker News | 342 | 评分 |

**归一化方案（待定）**：
- 方案 A：各平台独立排名，热度值 = f(rank)，统一映射到 0-10000000 区间
- 方案 B：各平台热度值独立归一化到 0-100，再按统一公式转换
- 方案 C：保留原始值，iOS 端按平台分别处理显示逻辑

> 此决策将在数据库建模阶段确定。

---

## 五、数据管道流程

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Fetcher    │     │   Scraper    │     │  Processor   │
│  (阶段 1)    │────→│  (阶段 2)    │────→│  (后处理)    │
│ 热榜列表 API  │     │ 正文页面抓取  │     │ 归一化/AI    │
└──────────────┘     └──────────────┘     └──────────────┘
                                                │
                                                ▼
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Differ     │     │   Storage    │     │  Snapshot    │
│  (对比计算)   │←────│  (Supabase)  │←────│  (快照打包)  │
│ rankChange   │     │  PostgreSQL  │     │ 聚合话题+元数据│
│ heatHistory  │     │              │     │              │
└──────────────┘     └──────────────┘     └──────────────┘
```

### 管道各阶段职责

| 阶段 | 输入 | 输出 | 说明 |
|------|------|------|------|
| **Fetcher** | 数据源 API URL | 原始话题列表 (title, heat, link...) | 每 15 分钟执行 |
| **Scraper** | 话题 link URL | 正文内容、补充图片、标签 | 对每条话题执行 |
| **Processor** | 原始数据 | 归一化热度值、AI 摘要、提取标签 | 批量处理 |
| **Snapshot** | 处理后的话题列表 | TrendSnapshot（含元数据） | 打包成快照 |
| **Storage** | TrendSnapshot | Supabase 数据库记录 | 持久化 |
| **Differ** | 当前快照 + 历史快照 | rankChange、heatHistory 更新 | 查询上一快照对比 |

---

## 六、数据表管理（规划中）

> **说明**：数据库建模将在数据源补充完成后统一进行。以下为初步规划框架。

### 6.1 预期表结构概览

| 表名（暂定） | 用途 | 主要字段 |
|-------------|------|---------|
| `snapshots` | 快照记录 | id, platform, fetched_at, valid_until, content_hash, etag |
| `topics` | 话题主体 | id, snapshot_id, platform, title, heat_value, rank, link |
| `topic_content` | 话题内容（分表） | topic_id, description, content, summary, image_urls, tags |
| `heat_history` | 热度时间序列 | topic_id, timestamp, heat_value, rank |
| `platforms` | 平台配置 | id, name, display_name, fetch_interval, enabled |

### 6.2 待确认事项

- [ ] 热度值归一化方案选定
- [ ] 话题去重策略（同一话题跨快照的识别方式）
- [ ] 历史数据保留策略（保留多少天的 heat_history）
- [ ] 是否需要分表存储不同平台的话题
- [ ] 评论数据是否独立表存储

---

## 七、文档更新日志

| 日期 | 更新内容 |
|------|---------|
| 2026-02-23 | 初版创建：iOS 数据字段需求、数据类型分类、覆盖矩阵、管道设计 |
