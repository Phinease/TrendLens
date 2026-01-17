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

```
├── Presentation     # SwiftUI Views
├── ViewModel        # @Observable 状态管理
├── Domain           # UseCases + Entities
├── Data             # Repository + DataSources
│   ├── Local        # SwiftData
│   └── Remote       # BaaS API / CDN JSON
└── Infrastructure   # 网络、日志、后台刷新
```

## 开发计划

| 阶段 | 目标 |
|------|------|
| 0 | 项目基建：三端 target、基础导航、SwiftData 注入 |
| 1 | MVP：本地 Mock 数据，完成核心 UI/交互 |
| 2 | 接入云端静态 JSON，实现远端数据同步 |
| 3 | Supabase 作为开发后端 |
| 4 | 云端刷新程序 |
| 5 | 国内 BaaS 替换/双后端支持 |
| 6 | 产品化增强：对比视图、搜索、Widget、通知 |
| 7 | 质量与发布：测试、性能优化、隐私合规 |

## 系统要求

- iOS 26.0+
- iPadOS 26.0+
- macOS 26.0+
- Xcode 26.0+
- Swift 6.0+

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
