# TrendLens 开发进展

> **文档定位：** 当前开发进度与任务追踪（唯一权威来源）
> **阶段定义参考：** [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md) 第 7 章
>
> **当前阶段：** 阶段 2.6 完成 + 2.7-2.9 iOS 端优化
> **最后更新：** 2026-03-30

---

## 已完成阶段

| 阶段 | 完成日期 | 核心交付 |
|------|---------|---------|
| **0 项目基建** | 2026-01-21 | Clean Architecture 三层架构、依赖注入、三端导航、启动页 |
| **0.5 UI 设计深化** | 2026-01-22 | Prismatic Flow 设计系统、14 个 UI 组件、热度曲线 |
| **1 MVP** | 2026-01-23 | Mock 数据生成、Feed/Compare/Search/Settings 完整实现 |
| **1.5 UI 重构** | 2026-01-24 ~ 02-18 | Ethereal Insight 设计语言、HeroCard、FluidRibbon、TopicDetail/DataAnalyse 分离（1.5.7 验收延后至阶段 6） |

---

## 当前阶段

### 阶段 2：后端数据采集 + 远程数据集成 🚧

**目标**：建立 Python 后端数据采集系统，通过 Supabase 存储数据，iOS 应用连接远程数据源替换本地 Mock 数据。

**设计文档**：
- 数据源选型：[TrendLens Data Sources.md](TrendLens%20Data%20Sources.md)
- 数据需求：[TrendLens Data Requirements.md](TrendLens%20Data%20Requirements.md)
- 数据存储策略：[TrendLens Data Storage Strategy.md](TrendLens%20Data%20Storage%20Strategy.md)
- 全量调研：[TrendLens Data Sources v1 (Archive).md](TrendLens%20Data%20Sources%20v1%20(Archive).md)

**技术栈**：Python 后端 + Supabase (PostgreSQL + pgvector) + Jina Embeddings v3 + Supabase Data API

**Supabase 配置**：
- Project: TrendLens
- 已启用 Data API（RESTful，用于 iOS 端 supabase-swift 连接）

---

#### 2.1 数据源接口验证

- [x] **2.1.1 P0 核心源**（7 源）✅ — 全部验证通过，详见 [TrendLens Data Sources.md](TrendLens%20Data%20Sources.md)
- [ ] **2.1.2 P1 补充源**（6 源）— sina-news, thepaper, tencent-hot, hackernews, 36kr-renqi, douban
- [ ] **2.1.3 P2 延伸源**（7 源）— wallstreetcn, cankaoxiaoxi, github-trending, netease-news, tieba, ithome, kaopu
- [ ] **2.1.4 补充缺失的数据源**

---

#### 2.2 数据库建模 ✅

6 张核心表 + 3 张趋势表 + pgvector HNSW 索引 + RLS + 20 平台种子数据。详见 [TrendLens Data Storage Strategy.md](TrendLens%20Data%20Storage%20Strategy.md)。

> ~~2.2.6 pg_cron~~ — 免费版不支持，改由 Python 后端调度器执行。

---

#### 2.3 Python 后端开发

**代码位置**：`backend/src/trendlens/`（45+ Python 源文件，7 个包）
**技术栈**：uv + Python 3.12+ / httpx / structlog / jieba / Jina Embeddings / Supabase PostgREST
**详细架构**：[TrendLens Backend Architecture.md](TrendLens%20Backend%20Architecture.md)

| 子任务 | 状态 | 摘要 |
|--------|------|------|
| 2.3.1 项目初始化 | ✅ | uv 项目、配置管理、日志系统、CLI 入口、数据模型 |
| 2.3.2 采集器基础设施 | ✅ | BaseFetcher ABC + 自动注册、httpx HTTP/2 + SOCKS、tenacity 重试 |
| 2.3.3 P0 核心源采集器 | ✅ | 7/7 平台全部验证通过（zhihu/baidu/bilibili-hs/bilibili-hv/toutiao/weibo/douyin） |
| 2.3.4 数据处理管道 | ✅ | topic_key 三级降级、热度排名映射、jieba 实体提取、Jina 批量嵌入 |
| 2.3.5 存储层 | ✅ | PostgREST 客户端 + 6 个 store 模块（topics/heat/embedding/cluster/snapshot/maintenance） |
| 2.3.6 匹配算法 | ✅ | 三信号融合（实体 Jaccard 0.3 + 向量余弦 0.7）+ Union-Find 聚类 |
| 2.3.7 编排器 + 调度器 | ✅ | 11 步完整管道、APScheduler 15 分钟周期、Semaphore=5 并发控制 |
| 2.3.8 数据源修复 | ✅ | weibo/douyin 改用 xxapi.cn 免登录 API |
| 2.3.9 内容抓取 | ✅ | 7 平台 Scraper（5 实现 + weibo/douyin Stub）、Semaphore=10 并发 |
| 2.3.10 质量过滤 | ✅ | LLM 编号过滤法 + content=description 去重 |
| 2.3.11 热力数据采集 | ✅ | LLM 关键词提取 → Google Trends → 趋势管道 60 分钟周期 |
| 2.3.12 Tag 补充 | ✅ | LLM 15 类分类 + merge_tags 合并算法 |

| 2.3.13 趋势关键词退役机制 | ✅ | `query_miss_streak` + `no_trend_data` 列、稀疏数据过滤（≤3 点）、网络错误 vs 确认无数据精确区分 |
| 2.3.14 调度器优化 | ✅ | `serve` 启动时立即执行 trend cycle（不等 60 分钟） |
| 2.3.15 文档统一管理 | ✅ | `backend/docs/` 合并至 `TrendLensDocs/`、修复全部交叉引用、SSOT 整改 |

- [ ] **2.3.16 向量嵌入存储验证** ⏸️ 延后 — pgvector 支持确认、持久化验证、RPC 函数部署
- [ ] **2.3.17 P1/P2 源扩展** ⏸️ 延后 — P1（6 源）+ P2（7 源）实现与数据质量验证

---

#### 2.4 iOS 远程数据层 ✅ + 2.5 平台枚举调整 ✅

**完成日期**：2026-03-06

**交付内容**：
- supabase-swift 2.x SPM 依赖集成
- Secrets.xcconfig 配置（gitignored）+ Info.plist 注入
- Platform 枚举更新：6 → 7 平台（weibo/zhihu/baidu/bilibili-hs/bilibili-hv/douyin/toutiao），移除 xiaohongshu/x/bilibili
- RemoteTrendingDataSource 完全重写（Supabase SDK 查询，5 个方法）
- DTO 层（SupabaseTopicDTO/RankChangeDTO/SupabaseHeatHistoryDTO）
- TrendingRepositoryImpl：isRemoteEnabled=true、TTL 缓存、网络失败降级、搜索直连 Supabase、热度历史懒加载
- DependencyContainer：移除 NetworkClient/refreshAllData、SwiftData schema reset 容错
- MockDataGenerator：更新为 7 平台模板（开发/测试后备）
- DesignSystem：PlatformGradient + PlatformColor 全部更新
- 三端编译通过（iPhone 17 Pro / iPad Pro 13" M5 / macOS signing-only issue）

- [x] **2.4.1 Supabase Swift SDK 集成** ✅
- [x] **2.4.2 RemoteDataSource 实现** ✅
- [x] **2.4.3 缓存与离线策略** ✅ — TTL 15min，网络失败返回过期缓存
- [x] **2.4.4 数据刷新** ✅ — 下拉刷新 forceRefresh、TaskGroup 并行
- [x] **2.4.5 端到端验证** ✅ (2026-03-13) — 模拟器连通 Supabase，数据流通确认

**2.4.5 修复内容**：
- 修复 Supabase URL 双重 `https://` 拼接问题（SupabaseConfig.swift 移除多余前缀）
- 更新 Supabase API Key（旧 JWT → 新 `sb_publishable_` 格式）
- 修复 DTO snake_case 映射（SupabaseTopicDTO/SupabaseHeatHistoryDTO 添加 CodingKeys）
- 清理 14 个编译警告：
  - Comment.swift: 4x `nonisolated(unsafe)` → `nonisolated static let`
  - SupabaseConfig.swift: 1x `nonisolated(unsafe)` → `nonisolated let`
  - TrendingRepositoryImpl.swift: 9x 多余 `await` 移除（LocalDataSource 方法为同步）
  - RankChange: 提取到独立文件，与 `@Model` 上下文解耦

---

#### 2.6 趋势页面（Trends Feature）🚧

**设计文档**：[TrendLens Trends Feature Design.md](TrendLens%20Trends%20Feature%20Design.md)

**目标**：将 Google Trends 时序数据以独立核心页面呈现，与热榜、对比平行。

- [x] **2.6.1 Domain 层** ✅ — TrendKeywordEntity、TrendRepository 协议、FetchTrendsUseCase
- [x] **2.6.2 Data 层** ✅ — TrendRepositoryImpl、RemoteTrendingDataSource 新增 4 DTO + 2 方法（直接查表，未用 RPC）
- [x] **2.6.3 TrendsView** ✅ — 趋势关键词列表页 + TrendKeywordCard（Liquid Glass）+ 排序选择器
- [x] **2.6.4 TrendDetailView** ✅ — 趋势详情页（专用 Chart 0-100 值域 + 关联话题 + 跳转 TopicDetailView）
- [x] **2.6.5 导航集成** ✅ — MainNavigationView 新增趋势 Tab（5 Tab：热榜→对比→趋势→搜索→设置）
- [ ] **2.6.6 打磨** — 待优化：Supabase RPC 替代多次查表、关联话题 `is_on_list` 过滤策略、趋势曲线交互拖动

---

#### 2.7 iOS 端优化（2026-03-29）✅

**交付内容**：
- Liquid Glass 全局适配（FluidRibbon、HeroCard、StandardCard、SearchView、CompareView、SplashView）
- Tab API 升级 + horizontalSizeClass 适配
- sensoryFeedback 替换 UIKit 触觉（6 处）
- ShareLink 替换 UIActivityViewController（3 处）
- FeedView 重构（506→175 行）：onTapGesture→Button、displayedTopics 缓存、移除冲突手势
- TopicDetailView 重构（675→340 行）：CommentRow/FlowLayout 提取、Dynamic Type、Text format API
- 启动速度优化：合并双 ModelContainer、DependencyContainer 延迟配置、并行预加载
- Bug 修复：HeroCard 背景溢出、MiniTrendLine 灰块、详情页内容闪现
- AppLog 日志系统建立（替换全部 print，7 分类 Logger）

#### 2.8 AppLog 日志系统（2026-03-30）✅

- 新增 `Core/Infrastructure/Logging/AppLog.swift`（7 分类 + timed 计时）
- 替换 6 个文件中全部 `print()` 为结构化 `AppLog` 日志
- 格式统一：`操作 状态 key=value`
- 协作指南文档：[iOS Debug Collaboration Guide.md](TrendLens%20iOS%20Debug%20Collaboration%20Guide.md)

#### 2.9 启动修复 + Splash 改造（2026-03-30）✅

**启动崩溃修复：**
- SwiftData 旧数据含已删除的 `xiaohongshu` Platform 枚举值 → 解码时 `try!` 崩溃
- 修复：TrendLensApp 添加 schema 版本号（v2），版本不匹配时自动清理旧 store 重建
- Info.plist 添加 `UILaunchScreen` 配置（AccentColor 背景），消除 pre-main 黑屏

**Splash 改造：**
- 去除 AI slop 风格（粉紫蓝渐变、旋转光环、发光球、GeometryReader、渐变文字）
- 新设计：中性灰背景 + 玻璃蜂鸟 Icon（SplashLogo Image Set）+ 品牌名依次淡入
- 支持深色模式自适应、Reduce Motion 无障碍
- 回调机制：`onFinished` 通知 App 动画播放完毕，等待数据就绪后再切换
- ⚠️ 遗留：Splash 淡出到主页仍为闪现（ISSUE-4），`.transition(.opacity)` + `.zIndex(1)` 无效

**新增文件：**
- `Assets.xcassets/SplashLogo.imageset/` — Splash 专用 Icon Image Set

---

## 已知问题（待解决）

| 编号 | 问题 | 严重度 | 分析 |
|------|------|--------|------|
| ~~**ISSUE-1**~~ | ~~启动白屏 20-30s~~ | ~~高~~ | ✅ 已解决（2026-03-30）：SwiftData 旧数据含已删除的 `xiaohongshu` 枚举导致解码崩溃 → schema 版本号迁移自动清理；黑屏 → Info.plist `UILaunchScreen` 配置 AccentColor 背景 |
| **ISSUE-2** | SwiftData 快照累积（total=49 且持续增长） | 中 | `clearExpiredSnapshots` 未被定期调用，每次 `fetchTopics` 都保存新快照但不清理旧的，长期会拖慢本地查询 |
| **ISSUE-4** | Splash 淡出到主页无动画（直接闪现） | 低 | ZStack 条件视图移除时 zIndex 行为异常。已尝试 `.transition(.opacity)` + `.zIndex(1)` 无效。可能需要改为非条件视图方案（opacity 手动控制）或 `matchedGeometryEffect` |
| **ISSUE-3** | Feed 首次加载 3.1s（`forceRefresh=false` 仍走网络） | 中 | 缓存 TTL 策略可能有问题——`forceRefresh=false` 时应优先返回缓存，仅在过期后才请求网络 |

---

## 待办事项（按优先级排序）

### P0 — 用户体验核心

| 编号 | 任务 | 预计工作量 | 来源 |
|------|------|-----------|------|
| **TODO-1** | 卡片多模态内容（HeroCard/StandardCard 加入图片缩略图） | 4-6 小时 | SwiftUI Review P3 #25 |
| **TODO-2** | Splash 改造（去 AI slop 粉紫蓝渐变，简洁品牌感） | 30 分钟 | SwiftUI Review AI Slop 检测 |

### P1 — 功能完善

| 编号 | 任务 | 预计工作量 | 来源 |
|------|------|-----------|------|
| **TODO-3** | 趋势页打磨（RPC 优化、曲线交互、关联话题展示优化） | 2 小时 | 2.6.6 |
| **TODO-4** | Feed 最后更新时间展示 | 30 分钟 | SwiftUI Review P3 #28 |
| **TODO-5** | Compare 交集结果前置到 Feed（降低发现门槛） | 4 小时 | 设计评审建议 |

### P2 — 技术债务

| 编号 | 任务 | 预计工作量 | 来源 |
|------|------|-----------|------|
| **TODO-6** | SettingsView 文件拆分（5 个类型 → 独立文件） | 1 小时 | SwiftUI Review P1 #11 |
| **TODO-7** | Binding(get:set:) 重构（PlatformManagementView） | 1 小时 | SwiftUI Review P0 #4 |
| **TODO-8** | DataAnalyseView DI 违规修复（直接实例化 RemoteDataSource） | 1 小时 | SwiftUI Review P1 #12 |
| **TODO-9** | MiniTrendLine 去 GeometryReader（接收 size 参数） | 30 分钟 | 性能审计 PERF-2 |
| **TODO-10** | TrendTopicEntity 手动 Equatable（仅比较关键字段） | 15 分钟 | 性能审计 PERF-7 |
| **TODO-11** | SwiftData 快照清理机制（定期调用 clearExpiredSnapshots） | 30 分钟 | ISSUE-2 |
| **TODO-12** | 缓存 TTL 策略修复（forceRefresh=false 时优先缓存） | 1 小时 | ISSUE-3 |
| **TODO-13** | Dynamic Type 全局支持（剩余文件的固定字体→语义字体） | 2 小时 | SwiftUI Review P1 #9 |

### P3 — 长期优化

| 编号 | 任务 | 预计工作量 | 来源 |
|------|------|-----------|------|
| **TODO-14** | 启动白屏问题深度调查（真机验证、Supabase 静态链接） | 需调研 | ISSUE-1 |
| **TODO-15** | Neutral 色彩迁移 Asset Catalog（减少 colorScheme 依赖） | 2 小时 | SwiftUI Review P3 #29 |
| **TODO-16** | P1 补充数据源（6 源：sina-news, thepaper 等） | 持续 | 2.1.2 |

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
