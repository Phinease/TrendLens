# TrendLens 开发待办

> 当前阶段：**阶段 0 - 项目基建**

---

## 阶段 0：项目基建

- [ ] iOS/iPadOS/macOS 三端 target 配置
- [ ] 基础导航：TabView（iPhone）+ NavigationSplitView（iPad/Mac）
- [ ] SwiftData ModelContainer 注入
- [ ] Design System 基础：字体、间距、圆角定义

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

## 术语对照

| 文档术语 | 说明 |
|----------|------|
| Feed / 首页 / All | 全平台热榜聚合页 |
| Compare / 对比页 | 交集/差集分析页 |
| Topic | 热点话题实体 |
| Snapshot | 某时刻某平台的完整热榜快照 |
| Platform | 平台枚举（weibo, xiaohongshu, bilibili, douyin, x） |
