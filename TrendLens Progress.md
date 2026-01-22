# TrendLens 开发进展

> **文档定位：** 当前开发进度与任务追踪（唯一权威来源）
> **阶段定义参考：** [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md) 第 7 章
>
> **当前阶段：** 阶段 1 - MVP（本地 SwiftData + Mock 数据生成）📋 准备开始
> **最后更新：** 2026-01-22
> **代码结构参考：** [TrendLensTests Architecture.md](TrendLensTests%20Architecture.md) 第 7 章

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

## 阶段 1：MVP（本地 SwiftData + Mock 数据生成）

**目标：** 将 MockData 集成到 SwiftData，完成完整数据流，实现所有功能页面。

**评估说明：** 基于代码探索（2026-01-22），当前状态：
- ✅ Domain 层完全实现（Entities, UseCases, Repository 协议）
- ✅ ViewModels 全部实现（FeedViewModel, CompareViewModel, SearchViewModel, SettingsViewModel）
- ✅ FeedView UI 完全实现（使用固定 MockData）
- ✅ UI 组件库完整（9 个 Prismatic Flow 组件）
- ⚠️ LocalTrendingDataSource.saveSnapshot() 未实现（FIXME 标记）
- ⚠️ FeedView 直接使用 MockData，未连接 ViewModel
- 📋 Compare/Search/Settings 是占位符

### 1.1 数据层完善

- [ ] 实现 LocalTrendingDataSource.saveSnapshot()
  - [ ] 将 TrendSnapshotEntity 转换为 SwiftData Model
  - [ ] 批量保存 TrendSnapshot + TrendTopic 关联
  - [ ] 处理 heatHistory 持久化（转换为 JSON 或关联表）
- [ ] 创建 MockDataGenerator（替代固定 MockData）
  - [ ] generateSnapshot(platform:) 方法
  - [ ] 随机生成话题标题、热度值、排名变化
  - [ ] 动态生成热度曲线数据
  - [ ] 支持重新生成（模拟刷新）
- [ ] 实现首次启动数据填充
  - [ ] 在 DependencyContainer 或 App 启动时检查数据库是否为空
  - [ ] 为 6 个平台各生成 1 个初始 Snapshot（每个 10-20 条话题）
  - [ ] 保存到 SwiftData
- [ ] 完善错误处理和日志记录

### 1.2 FeedView 数据流整合

- [ ] 连接 FeedViewModel
  - [ ] 替换 MockData 为 ViewModel 状态
  - [ ] displayedTopics 从 ViewModel 获取
  - [ ] 页面加载时调用 fetchTopics()
- [ ] 实现下拉刷新
  - [ ] 调用 MockDataGenerator 重新生成数据
  - [ ] 保存新 Snapshot 到 SwiftData
  - [ ] 更新 UI 显示
- [ ] 实现收藏功能
  - [ ] 卡片内心形图标点击事件
  - [ ] 调用 ViewModel.toggleFavorite()
  - [ ] 视觉反馈（动画、触觉）
- [ ] 实现屏蔽词过滤
  - [ ] 从 UserPreference 读取屏蔽词
  - [ ] 在 FetchTrendingUseCase 中过滤话题
  - [ ] 过滤后话题不显示在列表中
- [ ] 错误状态和空状态处理
  - [ ] 使用 ErrorView 显示错误
  - [ ] 使用 EmptyStateView 显示无数据
  - [ ] 使用 LoadingView 显示加载中

### 1.3 CompareView 完整实现

- [ ] 平台选择器 UI
  - [ ] 使用 Chip 风格多选组件
  - [ ] 支持选择 2-6 个平台
  - [ ] 选中态视觉反馈
- [ ] 交集/差集计算
  - [ ] 调用 CompareViewModel.findIntersection()
  - [ ] 调用 CompareViewModel.findUnique()
  - [ ] 显示相似度阈值说明（Levenshtein 距离）
- [ ] 对比结果展示
  - [ ] 交集区域：使用 TrendCard 展示
  - [ ] 平台独有区域：按平台分组显示
  - [ ] 支持点击查看详情（复用 TopicDetailSheet）
- [ ] 加载和错误状态

### 1.4 SearchView 完整实现

- [ ] 搜索输入框
  - [ ] 使用 TextField 组件
  - [ ] 搜索图标、清除按钮
  - [ ] 实时搜索（debounce 300ms）或手动搜索
- [ ] 搜索结果列表
  - [ ] 使用 TrendCard 组件展示结果
  - [ ] 按热度排序
  - [ ] 支持平台筛选
- [ ] 搜索历史（可选）
  - [ ] 保存最近 10 条搜索记录
  - [ ] 点击历史记录快速搜索
  - [ ] 支持清除历史
- [ ] 空状态和错误处理

### 1.5 SettingsView 完整实现

- [ ] 订阅平台管理页面
  - [ ] 展示 6 个平台列表
  - [ ] Toggle 开关控制订阅状态
  - [ ] 保存到 UserPreference
  - [ ] 影响 Feed 页面显示内容
- [ ] 屏蔽词管理页面
  - [ ] 展示当前屏蔽词列表
  - [ ] 添加屏蔽词（TextField + 添加按钮）
  - [ ] 删除屏蔽词（滑动删除或编辑模式）
  - [ ] 实时生效（重新加载 Feed 数据）
- [ ] 刷新设置页面
  - [ ] 刷新间隔选择（15分钟/30分钟/1小时/手动）
  - [ ] 后台刷新开关
  - [ ] 说明文本
- [ ] 关于页面
  - [ ] App 版本信息
  - [ ] 开发者信息
  - [ ] 隐私政策、用户协议（占位）
  - [ ] 致谢信息

### 1.6 交互完善

- [ ] 全局收藏功能
  - [ ] FeedView 收藏图标交互
  - [ ] CompareView 收藏支持
  - [ ] SearchView 收藏支持
  - [ ] 收藏状态同步
  - [ ] 触觉反馈和动画
- [ ] 屏蔽词功能生效
  - [ ] Settings 配置后立即过滤
  - [ ] Feed 页面自动重新加载
  - [ ] 屏蔽词匹配逻辑（标题包含）
- [ ] 下拉刷新统一体验
  - [ ] Feed 页面
  - [ ] Compare 页面
  - [ ] Search 页面（刷新搜索结果）
- [ ] 错误提示优化
  - [ ] 使用 ErrorView 统一样式
  - [ ] 提供重试按钮
  - [ ] 错误信息本地化

### 1.7 测试和调试

- [ ] 三端编译验证
  - [ ] iPhone 17 Pro Simulator
  - [ ] iPad Pro 13-inch M5 Simulator
  - [ ] macOS 运行
- [ ] 功能测试
  - [ ] 数据流完整性（ViewModel → UseCase → Repository → DataSource）
  - [ ] SwiftData 读写正确性
  - [ ] 收藏功能持久化
  - [ ] 屏蔽词过滤准确性
- [ ] UI 测试
  - [ ] 各页面导航正常
  - [ ] 动画流畅
  - [ ] 错误状态展示正确

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
  - [ ] 注册后台刷新任务
  - [ ] 实现定时刷新逻辑（系统调度）
  - [ ] 测试后台刷新可靠性
- [ ] 本地通知（可选）
  - [ ] 热点突发提醒（热度突增 > 阈值）
  - [ ] 收藏话题更新提醒
  - [ ] 通知权限请求
- [ ] 电量和流量优化
  - [ ] 后台刷新频率限制
  - [ ] Wi-Fi 下刷新选项
  - [ ] 低电量模式适配

## 阶段 4：云端刷新程序

**目标：** 搭建服务端定时抓取和 JSON 生成服务。

- [ ] 爬虫程序开发
  - [ ] 微博热搜爬虫
  - [ ] 小红书热榜爬虫
  - [ ] B站热门爬虫
  - [ ] 抖音热点爬虫
  - [ ] X Trending Topics API
  - [ ] 知乎热榜爬虫
- [ ] Snapshot 生成器
  - [ ] 数据清洗和标准化
  - [ ] 热度值归一化
  - [ ] 排名变化计算
  - [ ] 生成 TrendSnapshotDTO JSON
- [ ] 定时任务调度
  - [ ] 每平台 10-15 分钟刷新一次
  - [ ] 错误重试机制
  - [ ] 失败告警
- [ ] JSON 上传到 CDN
  - [ ] 按平台分文件（weibo.json, xiaohongshu.json, ...）
  - [ ] 设置正确的 ETag 和 Cache-Control 头
  - [ ] 多区域同步
- [ ] 监控和日志
  - [ ] 抓取成功率监控
  - [ ] 数据质量检查
  - [ ] 异常告警

## 阶段 5：用户体系（可选）

**目标：** 引入用户账号系统，支持云端数据同步。

- [ ] BaaS 选型和集成
  - [ ] 国内：Leancloud / Supabase 替代 / 自建
  - [ ] 用户鉴权（匿名/邮箱/第三方登录）
  - [ ] 数据库设计（UserProfile, Favorites, Preferences）
- [ ] 云端偏好同步
  - [ ] 收藏话题云端保存
  - [ ] 屏蔽词云端保存
  - [ ] 订阅平台云端保存
  - [ ] 多设备同步
- [ ] 匿名用户迁移
  - [ ] 本地数据导出
  - [ ] 登录后自动合并
  - [ ] 冲突解决策略
- [ ] 隐私和安全
  - [ ] 用户协议和隐私政策
  - [ ] 数据加密传输
  - [ ] 用户数据删除功能

## 阶段 6：质量与发布

**目标：** 完善测试、优化性能、准备发布。

- [ ] 单元测试
  - [ ] Domain 层覆盖率 ≥ 90%
  - [ ] Data 层覆盖率 ≥ 80%
  - [ ] Presentation 层覆盖率 ≥ 75%
  - [ ] 测试报告生成
- [ ] UI 测试
  - [ ] 核心流程自动化测试
  - [ ] 各平台适配测试（iPhone/iPad/Mac）
  - [ ] 深色模式测试
  - [ ] 无障碍测试
- [ ] 性能优化
  - [ ] 启动时间优化（< 2s）
  - [ ] 列表滚动流畅度（60fps）
  - [ ] 内存占用优化
  - [ ] 网络请求优化
- [ ] 隐私合规
  - [ ] App Privacy Policy 完善
  - [ ] App Store 隐私标签准备
  - [ ] GDPR 合规检查（如需）
- [ ] 发布准备
  - [ ] App Store 截图和预览视频
  - [ ] 应用描述和关键词优化
  - [ ] App Icon 最终版
  - [ ] TestFlight 内测
  - [ ] App Store Connect 提交

---

## 术语参考

所有项目术语定义见 [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md) 第 10 章。
