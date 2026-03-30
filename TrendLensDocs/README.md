# TrendLens

**TrendLens** — 用镜头看趋势，打破信息茧房。

一款跨平台热搜聚合应用，将微博、知乎、百度、B站、抖音、头条等平台的热榜以统一结构展示，结合 Google Trends 趋势数据，实现横向对比与趋势洞察。

## 功能特性

- **全平台聚合**：整合 7 个社交平台热榜（微博/知乎/百度/B站热搜/B站热门/抖音/头条），一站式查看
- **智能对比**：交集/差集分析，发现跨平台热点与平台特有内容
- **趋势洞察**：Google Trends 时序数据驱动的关键词趋势，7 天曲线可视化
- **跨端体验**：支持 iOS / iPadOS / macOS，Liquid Glass 设计语言
- **个性化**：收藏、屏蔽词、自定义排序

## 系统组成

- **iOS 客户端**：SwiftUI 原生应用（Clean Architecture + MVVM）
- **Python 后端**：数据采集管道（7 平台热榜 → 归一化 → 嵌入 → 匹配 → Supabase）
- **Supabase**：PostgreSQL + pgvector + Data API

## 技术亮点

- 原生 SwiftUI（iOS 26 SDK / Swift 6.2）+ Liquid Glass
- Clean Architecture + MVVM 分层架构
- Supabase 后端（开发阶段，支持可替换）
- AppLog 结构化日志系统（OSLog 7 分类）
- 离线优先，SwiftData 缓存 + TTL 策略

## 开发阶段

| 阶段 | 状态 | 目标 |
|------|------|------|
| 0 项目基建 | ✅ | 三端 target、基础导航、依赖注入 |
| 0.5 UI 设计 | ✅ | Prismatic Flow 设计系统、14 个 UI 组件 |
| 1 MVP | ✅ | Mock 数据、Feed/Compare/Search/Settings |
| 1.5 UI 重构 | ✅ | Ethereal Insight 设计语言、HeroCard、FluidRibbon |
| 2 后端集成 | ✅ | Python 数据管道、Supabase、iOS 远程数据层 |
| 2.6 趋势页面 | ✅ | Trends Tab、TrendDetailView、关联话题 |
| 2.7-2.9 优化 | ✅ | Liquid Glass、View 重构、启动修复、Splash 改造、AppLog |

> 详细进度见 [TrendLens Progress.md](TrendLens%20Progress.md)

## 系统要求

- iOS 26.0+ / iPadOS 26.0+ / macOS 26.0+ (Tahoe)
- Xcode 26.0+
- Swift 6.2

## 快速开始

```bash
git clone https://github.com/YourUsername/TrendLens.git
cd TrendLens
open TrendLens.xcodeproj
```

需要配置 `Config/Secrets.xcconfig`（Supabase URL 和 Key），详见 [Developer Guide](TrendLens%20Developer%20Guide.md)。

## 文档导航

**产品与规划：**
- [Development Plan.md](TrendLens%20Development%20Plan.md) — 产品规划、开发阶段、BaaS 策略
- [Progress.md](TrendLens%20Progress.md) — 当前开发进度与待办任务
- [Trends Feature Design.md](TrendLens%20Trends%20Feature%20Design.md) — 趋势页面功能设计

**技术文档：**
- [Technical Architecture.md](TrendLens%20Technical%20Architecture.md) — 技术架构
- [Database Schema.md](TrendLens%20Database%20Schema.md) — 数据库模型
- [Backend Architecture.md](TrendLens%20Backend%20Architecture.md) — Python 后端架构
- [Key Files.md](TrendLens%20Key%20Files.md) — 关键文件索引

**开发协作：**
- [CLAUDE.md](../CLAUDE.md) — Claude Code 工作指引
- [iOS Debug Collaboration Guide.md](TrendLens%20iOS%20Debug%20Collaboration%20Guide.md) — 人机协作调试流程
- [SwiftUI Review.md](TrendLens%20SwiftUI%20Review.md) — 全面审查报告与修复记录
