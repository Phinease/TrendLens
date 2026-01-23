# 目标与边界

一个 **“跨平台热搜聚合”** 的轻量 App：把小红书 / 微博 / Bilibili / 抖音 / X 等平台的热榜以统一结构展示，核心价值是 **“横向对比、打破单平台的信息茧房”**。

- **我们先不讨论“如何拿到热榜数据”**（官方 API/第三方源/爬取等属于后续议题）
- 本计划聚焦：**App 架构、技术栈（面向 iOS 26 / iPadOS 26 / macOS 26）、数据更新与缓存体系、BaaS 选型（含可替换与双数据源）、UI/交互与迭代节奏**

---

# 0. 英文项目名

- **TrendLens**（“用镜头看趋势”，语义贴合“打破信息茧房”）

命名建议：

- repo 名用 `TrendLens`（或你选的名字），bundle id 用 `com.yourname.trendlens`
- 预留未来国际化：避免中文拼音/平台名直接入项目名

---

# 1. 项目架构

采用 **Clean Architecture + MVVM** 分层架构，详细技术实现规范见 [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md)。

**简化架构图：**

```
Presentation → Domain → Data → Infrastructure
```

**核心原则：**

- 上层依赖下层，下层不依赖上层
- Domain 层无框架依赖
- Repository 模式支持后端可替换性

**模块组织：**

- **App**：入口、依赖注入、路由
- **Features**：功能模块（Feed、Compare、Search、Settings）
- **Core**：Domain + Data + Infrastructure
- **UIComponents**：可复用 UI 组件

详细分层说明、模块职责、依赖规则见 [Technical Architecture - 第1章](TrendLens%20Technical%20Architecture.md#1-整体架构)。

---

# 2. 技术栈

详细技术栈见 [TrendLens Technical Architecture.md 第3章](TrendLens%20Technical%20Architecture.md#3-技术栈)。

**核心技术选型：**

- **UI 框架**：SwiftUI（适配 Liquid Glass 风格）
- **状态管理**：@Observable（MVVM）
- **持久化**：SwiftData（iOS 26 新特性：Model Inheritance、Persistent History）
- **网络**：URLSession + async/await + ETag
- **并发模型**：Swift 6.2（默认 `@MainActor` 隔离）
- **可视化**：Swift Charts
- **小组件**：WidgetKit

并发模型与 Actor 隔离策略见 [Technical Architecture - 第4章](TrendLens%20Technical%20Architecture.md#4-swift-62-并发模型)。

---

# 3. 状态管理：@Observable

本项目采用 **@Observable** 宏作为 MVVM 的状态管理方式，而非传统的 `ObservableObject`。

**核心优势：**

- 细粒度属性追踪（只在相关属性变化时刷新 UI）
- 无需手动 `@Published` 注解
- 更好的性能

**基本使用模式：**

```swift
@Observable
final class FeedViewModel {
    private(set) var items: [TrendTopic] = []
    private(set) var isLoading = false
    private(set) var error: Error?
}
```

详细说明与最佳实践见 [CLAUDE.md - 状态管理](CLAUDE.md#状态管理)。

---

# 4. 数据模型与缓存策略

采用 **Snapshot（快照）** 模型：热榜数据是时间序列，每次刷新生成一个快照。

**数据形态：**

- 每个 Snapshot 包含：platform、topics、fetchedAt、validUntil、etag
- 支持离线模式、缓存验证、历史对比

**缓存策略：**
详见 [Technical Architecture - 第6章](TrendLens%20Technical%20Architecture.md#6-数据流与缓存策略)。

**刷新策略：**

- 客户端：进入前台刷新（TTL）、手动刷新、后台刷新（BGTaskScheduler）
- 云端：定时任务 + CDN 分发（见阶段 2-3 交付物）

---

# 5. BaaS 选型与“可替换/双数据源”策略（重点更新）

希望：

- 学习期/开发期用 **Supabase**（体验好，效率高）
- 未来上架/国内可用性要更稳：换成 **国内 BaaS**（或同时支持国内+海外）

这完全可行，但前提是：**从第一天把 RemoteDataSource 抽象好，并且让“云端刷新程序”成为单一事实源（SSOT）**。

## 5.1 开发阶段：Supabase（优先）

为什么适合学习期：

- Postgres 生态强、开发体验好
- Auth/Storage/Realtime 等开箱即用

但计划书中需要明确：

- **Supabase 是“阶段性默认后端”**，不是长期唯一选择

## 5.2 未来替换：国内 BaaS（CloudBase / AGC / LeanCloud / 自建等）

替换策略的关键：

- App 端只依赖一个协议：
  - `TrendingRemoteDataSource`（获取快照/增量）
  - `TrendingConfigRemoteDataSource`（灰度开关/版本）
- Supabase / 国内 BaaS 都只是 **协议实现**（Adapter）

这样你可以：

- 只换 RemoteDataSource 的实现与依赖注入
- UI、VM、UseCase、Repository 基本不动

## 5.3 国际化与“双数据源”共存（Supabase + 国内 BaaS）

> “未来可能国际化”，并且希望 Supabase + 国内 BaaS 双数据源：可行，但要先讲清同步策略。

### 策略 1：云端刷新程序同时写入两边（推荐）

- 刷新程序从各平台拉数据（怎么拉先不讨论）
- 生成统一 Snapshot
- **一次生成、双写**：
  - 写到 Supabase（海外）
  - 写到国内 BaaS（国内）

优点：

- 同步逻辑集中在服务端（最好测试、最好监控）
- App 端按“区域/网络”选择最近的数据源即可

挑战：

- 双写失败的补偿机制（重试、死信、对账）

### 策略 2：只存对象存储 JSON，BaaS 只做鉴权/偏好

- 热榜数据走“对象存储 + CDN（按地区分桶）”
- BaaS 只管：用户收藏/屏蔽词/订阅规则

优点：

- 热榜数据读取最便宜最稳
- “双数据源”几乎变成“多 CDN 区域分发”，同步很简单

挑战：

- 统计/复杂查询能力放到服务端后，可能要额外做 API

### 策略 3：数据库复制（不推荐作为第一选择）

- Postgres 到国内数据库做复制/同步

优点：

- 理论上很“统一”

挑战：

- 运维与一致性复杂度高
- 国内外网络与合规因素会放大难度

## 5.4 App 端“多后端选择”的落地方式

App 端做一个 `RemoteEndpointPolicy`：

- 根据地区/网络/配置（远端下发）决定用哪个后端
- 支持 fallback：
  - 首选国内 BaaS → 失败切到静态 JSON
  - 海外首选 Supabase → 失败切到静态 JSON

> 结论：**把“热榜快照”做成可 CDN 分发的 JSON，你的后端可替换性会直线上升。**

---

# 6. UI / 交互设计（Liquid Glass 设计语言）

> **完整 UI 设计规范见：** [TrendLens UI Design System.md](TrendLens%20UI%20Design%20System.md)

## 6.1 设计理念

采用 **Liquid Glass（液态玻璃）** 美学，强调透明、层次、流动、光影效果。核心设计目标：

- 让用户感受到"透过镜头看热点"的体验
- 信息密度高但不拥挤
- 轻量、优雅、现代

## 6.2 信息架构

- **首页（Feed/All）**：全平台综合视图（打破信息茧房的主入口）
- **平台页（Platform Tabs）**：按平台查看热榜（对照用）
- **对比页（Compare）**：
  - 交集：多个平台同时出现的热点
  - 差集：只在某个平台热的内容（体现"平台偏好"）
- **搜索/收藏（Search & Save）**：收藏热点、历史回看
- **设置（Settings）**：刷新策略、过滤词、排序方式、数据源说明、隐私说明

## 6.3 核心组件

详细设计规范见 [UI Design System - 第 8 章](TrendLens%20UI%20Design%20System.md#8-组件设计规范)。

- **TrendCard**：热点卡片（圆角 16pt，Material 背景，包含平台徽章、热度指示器、排名变化）
- **PlatformBadge**：平台徽章（32pt 圆形，平台色背景）
- **HeatIndicator**：热度指示器（数字 + 图标 / 进度条 / 小型曲线）
- **RankChangeIndicator**：排名变化（↑ 绿色 / ↓ 红色 / NEW 蓝色）
- **EmptyStateView**：空状态（图标 + 提示文字）
- **ErrorView**：错误态（图标 + 错误信息 + 重试按钮）
- **LoadingView**：加载态（Skeleton / Shimmer 效果）

## 6.4 热度曲线功能（新增特性）

**核心价值：** 让用户直观感受"热点的兴起与衰落"，而非仅看到静态数字。

详细设计规范见 [UI Design System - 第 9 章](TrendLens%20UI%20Design%20System.md#9-热度曲线设计新增功能)。

### 6.4.1 小型曲线（卡片内嵌）

- 尺寸：80pt × 32pt
- 位置：卡片右下角，热度数字下方
- 样式：平滑折线，根据热度映射颜色（灰/橙/红）
- 交互：点击卡片 → 展开详情页

### 6.4.2 完整曲线（详情页）

- 尺寸：全屏宽 × 200pt
- 样式：渐变填充区域 + 虚线网格背景
- 交互：拖动显示精确数据点，捏合缩放时间范围
- 数据采样：高热话题每 10 分钟，普通话题每 30 分钟

### 6.4.3 数据模型

```swift
struct HeatDataPoint: Codable, Sendable {
    let timestamp: Date
    let heatValue: Int
}

// TrendTopic 扩展
extension TrendTopic {
    var heatHistory: [HeatDataPoint] // 热度历史数据
}
```

### 6.4.4 技术实现

- 使用 **Swift Charts**（iOS 26 原生支持）
- 平滑曲线：Catmull-Rom 插值
- 动画：`trim(from:to:)` 绘制动画（0.8 秒）

## 6.5 交互细节

- Skeleton / Shimmer 加载态
- "上次更新：xx:xx" + "数据有效期"
- 下拉刷新 + 轻微触觉反馈
- 卡片点击：轻微缩放（0.98） + 阴影增强
- 卡片长按：快捷菜单（收藏/分享/屏蔽）
- 对比页：平台选择器（chips）
- 深色模式、动态字体、VoiceOver

---

# 7. 完整开发计划（阶段、里程碑、交付物）

> 以 0 → 1 的节奏：先把体验做出来，再把数据链路做稳，并确保后端可替换。

## 阶段 0：项目基建

**目标：** 建立 Clean Architecture 分层架构，完成三端项目配置。

**主要交付物：**

- Clean Architecture 目录结构（App, Features, Core, UIComponents）
- Domain/Data/Infrastructure 层完整框架
- 依赖注入容器
- 三端 target 配置（iOS/iPadOS/macOS）
- SwiftData ModelContainer 集成
- 基础导航结构（TabView / NavigationSplitView）
- Design System 基础定义

**当前状态：** ✅ 已完成

**当前进度：** 见 [TrendLens Progress.md](TrendLens%20Progress.md#阶段-0项目基建)

## 阶段 0.5：UI 设计深化（新增）

**目标：** 在进入 MVP 开发前，完善 UI 设计系统，提升视觉质量。

**主要交付物：**

- **UI 设计白皮书**：Liquid Glass 设计语言完整规范
- **核心 UI 组件库**：
  - TrendCard（热点卡片）
  - PlatformBadge（平台徽章）
  - HeatIndicator（热度指示器）
  - RankChangeIndicator（排名变化）
  - EmptyStateView / ErrorView / LoadingView
- **热度曲线功能**：
  - HeatDataPoint 数据模型
  - HeatCurveView（小型曲线）
  - HeatCurveDetailView（完整曲线）
  - 曲线动画与交互
  - TrendTopic 扩展（支持 heatHistory）

**当前状态：** 🚧 进行中

**当前进度：** 见 [TrendLens Progress.md](TrendLens%20Progress.md#阶段-05ui-设计深化新增)

## 阶段 1：MVP（纯本地 Mock 数据）

**目标：** 不依赖后端，先把 UI/交互做成"能用且好看"。

**主要交付物：**

- SwiftData 模型完善（Snapshot/Topic + heatHistory/UserPrefs）
- Mock 数据生成（6 个平台 × 50 条话题 + TOP 10 热度曲线）
- Feed 页面完整 UI（平台 Tab + 热榜列表 + 详情页）
- Compare 页面（平台选择器 + 交集/差集展示）
- 交互功能（下拉刷新 + 收藏 + 屏蔽词）
- 状态管理（空态 / 错误态 / 加载态）

**当前状态：** ✅ 已完成

**当前进度：** 见 [TrendLens Progress.md](TrendLens%20Progress.md#阶段-1mvp本地-mock)

## 阶段 1.5：UI 系统重构（Ethereal Insight）

**目标：** 基于新设计系统（v3.0 - Ethereal Insight）重构 UI，实现更高级、更克制、更高效的信息体验。

**核心理念：** 垂直切片式迭代开发——每个 Phase 都有立即可视觉验证的成果，而非到最后才发现问题。

**设计背景：**

原有的 Prismatic Flow 设计（v2.0）强调"棱镜、渐变、脉动"，但在实际使用中存在以下问题：

- 色彩过于丰富：平台色被滥用，导致视觉嘈杂
- 信息效率不足：缺少核心内容摘要，用户需要二次点击
- 创新性不足：采用标准 iOS 布局，未充分体现产品差异化

新设计系统 **Ethereal Insight** 在保留流动性与深度感的基础上，强调：

- **沉浸式体验**：中性背景 + 内容为中心
- **信息效率**：AI 摘要优先 + 极简趋势可视化
- **克制优雅**：平台色仅用于识别，热度色用于趋势

**完整设计规范见：** [TrendLens New UI Design System.md](TrendLens%20New%20UI%20Design%20System.md)

**开发原则：**

本项目处于研发阶段，不考虑兼容旧设计：

- 直接删除旧代码（TrendCard 等），不做适配层
- 保持代码清洁：避免兼容性冗余
- 每个 Phase 都能视觉验证：使用 Canvas Preview 或 Simulator 立即看到效果

**主要交付物（6 个 Phase）：**

### Phase 1：基础系统 + 第一个可见卡片

- 扩展 Mock 数据（添加 summary + heatHistory 字段）
- DesignSystem.swift 重构（中性色、Heat Spectrum、阴影预设）
- 原子组件（PlatformIcon、RankChangeIndicator、MiniTrendLine）
- StandardCard 完整初版
- CardGalleryView（临时预览组件）

**成果：** 在 Canvas/Simulator 看到完整的卡片样式

### Phase 2：Feed 页面集成

- HeroCard.swift（焦点卡片，Rank 1-3）
- 重构 FeedView（删除旧 TrendCard，使用新卡片）
- 混合布局验证（Hero + Standard）

**成果：** 打开 App 能看到 Feed 页面的新卡片列表

### Phase 3：导航系统升级

- FluidRibbon.swift（流体化平台选择器）
- FloatingDock.swift（悬浮导航栏，自动隐藏）
- 重构 MainNavigationView

**成果：** 顶部平台切换和底部 Dock 导航都能工作

### Phase 4：其他页面与状态组件

- 重构 CompareView / SearchView（使用新组件）
- 更新 EmptyStateView / SkeletonCard / ErrorView
- iPad/Mac 响应式布局

**成果：** 所有页面统一视觉风格

### Phase 5：高级特效与交互

- 热度特效（发光、脉冲、粒子）
- 卡片交互（点击、滑动、长按）
- 详情页转场动画
- 性能优化和代码清理

**成果：** 完整的高级交互体验，代码库干净

### Phase 6：三端验证与文档更新

- 三端编译验证（iPhone / iPad / Mac）
- 视觉和交互走查
- 深色模式、无障碍、动态字体检查
- 文档同步更新

**成果：** UI 重构完成，阶段 1.5 标记完成

**当前状态：** 🚧 进行中

**当前进度：** 见 [TrendLens Progress.md](TrendLens%20Progress.md#阶段-15ui-系统重构ethereal-insight)

## 阶段 2：静态 JSON + CDN（生产级数据方案）

**前置条件：** 阶段 1.5 完成（UI 重构完成后再连接真实数据）

**目标：** 建立生产级的数据分发架构。热榜数据本质是只读的时间序列，静态 JSON + CDN 是**长期生产方案**，而非过渡方案。

**为什么这是最佳方案：**

- **成本低**：CDN 分发比数据库查询便宜几个数量级
- **性能高**：全球边缘节点，延迟最低
- **稳定性强**：CDN 故障率远低于数据库服务
- **可替换性高**：换 CDN 供应商只需改 URL，无需改 App 代码

**主要交付物：**

- RemoteDataSource：从 CDN URL 拉取 JSON
- ETag/If-None-Match 支持（节省流量）
- 缓存策略：TTL + validUntil
- 数据版本与回滚字段（schemaVersion）
- 多区域 CDN 配置（国内/海外）

**当前进度：** 见 [TrendLens Progress.md](TrendLens%20Progress.md#阶段-2静态-json--cdn)

## 阶段 3：云端刷新程序

**目标：** 建立数据生成与分发流水线。

**主要交付物：**

- 定时任务框架（云函数 + Cron）
- 生成 Snapshot 并上传至对象存储（触发 CDN 刷新）
- 基本监控：日志、告警（刷新失败/数据为空）
- 多区域同步（国内 OSS + 海外 S3/R2）

**当前进度：** 见 [TrendLens Progress.md](TrendLens%20Progress.md#阶段-3云端刷新程序)

## 阶段 4：用户体系与云同步（可选）

**目标：** 为需要跨设备同步的用户提供账户体系。

> **注意：** 此阶段为可选增强，核心功能不依赖用户登录。

**主要交付物：**

- BaaS 用户鉴权（Supabase Auth / 国内 BaaS）
- 云端存储用户偏好：收藏、屏蔽词、订阅规则
- 跨设备同步
- 匿名用户数据迁移（本地 → 云端）

**当前进度：** 见 [TrendLens Progress.md](TrendLens%20Progress.md#阶段-4用户体系可选)

## 阶段 5：质量与发布

**目标：** 完成测试、性能优化、隐私合规，准备发布。

**主要交付物：**

- 单元测试：解析、去重、排序、对比算法
- UI 测试：关键流程（刷新/切平台/收藏）
- 性能：首屏时间、列表滚动、SwiftData 查询优化
- 隐私合规：隐私政策、数据收集声明

**当前进度：** 见 [TrendLens Progress.md](TrendLens%20Progress.md#阶段-5质量与发布)

---

# 8. 高级功能规划

> 以下功能在核心架构稳定后逐步迭代，每个功能都是在现有模块上增加能力。

## 8.1 Compare 对比页（产品灵魂）

核心价值：打破信息茧房，横向对比各平台差异。

功能点：

- **交集视图**：多个平台同时出现的热点（真正的全民热点）
- **差集视图**：只在某个平台热的内容（体现平台用户画像差异）
- **平台选择器**：Chips 多选，灵活对比任意组合
- **热度归一化**：不同平台的热度值标准化，便于对比

## 8.2 热点时间线

核心价值：洞察热点的生命周期与跨平台传播路径。

功能点：

- **单话题时间线**：查看某个热点在各平台的上榜/下榜/排名变化
- **传播路径可视化**：热点从哪个平台首发，如何扩散到其他平台
- **持续时长统计**：哪些平台的热点更"长寿"
- **Swift Charts 可视化**：时间轴 + 多平台曲线

## 8.3 Widget 小组件

功能点：

- 桌面 Top1/Top5 速览
- 多尺寸适配（small/medium/large）
- 点击跳转到对应详情

## 8.4 智能通知

功能点：

- 重大热点突发通知（多平台同时上榜）
- 关注话题上榜提醒
- 通知频率控制（避免打扰）

## 8.5 数据透明度

功能点：

- 数据说明页：更新时间、来源、覆盖范围
- 数据健康状态：各平台最后更新时间、是否正常
