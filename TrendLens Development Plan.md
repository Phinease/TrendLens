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

# 1. 项目架构（推荐版）

> 目标：在 SwiftUI + SwiftData 的前提下，把「UI」「业务」「数据」分层，方便后续替换数据源、做缓存与同步、做对比视图。

## 1.1 分层（App 内）

**Presentation（SwiftUI Views）**
- 负责页面、动画、交互、可访问性
- 不直接写网络与持久化细节

**State / ViewModel（@Observable / MVVM）**
- 页面状态：加载、错误、离线、刷新进度
- 调用 UseCase/Repository

**Domain（UseCases + Entities）**
- “刷新热榜”“读取缓存”“对比平台差异”“计算交集/差集”等业务逻辑

**Data（Repository + DataSources）**
- Repository 统一对外提供数据
- DataSources：
  - Local（SwiftData）
  - Remote（BaaS API / CDN JSON / Supabase / 国内 BaaS）

**Infrastructure**
- 网络：URLSession + async/await + ETag/If-None-Match
- 日志：OSLog
- 后台刷新：BGTaskScheduler（iOS/iPadOS） / 前台定时刷新策略（macOS）

## 1.2 模块化（建议在现有 Xcode 工程内逐步演进）

从你当前 Xcode 初始化单 target 的结构，演进为：

- **App**（入口、依赖注入、路由）
- **Features**（页面级：Feed、Compare、Search、Settings）
- **Core**（Domain + Data + Infra）
- **UIComponents**（卡片、列表单元、Skeleton、Chip、Tag 等可复用组件）

落地方式：
- 初期可先按文件夹组织（不急着上 Swift Package）
- 中期把 Core / UIComponents 抽成 **Swift Package**，iOS/iPadOS/macOS 复用更干净

## 1.3 架构选项对比（你可以选其一）

### MVVM + Observation（推荐默认）
- 优点：轻量、SwiftUI 生态最顺、适合快速把交互体验做漂亮
- 缺点：需要你自律维持边界（别把逻辑塞进 View）

> 从第一天就把 Repository/DataSource 抽象写好，为将来双后端与替换留接口。

---

# 2. 技术栈（面向 iOS 26 / iPadOS 26 / macOS 26）

## 2.1 Toolchain

- **Xcode 26.x**（对应 iOS/iPadOS/macOS 26 SDK）
- **Swift 6.x**（建议用 Swift 6 语言模式；早期也可 Swift 5 模式逐步迁移）

## 2.2 客户端（App）

- **SwiftUI（跨三端 UI）**
  - iPhone：TabView 主导航
  - iPad / Mac：NavigationSplitView 主从布局 + Sidebar
  - 设计语言：适配“Liquid Glass”风格（透明层次、材质、清晰的层级与对比度）

- **Observation（@Observable）**
  - 作为 MVVM 的默认状态管理方式（见第 3 章）

- **SwiftData（本地缓存/离线）**
  - ModelContainer：App 入口注入
  - ModelContext：Repository 内使用（不要散落在 View）
  - Schema 迁移策略：从 MVP 阶段就保留 schemaVersion

- **Swift Concurrency（async/await）**
  - 并发拉取多平台数据、去重、合并、计算交集/差集
  - 结合 Swift 6 严格并发检查，让数据层更安全

- **Networking**
  - URLSession + Codable
  - ETag/Last-Modified / 断网重试 / 节流（防止频繁刷新）

- **Background Refresh**
  - iOS/iPadOS：BGAppRefreshTask（尽力而为，不强依赖频率）
  - macOS：前台定时刷新 + 手动刷新为主

- **Swift Charts**：做“跨平台热度分布”“24h 上榜次数”等可视化

- **WidgetKit**：桌面小组件（“全平台 Top1/Top5”）

---

# 3. Observation（@Observable）是什么？为什么作为 MVVM 首选

你熟悉 MVVM，但 Observation 不熟，这里给你一个“工程视角”的解释。

## 3.1 它解决了什么问题

传统 SwiftUI 常见两套：
- `ObservableObject + @Published + @StateObject/@ObservedObject`
- 以及各种手动 `objectWillChange.send()` 的坑

**Observation 的核心：**
- 用 `@Observable`（宏）把一个类型标记为“可观测”
- SwiftUI 能更细粒度地追踪“你读了哪些属性”，从而 **只在需要时刷新 UI**

简单理解：
- `ObservableObject` 更像“对象级别广播变更”
- `@Observable` 更像“属性级依赖追踪（更精细、更省）”

## 3.2 你在 MVVM 里怎么用

建议模式：
- 每个页面一个 `@Observable` ViewModel
- View 用 `@State` 持有 VM（或由依赖注入传入）
- VM 内部使用 async/await 调 repository

常见状态字段：
- `var items: [TopicViewData] = []`
- `var isLoading = false`
- `var error: Error? = nil`
- `var lastUpdatedAt: Date?`

## 3.3 与 SwiftData 的关系

- SwiftData Model 本身也和 SwiftUI/Observation 生态衔接良好
- 但工程上仍建议：
  - SwiftData 的 `ModelContext` 放在 Repository
  - ViewModel 只关心“拿数据/写数据”的接口，不关心持久化细节

## 3.4 你需要注意的坑（提前规避）

- **线程/Actor 约束**：UI 更新通常在主线程（建议 ViewModel 默认 `@MainActor`）
- **引用类型/值类型边界**：ViewModel 通常用 class；纯数据结构用 struct
- **避免在 View 中做 IO**：网络与持久化都应在 VM/UseCase/Repository

---

# 4. 数据更新方式（不讨论“怎么获取”，只讨论“怎么更新/缓存”）

> 采用“快照 Snapshot”模型。

## 4.1 数据形态：Snapshot

热榜天然是时间序列：
- 每个平台每次刷新生成一个 Snapshot
- Snapshot 包含：platform、rank 列表、fetchedAt、validUntil（TTL）、hash/etag

客户端：
- 拉取最新 Snapshot（或增量）
- 过期后自动刷新
- 离线时展示最近一次 Snapshot，并明确标注“更新时间/是否过期”

## 4.2 刷新策略（客户端）

- **进入前台刷新**：若缓存超过 X 分钟（比如 10 分钟）
- **手动刷新**：下拉刷新 + 显示“正在更新/上次更新”
- **后台刷新（iOS/iPadOS）**：系统允许的情况下做轻量刷新
- **节流**：同一平台短时间多次进入不要反复打 API

## 4.3 刷新策略（云端）

- **定时任务**：每个平台按自身更新频率刷新
- **多级缓存**：
  - DB 保存结构化数据（便于查询/统计/对比）
  - 对外 API 尽量走 **CDN 缓存的 JSON**（成本低、性能高）
- **一致性与有效性**：
  - Snapshot 带 validUntil
  - 写入时做去重（hash 相同则不重复写）
  - 标记数据来源与版本，便于回滚

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

# 6. UI / 交互设计建议（更贴合 iOS 26 / macOS 26 设计语言）

## 6.1 信息架构（推荐）

- **首页（All）**：全平台综合视图（你定义的“真实热点”主入口）
- **平台页（Platform）**：按平台查看热榜（对照用）
- **对比页（Compare）**：
  - 交集：多个平台同时出现的热点
  - 差集：只在某个平台热的内容（体现“平台偏好”）
- **搜索/收藏（Search & Save）**：收藏热点、历史回看
- **设置（Settings）**：刷新策略、过滤词、排序方式、数据源说明、隐私说明

## 6.2 交互细节（提升质感）

- Skeleton / Shimmer 加载态
- “上次更新：xx:xx” + “数据有效期”
- 下拉刷新 + 轻微触觉反馈
- 卡片上标注：平台徽标、排名变化（↑↓）
- 对比页提供：平台选择器（chips）
- 深色模式、动态字体、VoiceOver

---

# 7. 完整开发计划（阶段、里程碑、交付物）

> 以 0 → 1 的节奏：先把体验做出来，再把数据链路做稳，并确保后端可替换。

## 阶段 0：项目基建

交付：
- iOS/iPadOS/macOS 三端 target 跑通
- 基础导航：TabView（iPhone）+ NavigationSplitView（iPad/mac）
- SwiftData ModelContainer 注入（在 App 入口）
- Design System：字体、间距、圆角、材质层（为 Liquid Glass 风格预留）

## 阶段 1：MVP（纯本地 Mock 数据）

目标：不依赖后端，先把 UI/交互做成“能用且好看”。

交付：
- SwiftData 模型（Snapshot/Topic/UserPrefs）
- 首页（All）+ 平台页（Platform）
- 下拉刷新（先刷新本地 mock）
- 收藏/屏蔽词（本地状态）
- 过滤与排序
- 空状态、错误态、离线态

## 阶段 2：接入“云端静态 JSON”

目标：先用最简单的远端接口形态跑通“远端 → 本地缓存 → UI”。

交付：
- RemoteDataSource：从固定 URL 拉取 JSON
- ETag/If-None-Match 支持
- 缓存策略：TTL + validUntil
- 数据版本与回滚字段（schemaVersion）

## 阶段 3：Supabase 作为开发后端

交付：
- Snapshots 表结构（或存 JSON + 元数据）
- API 访问层（RemoteDataSource 的 Supabase 实现）
- 基本鉴权（可先匿名/设备级）

## 阶段 4：云端刷新程序（不讨论抓取细节，只做触发与写入）

交付：
- 定时任务框架（云函数 + Cron）
- 生成 Snapshot 并写入后端（先写 Supabase）
- 基本监控：日志、告警（刷新失败/数据为空）

## 阶段 5：国内 BaaS 替换/双后端

交付：
- 国内 BaaS 的 RemoteDataSource 实现（Adapter）
- EndpointPolicy（按地区/网络选择后端）
- 双写/对账（如果你选“服务端双写”策略）

## 阶段 6：产品化增强（持续迭代）

- Compare 对比视图（产品灵魂）
- 搜索 + 收藏 + 历史回看
- Widget
- 通知（重大新热点）
- 数据说明页（透明度：更新时间、来源、覆盖范围）

## 阶段 7：质量与发布（并行）

- 单元测试：解析、去重、排序、对比算法
- UI 测试：关键流程（刷新/切平台/收藏）
- 性能：首屏时间、列表滚动、SwiftData 查询优化
- 隐私合规：隐私政策、数据收集声明
