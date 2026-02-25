# TrendLens 开发进展

> **文档定位：** 当前开发进度与任务追踪（唯一权威来源）
> **阶段定义参考：** [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md) 第 7 章
>
> **当前阶段：** 阶段 2 - 后端数据采集 + 远程数据集成
> **最后更新：** 2026-02-23

---

## 已完成阶段

### 阶段 0：项目基建 ✅（2026-01-21）

Clean Architecture 目录结构、依赖注入容器、Domain/Data/Infrastructure 三层架构、基础导航结构（iPhone TabView / iPad+macOS NavigationSplitView）、炫酷启动页。

### 阶段 0.5：UI 设计深化 ✅（2026-01-22）

Prismatic Flow 设计系统（平台渐变色带、热度光谱、3D 阴影层级）、UI 组件库 14 个组件、热度曲线功能（HeatCurveView、HeatCurveMini、触摸交互）、Feed 页面完整 UI。

### 阶段 1：MVP（本地 SwiftData + Mock 数据）✅（2026-01-23）

MockDataGenerator 动态数据生成（6 平台各 15 条话题）、FeedView/CompareView/SearchView/SettingsView 完整实现、下拉刷新/收藏/屏蔽词过滤。

**技术要点**：SwiftData Predicate 不捕获外部变量（改用内存过滤）、`@MainActor` 隔离、`isRemoteEnabled = false` 配置。

### 阶段 1.5：UI 系统重构（Ethereal Insight）✅（2026-01-24 ~ 2026-02-18）

| Phase | 核心交付 | 完成 |
|-------|---------|------|
| 1.5.1 | DesignSystem 重构、原子级组件库（PlatformIcon、RankChangeIndicator、MiniTrendLine、StandardCard） | ✅ |
| 1.5.2 | HeroCard 实现、FeedView 重构为 Hero+Standard 混合布局 | ✅ |
| 1.5.3 | 官方 TabView + FluidRibbon 集成，平台切换流畅 | ✅ |
| 1.5.4 | CompareView/SearchView 响应式布局（iPad 2列 LazyVGrid）、状态组件（EmptyState/Skeleton/Error） | ✅ |
| 1.5.5 | 卡片交互（缩放反馈、滑动操作、长按菜单）、FluidRibbon 优化（滑动切换、触觉反馈） | ✅ |
| 1.5.6 | TopicDetailView（新闻内容）+ DataAnalyseView（热度数据）分离、卡片导航按钮 | ✅ |
| 1.5.7 | 三端验证与文档更新 | ⏸️ 延后 |

> **1.5.7 延后说明**：深色模式走查、动态字体测试、VoiceOver 测试等验收工作延后至阶段 6（质量与发布）阶段统一执行。三端编译已在各 Phase 中持续验证通过。

---

## 当前阶段

### 阶段 2：后端数据采集 + 远程数据集成 🚧

**目标**：建立 Python 后端数据采集系统，通过 Supabase 存储数据，iOS 应用连接远程数据源替换本地 Mock 数据。

**设计文档**：
- 数据源选型：[backend/docs/hot-news-data-sources-v2.md](backend/docs/hot-news-data-sources-v2.md)
- 数据需求：[backend/docs/data-requirements.md](backend/docs/data-requirements.md)
- 全量调研：[backend/docs/data-sources-v1.md](backend/docs/data-sources-v1.md)

**技术栈**：Python 后端 + Supabase (PostgreSQL) + Supabase Data API

**Supabase 配置**：
- Project: TrendLens
- 已启用 Data API（RESTful，用于 iOS 端 supabase-swift 连接）

---

#### 2.1 数据源补充与接口验证 🚧

**目标**：完善 hot-news-data-sources-v2.md，验证所有选定接口的可用性和数据完整度

- [ ] **2.1.1 P0 核心源接口验证**（7 源 / 8 端点）
  - [ ] zhihu — 知乎热榜列表 + 答案内容抓取
  - [ ] baidu — 百度热搜列表 + 描述
  - [ ] weibo — 微博热搜列表 + 搜索结果抓取（Cookie 维护方案）
  - [ ] bilibili-hot-search — B 站热搜 + 搜索扩展
  - [ ] bilibili-hot-video — B 站热门视频（API 全量）
  - [ ] douyin — 抖音热搜（Client Token 获取验证）
  - [ ] toutiao — 今日头条热榜 + 文章抓取
- [ ] **2.1.2 P1 补充源接口验证**（6 源）
  - [ ] sina-news, thepaper, tencent-hot, hackernews, 36kr-renqi, douban
- [ ] **2.1.3 P2 延伸源接口验证**（7 源）
  - [ ] wallstreetcn, cankaoxiaoxi, github-trending, netease-news, tieba, ithome, kaopu
- [ ] **2.1.4 补充缺失的数据源**
  - [ ] 评估是否需要新增平台以覆盖数据需求缺口
  - [ ] 更新 data-requirements.md 覆盖矩阵

---

#### 2.2 数据库建模

**目标**：基于 data-requirements.md 设计 Supabase 数据表

- [ ] **2.2.1 确定热度值归一化方案**
- [ ] **2.2.2 设计数据表结构**
  - [ ] snapshots 表（快照记录）
  - [ ] topics 表（话题主体）
  - [ ] topic_content 表（话题内容，分表）
  - [ ] heat_history 表（热度时间序列）
  - [ ] platforms 表（平台配置）
- [ ] **2.2.3 在 Supabase 中创建表和索引**
- [ ] **2.2.4 配置 Row Level Security (RLS)**
- [ ] **2.2.5 更新 data-requirements.md 第六章**

---

#### 2.3 Python 后端开发

**目标**：实现数据采集管道，定时抓取热榜数据存入 Supabase

- [ ] **2.3.1 后端项目初始化**
  - [ ] Python 项目结构（src/fetchers, src/scrapers, src/processors, src/storage）
  - [ ] 依赖管理（requirements.txt / pyproject.toml）
  - [ ] 配置管理（环境变量、数据源配置）
  - [ ] 日志系统
- [ ] **2.3.2 阶段 1 采集器（Fetcher）**
  - [ ] 通用 HTTP 客户端（重试、超时、User-Agent 轮换）
  - [ ] P0 核心源采集器（7 个）
  - [ ] 响应解析器（JSON / HTML / 内嵌 JSON）
- [ ] **2.3.3 阶段 2 正文抓取器（Scraper）**
  - [ ] 通用正文提取器（基于 readability / newspaper3k）
  - [ ] 各源专用页面解析器
  - [ ] 图片 URL 提取
- [ ] **2.3.4 数据处理器（Processor）**
  - [ ] 热度值归一化
  - [ ] AI 摘要生成（Claude API 集成）
  - [ ] 关键词/标签提取
  - [ ] 数据清洗（去 HTML、去广告、去重）
- [ ] **2.3.5 快照与存储**
  - [ ] 快照打包（聚合话题 + 元数据）
  - [ ] Supabase 写入（supabase-py）
  - [ ] 快照对比（rankChange 计算）
  - [ ] 热度历史追加（heatHistory 累积）
- [ ] **2.3.6 调度系统**
  - [ ] 定时任务（每 15 分钟采集一次）
  - [ ] 错误处理与重试策略
  - [ ] 采集状态监控
- [ ] **2.3.7 P1/P2 源扩展**
  - [ ] 实现 P1 源（6 个）
  - [ ] 实现 P2 源（7 个）
  - [ ] 数据质量验证

---

#### 2.4 iOS 远程数据层

**目标**：iOS 应用连接 Supabase 获取真实数据，替换本地 Mock

- [ ] **2.4.1 Supabase Swift SDK 集成**
  - [ ] 添加 supabase-swift 依赖
  - [ ] 配置 Supabase Client（URL + anon key）
- [ ] **2.4.2 RemoteDataSource 实现**
  - [ ] 实现 `RemoteTrendingDataSource`（基于 Supabase API）
  - [ ] 数据模型映射（Supabase JSON → TrendTopicEntity）
  - [ ] 平台枚举更新（根据实际可用数据源调整）
- [ ] **2.4.3 缓存与离线策略**
  - [ ] ETag 支持（304 响应处理）
  - [ ] 本地 SwiftData 缓存（validUntil TTL）
  - [ ] 离线模式降级（使用过期缓存 + 标记）
- [ ] **2.4.4 数据刷新**
  - [ ] 手动下拉刷新触发网络请求
  - [ ] 自动刷新间隔（配合 validUntil）
  - [ ] 多平台并行请求（TaskGroup）
- [ ] **2.4.5 端到端验证**
  - [ ] 后端采集 → Supabase 存储 → iOS 读取 → UI 展示
  - [ ] 三端编译验证（iPhone/iPad/Mac）
  - [ ] 错误处理与降级测试

---

#### 2.5 平台枚举调整

**目标**：根据实际数据源可用性更新 iOS 端 Platform 枚举

> **当前状态**：iOS 端有 6 个平台（weibo/xiaohongshu/bilibili/douyin/x/zhihu），其中小红书和 X 无可靠数据源。
> 此任务在后端核心功能稳定后再执行。

- [ ] **2.5.1 确定最终平台列表**
- [ ] **2.5.2 更新 Platform.swift 枚举**
- [ ] **2.5.3 更新 UI 组件中的平台引用**
- [ ] **2.5.4 三端编译验证**

---

## ⚠️ 重要开发原则

**阶段 2 开发原则：**

1. **后端先行**：先完成后端数据采集，确认数据质量，再对接 iOS 端
2. **逐源验证**：每实现一个数据源，立即验证数据完整性和正确性
3. **数据优先于 UI**：先确保数据管道稳定，UI 调整随后进行
4. **保持 Mock 兼容**：iOS 端保留 Mock 数据能力，方便开发调试

**编译要求**

```bash
# iOS Simulator
xcodebuild -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# iPad Simulator
xcodebuild -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'

# macOS
xcodebuild -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=macOS'
```

---

## 未来阶段

### 阶段 3：后台刷新 + 通知

- BGTaskScheduler 集成
- 本地通知（热点突发提醒、收藏话题更新）
- 电量和流量优化

### 阶段 5：用户体系（可选）

- BaaS 选型和集成
- 云端偏好同步（收藏、屏蔽词、订阅平台）
- 匿名用户迁移
- 隐私和安全

### 阶段 6：质量与发布

- 单元测试（Domain 90%, Data 80%, Presentation 75%）
- UI 测试
- 性能优化（启动 < 2s, 列表 60fps）
- 深色模式走查、动态字体、VoiceOver（原 Phase 1.5.7 内容）
- 隐私合规
- 发布准备（App Store 提交）

---

## 术语参考

所有项目术语定义见 [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md) 第 10 章。
