# TrendLens 开发进展

> **文档定位：** 当前开发进度与任务追踪（唯一权威来源）
> **阶段定义参考：** [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md) 第 7 章
>
> **当前阶段：** 阶段 0 - 项目基建
> **最后更新：** 2026-01-21

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

---

## 阶段 0：项目基建

- [ ] iOS/iPadOS/macOS 三端 target 配置
- [ ] 基础导航：TabView（iPhone）+ NavigationSplitView（iPad/Mac）
- [x] SwiftData ModelContainer 注入框架（DependencyContainer 中已配置）
- [ ] Design System 基础：字体、间距、圆角定义
- [ ] 更新 TrendLensApp.swift（注入 ModelContainer）

## 阶段 1：MVP（本地 Mock）

- [ ] SwiftData 模型：Snapshot、Topic、UserPreference
- [ ] Feed 页面：热榜列表、平台 Tab 切换
- [ ] Compare 页面：交集/差集展示
- [ ] 下拉刷新（Mock 数据）
- [ ] 收藏/屏蔽词功能
- [ ] 空状态、错误态、加载态

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
| Platform | 平台枚举（weibo, xiaohongshu, bilibili, douyin, x） |
