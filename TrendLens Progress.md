# TrendLens 开发进展

> **文档定位：** 当前开发进度与任务追踪（唯一权威来源）
> **阶段定义参考：** [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md) 第 7 章
>
> **当前阶段：** 阶段 0.5 - UI 设计深化 ✅ 已完成
> **最后更新：** 2026-01-22

---

## 已完成

### 架构搭建（2026-01-21）

- [x] Clean Architecture 目录结构
- [x] Domain 层：Entities, UseCases, Repository 协议
- [x] Data 层：Repository 实现, DataSources（Local/Remote）
- [x] Infrastructure 层：NetworkClient（支持 ETag）
- [x] 依赖注入容器
- [x] 4 个 ViewModel（Feed, Compare, Search, Settings）
- [x] 项目编译通过（iOS Simulator）

### 阶段 0 完成（2026-01-21）

- [x] iOS 26 SDK 统一版本系统确认（无需额外 target 配置）
- [x] Design System 基础：字体、间距、圆角、Liquid Glass 材质定义
- [x] 炫酷启动页（SplashView）：动态光球、渐变、旋转动画
- [x] 基础导航结构：
  - iPhone：TabView（4 个主要 Tab）
  - iPad：NavigationSplitView + Sidebar
  - macOS：NavigationSplitView + 原生选择支持
- [x] 4 个功能页面占位：FeedView, CompareView, SearchView, SettingsView
- [x] 更新 TrendLensApp.swift：集成 SwiftData ModelContainer + 启动页逻辑
- [x] 三端编译验证通过（iPhone 17 Pro, iPad Pro 13-inch M5, macOS）

### 阶段 0.5 完成（2026-01-22）

- [x] UI 设计白皮书创建（TrendLens UI Design System.md）
- [x] Prismatic Flow 设计系统扩展：
  - [x] 平台渐变色带（6 个平台）
  - [x] 热度光谱（8 级热度映射）
  - [x] 3D 阴影层级系统
  - [x] 动画时长规范
- [x] UI 组件库实现：
  - [x] TrendCard（Morphic 变形卡片组件）
  - [x] PlatformBadge（平台徽章组件）
  - [x] PlatformGradientBand（平台渐变光带）
  - [x] HeatIndicator（热度指示器 + 能量条）
  - [x] HeatLevelBadge（热度等级徽章）
  - [x] RankChangeIndicator（排名变化指示器）
  - [x] RankBadge（排名徽章）
  - [x] EmptyStateView（空状态组件）
  - [x] ErrorView（错误状态组件）
  - [x] ErrorBanner（内联错误横幅）
  - [x] LoadingView（加载状态组件）
  - [x] SkeletonCard / SkeletonList（骨架屏）
  - [x] RefreshLoadingView（刷新加载指示器）
- [x] 热度曲线功能：
  - [x] HeatDataPoint 数据模型（时间戳 + 热度值 + 排名）
  - [x] HeatCurveView（完整曲线 - 详情页，支持触摸交互）
  - [x] HeatCurveMini（迷你曲线 - 卡片内嵌）
  - [x] 曲线动画实现（绘制动画、悬浮交互）
- [x] 数据模型扩展：
  - [x] TrendTopicEntity 增加 heatHistory、rankChange、isFavorite 字段
  - [x] RankChange 枚举（new/up/down/unchanged）
- [x] MockData 固定数据：
  - [x] 6 个平台的模拟热点话题数据
  - [x] 热度曲线模拟数据生成
  - [x] 各平台 5-6 条示例话题
- [x] Feed 页面完整 UI：
  - [x] 平台 Tab 切换（全部 / 微博 / 小红书 / B站 / 抖音 / X / 知乎）
  - [x] 热榜列表（使用 TrendCard 组件）
  - [x] 卡片点击 → 话题详情 Sheet
  - [x] TopicDetailSheet（详情页，含完整热度曲线）
  - [x] 下拉刷新（模拟）
- [x] 三端编译验证通过（iPhone 17 Pro, iPad Pro 13-inch M5, macOS）

---

## 阶段 0：项目基建 ✅ 已完成

所有任务已完成，可进入阶段 0.5。

## 阶段 0.5：UI 设计深化 ✅ 已完成

所有 UI 组件已实现，固定 Mock 数据已填入。可进入阶段 1。

## 阶段 1：MVP（本地 Mock）

**目标：** 移除固定数据，改用 SwiftData 和专业 Mock 数据生成；完善交互功能。

- [ ] 移除 MockData.swift 固定数据
- [ ] SwiftData 模型完善：
  - [ ] TrendSnapshot（已有，需扩展）
  - [ ] TrendTopic（已有，需增加 heatHistory SwiftData 支持）
  - [ ] UserPreference（已有）
- [ ] SwiftData Mock 数据填充：
  - [ ] 生成 6 个平台的模拟 Snapshot
  - [ ] 每个平台 50 条热点话题
  - [ ] 为 TOP 10 话题生成模拟热度曲线数据
- [ ] Compare 页面：
  - [ ] 平台选择器（Chips）
  - [ ] 交集/差集计算逻辑
  - [ ] 对比结果展示
- [ ] Search 页面：
  - [ ] 搜索输入框
  - [ ] 搜索结果列表
  - [ ] 搜索历史
- [ ] Settings 页面：
  - [ ] 屏蔽词管理
  - [ ] 主题切换
  - [ ] 关于页面
- [ ] 交互功能：
  - [ ] 下拉刷新（Mock 数据重新生成）
  - [ ] 收藏功能（点击卡片内心形图标，持久化）
  - [ ] 屏蔽词功能（Settings 页面配置）

## 阶段 2：静态 JSON + CDN

- [ ] RemoteDataSource 实现
- [ ] ETag/If-None-Match 支持
- [ ] 缓存策略：validUntil + TTL
- [ ] 多区域端点配置

## 阶段 3：云端刷新程序

- [ ] 定时任务框架
- [ ] Snapshot 生成与上传
- [ ] 监控与告警

## 阶段 4：用户体系（可选）

- [ ] BaaS 用户鉴权
- [ ] 云端偏好同步
- [ ] 匿名用户迁移

## 阶段 5：质量与发布

- [ ] 单元测试覆盖率 ≥ 65%
- [ ] UI 测试核心流程
- [ ] 性能优化
- [ ] 隐私合规

---

## 新增文件清单（阶段 0.5）

### 数据模型
- `TrendLens/Core/Domain/Entities/HeatDataPoint.swift` - 热度数据点模型

### UI 组件
- `TrendLens/UIComponents/PlatformBadge.swift` - 平台徽章 + 渐变光带
- `TrendLens/UIComponents/HeatIndicator.swift` - 热度指示器 + 能量条
- `TrendLens/UIComponents/RankChangeIndicator.swift` - 排名变化指示器 + 排名徽章
- `TrendLens/UIComponents/TrendCard.swift` - Morphic 变形卡片
- `TrendLens/UIComponents/HeatCurveView.swift` - 热度曲线（完整版 + 迷你版）
- `TrendLens/UIComponents/EmptyStateView.swift` - 空状态视图
- `TrendLens/UIComponents/ErrorView.swift` - 错误状态视图 + 内联横幅
- `TrendLens/UIComponents/LoadingView.swift` - 加载状态 + 骨架屏

### 临时数据（阶段 1 将移除）
- `TrendLens/Core/Data/MockData.swift` - 固定 Mock 数据

### 修改文件
- `TrendLens/UIComponents/DesignSystem.swift` - 扩展 Prismatic Flow 设计系统
- `TrendLens/Core/Domain/Entities/TrendTopic.swift` - 扩展 TrendTopicEntity
- `TrendLens/Features/Feed/Views/FeedView.swift` - 完整 Feed UI 实现

---

## 文档整改任务

### 立即整改（优先级极高）

- [x] 重命名 TODO.md 为 TrendLens Progress.md
- [x] 修改 Development Plan.md 第7章（删除具体任务，改为引用 Progress.md）
- [x] 统一架构分层定义到 Technical Architecture.md
- [x] 删除 PROJECT_STRUCTURE.md
- [x] 删除 TrendLens Module Reference.md（内容已合并到 Technical Architecture）

### 深度整合（优先级高）

- [x] 统一技术细节到 Technical Architecture.md（技术栈、缓存策略、并发规范）
- [x] 在每份文档开头添加职责说明
- [x] 更新 README.md（用户视角，功能与规划）

### 建立维护机制（优先级中）

- [x] 更新 CLAUDE.md 文档维护规范（添加信息归属速查表）
- [ ] 添加文档一致性检查脚本（可选）

---

## 术语对照

| 文档术语 | 说明 |
|----------|------|
| Feed / 首页 / All | 全平台热榜聚合页 |
| Compare / 对比页 | 交集/差集分析页 |
| Topic | 热点话题实体 |
| Snapshot | 某时刻某平台的完整热榜快照 |
| Platform | 平台枚举（weibo, xiaohongshu, bilibili, douyin, x, zhihu） |
| Morphic Card | 变形卡片（非对称圆角 + 渐变光带） |
| Heat Spectrum | 热度光谱（8 级颜色映射） |
| Prismatic Flow | 棱镜流设计系统 |
