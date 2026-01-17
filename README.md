# TrendLens

**TrendLens** — 用镜头看趋势，打破信息茧房。

一款跨平台热搜聚合应用，将小红书、微博、Bilibili、抖音、X 等平台的热榜以统一结构展示，实现横向对比，帮助用户获取更全面的信息视角。

## 功能特性

- **全平台聚合**：整合多个社交平台热榜，一站式查看
- **智能对比**：交集/差集分析，发现跨平台热点与平台特有内容
- **跨端体验**：支持 iOS / iPadOS / macOS，统一设计语言
- **个性化**：收藏、屏蔽词、自定义排序

## 技术栈

- **UI**: SwiftUI (iOS 26 / iPadOS 26 / macOS 26)
- **状态管理**: Observation (@Observable) + MVVM
- **本地存储**: SwiftData
- **网络**: URLSession + async/await
- **后端**: Supabase (开发阶段) / 国内 BaaS (生产阶段)
- **可视化**: Swift Charts
- **小组件**: WidgetKit

## 架构设计

采用 **Clean Architecture + MVVM** 分层架构：

```
┌─────────────────────────────────────────────────┐
│  Presentation: SwiftUI Views + ViewModels       │
├─────────────────────────────────────────────────┤
│  Domain: UseCases + Entities + Repository Proto │
├─────────────────────────────────────────────────┤
│  Data: Repository Impl + Local/Remote DataSource│
├─────────────────────────────────────────────────┤
│  Infrastructure: Network + Logging + Background │
└─────────────────────────────────────────────────┘
```

## 开发计划

| 阶段 | 目标 |
|------|------|
| 0 | 项目基建：三端 target、基础导航、SwiftData 注入 |
| 1 | MVP：本地 Mock 数据，完成核心 UI/交互 |
| 2 | 静态 JSON + CDN：生产级数据分发架构 |
| 3 | 云端刷新程序：数据生成与分发流水线 |
| 4 | 用户体系（可选）：云同步、跨设备 |
| 5 | 质量与发布：测试、性能优化、隐私合规 |

> 详见 `TrendLens Development Plan.md`

## 系统要求

- iOS 26.0+
- iPadOS 26.0+
- macOS 26.0+ (Tahoe)
- Xcode 26.0+
- Swift 6.2

## 快速开始

1. 克隆仓库
```bash
git clone https://github.com/YourUsername/TrendLens.git
```

2. 打开项目
```bash
cd TrendLens
open TrendLens.xcodeproj
```

3. 选择目标设备并运行

## 文档索引

| 文档 | 说明 |
|------|------|
| `TrendLens Development Plan.md` | 产品规划、开发阶段、BaaS 策略 |
| `TrendLens Technical Architecture.md` | 技术架构、目录结构、编码规范 |
| `TrendLens Module Reference.md` | 各模块职责、能力、边界定义 |
| `TrendLens Testing Guide.md` | 测试策略、覆盖率要求、运行方法 |
| `TrendLensTests Architecture.md` | 单元测试目录结构与规范 |
| `TrendLensUITests Architecture.md` | UI 测试 Page Object 与规范 |
