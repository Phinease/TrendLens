# TrendLens 开发进展

> **文档定位：** 当前开发进度与任务追踪（唯一权威来源）
> **阶段定义参考：** [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md) 第 7 章
>
> **当前阶段：** 阶段 2 - 远程数据 + CDN 集成
> **最后更新：** 2026-01-23

---

## 已完成阶段

### 阶段 0：项目基建 ✅

完成日期：2026-01-21

- Clean Architecture 目录结构、依赖注入容器
- Domain/Data/Infrastructure 三层架构
- 基础导航结构（iPhone TabView / iPad+macOS NavigationSplitView）
- 炫酷启动页（SplashView）
- 三端编译验证通过

### 阶段 0.5：UI 设计深化 ✅

完成日期：2026-01-22

- Prismatic Flow 设计系统（平台渐变色带、热度光谱、3D 阴影层级）
- UI 组件库（TrendCard、PlatformBadge、HeatIndicator、RankBadge 等 14 个组件）
- 热度曲线功能（HeatCurveView、HeatCurveMini、触摸交互）
- Feed 页面完整 UI（平台 Tab 切换、热榜列表、话题详情 Sheet）
- 三端编译验证通过

### 阶段 1：MVP（本地 SwiftData + Mock 数据）✅

完成日期：2026-01-23

**核心实现：**

- MockDataGenerator 动态生成数据（替代固定 MockData）
- 首次启动数据填充（6 平台各 15 条话题）
- FeedView 完整数据流（ViewModel 连接、下拉刷新、收藏、屏蔽词过滤）
- CompareView 完整实现（平台多选、交集/差集计算、对比结果展示）
- SearchView 完整实现（实时搜索、平台筛选、结果列表）
- SettingsView 完整实现（订阅平台管理、屏蔽词管理、刷新设置、关于页面）

**关键技术修复：**

- Swift 6 并发问题：UserPreference Sendable、@MainActor 隔离
- SwiftData error 1：所有 Predicate 避免捕获外部变量，改用内存过滤
- 禁用远程请求：`isRemoteEnabled = false` 配置开关

**技术要点：**

- SwiftData ModelContext 必须在 @MainActor 上使用
- SwiftData Predicate 不应捕获外部变量（即使是简单类型）
- 正确做法：获取所有数据 → 内存过滤

---

## 阶段 2：远程数据 + CDN 集成

**目标：** 连接真实后端数据源，完成网络层集成。

- [ ] 配置 CDN 端点
  - [ ] 确定 CDN 提供商（Cloudflare / AWS CloudFront / 国内 CDN）
  - [ ] 配置静态 JSON 文件存储路径
  - [ ] 设置多区域回退（国内/国外）
  - [ ] RemoteTrendingDataSource 配置真实 baseURL
- [ ] ETag 缓存优化
  - [ ] 验证 NetworkClient 的 If-None-Match 支持
  - [ ] 测试 304 响应处理
  - [ ] 验证缓存命中率
- [ ] 数据刷新策略
  - [ ] validUntil 时间配置（建议 15-30 分钟）
  - [ ] 手动刷新触发网络请求
  - [ ] 自动刷新间隔配置
- [ ] 错误处理和降级
  - [ ] 网络失败时使用过期缓存
  - [ ] 显示数据时效性标识
  - [ ] 离线模式提示
- [ ] 性能优化
  - [ ] 并行请求多平台数据（TaskGroup）
  - [ ] 请求超时配置优化
  - [ ] 流量监控

## 阶段 3：后台刷新 + 通知

**目标：** 实现后台数据刷新和可选的推送通知。

- [ ] BGTaskScheduler 集成
- [ ] 本地通知（热点突发提醒、收藏话题更新）
- [ ] 电量和流量优化

## 阶段 4：云端刷新程序

**目标：** 搭建服务端定时抓取和 JSON 生成服务。

- [ ] 爬虫程序开发（微博、小红书、B站、抖音、X、知乎）
- [ ] Snapshot 生成器（数据清洗、热度归一化、排名变化计算）
- [ ] 定时任务调度（每 10-15 分钟刷新）
- [ ] JSON 上传到 CDN
- [ ] 监控和日志

## 阶段 5：用户体系（可选）

**目标：** 引入用户账号系统，支持云端数据同步。

- [ ] BaaS 选型和集成
- [ ] 云端偏好同步（收藏、屏蔽词、订阅平台）
- [ ] 匿名用户迁移
- [ ] 隐私和安全

## 阶段 6：质量与发布

**目标：** 完善测试、优化性能、准备发布。

- [ ] 单元测试（Domain 90%, Data 80%, Presentation 75%）
- [ ] UI 测试
- [ ] 性能优化（启动 < 2s, 列表 60fps）
- [ ] 隐私合规
- [ ] 发布准备（App Store 提交）

---

## 术语参考

所有项目术语定义见 [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md) 第 10 章。
