# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 提供代码库工作指引。

## 项目概述

TrendLens 是一款跨平台热搜聚合应用，面向 iOS 26 / iPadOS 26 / macOS 26。聚合微博、小红书、Bilibili、抖音、X、知乎等平台热榜，通过对比分析帮助用户打破信息茧房。

**核心特征：**

- 原生 SwiftUI 应用（iOS 26+ SDK, Swift 6.2）
- Clean Architecture + MVVM 架构
- 后端可替换性设计（开发阶段 Supabase → 生产阶段 CDN + 国内 BaaS）
- 只读快照数据模型（热榜数据作为时间序列快照）

完整产品规划与技术选型详见 [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md)。

---

## 构建与测试

所有构建、测试命令、Xcode 快捷键、代码示例详见 [TrendLens Developer Guide.md](TrendLens%20Developer%20Guide.md)。

---

## 架构概览

### Clean Architecture 分层

完整架构说明见 [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md)。

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

**依赖规则：** 上层可依赖下层，下层不可依赖上层。Domain 层不依赖任何框架。

### 目录结构

详细目录结构、各层职责与模块边界定义见 [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md) 第 2 章和第 5 章。

```
TrendLens/
├── App/                    # 入口、依赖注入
├── Features/               # 功能模块（Feed, Compare, Search, Settings）
├── Core/
│   ├── Domain/            # 纯业务逻辑（无框架依赖）
│   ├── Data/              # 数据访问实现
│   └── Infrastructure/    # 网络、日志、后台任务
├── UIComponents/          # 可复用 UI 组件
├── Extensions/
└── Resources/
```

---

## 核心架构决策

### 1. SwiftData Model 与 Domain Entity 分离

- Domain Entities：纯 Swift 结构/类（无 `@Model` 宏）
- SwiftData `@Model` 类型：仅存在于 DataSources 层
- 通过 `toDomainEntity()` 方法转换

### 2. 基于快照的数据模型

- 热点话题是时间序列快照，非可变记录
- 每个快照包含：platform, topics, fetchedAt, validUntil, etag
- 支持离线模式、缓存验证、历史对比

### 3. 后端可替换性

- 所有后端访问通过 `RemoteDataSource` 协议
- 开发阶段：Supabase
- 生产计划：CDN 静态 JSON + 可选国内 BaaS（用户数据）
- App 代码不直接耦合特定后端

详见 [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md) 第 5 章「BaaS 选型与可替换策略」。

### 4. Actor 隔离（Swift 6.2）

项目采用 Swift 6.2 默认 `@MainActor` 隔离：

- Views/ViewModels：`@MainActor`
- UseCases：`Sendable` 结构体（可在任意 Actor 调用）
- Repositories/DataSources：I/O 方法标记 `nonisolated`
- NetworkClient：`actor`（线程安全网络操作）

并发模型详见 [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md) 第 4 章。

---

## 数据流与缓存策略

### 数据流

```
View → ViewModel → UseCase → Repository → DataSource
                                  ↓
                        Local (SwiftData) / Remote (Network)
```

### 缓存策略

1. 检查 `validUntil` 判断缓存有效性
2. 有效 → 返回缓存
3. 过期 → 请求远程（带 ETag）
4. 网络成功 → 更新缓存
5. 网络失败 → 返回过期缓存（带标记）

**ETag 支持：**

- NetworkClient 支持 `If-None-Match` 头
- 304 响应 → 使用缓存数据
- 节省流量与服务器负载

---

## 编码与测试规范

- **编码规范**：见 [Technical Architecture.md](TrendLens%20Technical%20Architecture.md) 第 8 章
- **测试策略**：见 [Testing Guide.md](TrendLens%20Testing%20Guide.md)
- **代码示例**：见 [Developer Guide.md](TrendLens%20Developer%20Guide.md)

**核心要点**：

- 使用 `@Observable` 宏（非 `ObservableObject`）
- 使用 `DependencyContainer` 创建所有依赖
- 测试命名：`test_[方法]_[条件]_[预期结果]`
- 覆盖率目标：Domain 90%, Data 80%, Presentation 75%

---

## 关键文件

跨层修改时，优先查阅以下文件：

**核心实体：**

- [TrendLens/Core/Domain/Entities/Platform.swift](TrendLens/Core/Domain/Entities/Platform.swift) - 平台枚举
- [TrendLens/Core/Domain/Entities/TrendTopic.swift](TrendLens/Core/Domain/Entities/TrendTopic.swift) - 话题实体与 SwiftData Model
- [TrendLens/Core/Domain/Entities/TrendSnapshot.swift](TrendLens/Core/Domain/Entities/TrendSnapshot.swift) - 快照实体（含 TTL/ETag）

**Repository 协议：**

- [TrendLens/Core/Domain/Repositories/TrendingRepository.swift](TrendLens/Core/Domain/Repositories/TrendingRepository.swift)
- [TrendLens/Core/Domain/Repositories/UserPreferenceRepository.swift](TrendLens/Core/Domain/Repositories/UserPreferenceRepository.swift)

**基础设施：**

- [TrendLens/Core/Infrastructure/Network/NetworkClient.swift](TrendLens/Core/Infrastructure/Network/NetworkClient.swift) - 网络层（ETag 支持）
- [TrendLens/App/DependencyContainer.swift](TrendLens/App/DependencyContainer.swift) - DI 配置

---

## 开发约束

### 必须做（DO）

- 保持 Domain 层纯净（无 SwiftUI/SwiftData/框架导入）
- 使用 Repository 协议，禁止从 ViewModel 直接实例化 DataSource
- Swift 6.2 `@MainActor` 上下文中，I/O 操作标记 `nonisolated`
- 所有依赖创建通过 DependencyContainer
- 编写领域错误，而非框架特定错误
- 使用 Mock Repository 测试 UseCase
- 遵循 Clean Architecture 依赖规则（内层不知道外层）

### 禁止做（DON'T）

- Domain 层导入 SwiftUI 或 SwiftData
- View 中直接使用 `@Query`（使用 Repository 模式）
- 硬编码后端 URL（使用 RemoteDataSource 抽象）
- 创建新 SwiftData Model 时不创建对应 Domain Entity
- 修改 SwiftData Schema 时跳过迁移策略
- 使用 `ObservableObject`（使用 `@Observable` 宏）
- 绕过依赖注入容器

---

## 文档维护规范

### 文档职责划分

| 文档 | 职责 | 更新时机 |
|------|------|----------|
| [Development Plan.md](TrendLens%20Development%20Plan.md) | 产品规划、开发阶段、BaaS 策略 | 阶段完成、架构决策变更 |
| [Technical Architecture.md](TrendLens%20Technical%20Architecture.md) | 技术规范（架构、技术栈、并发模型、编码规范） | 技术栈变更、架构调整 |
| [Developer Guide.md](TrendLens%20Developer%20Guide.md) | 开发操作手册（构建、测试命令、代码示例） | 工具链变更、新增常用模式 |
| [Testing Guide.md](TrendLens%20Testing%20Guide.md) | 测试策略总览、覆盖率要求 | 测试框架变更、质量要求调整 |
| [TrendLensTests Architecture.md](TrendLensTests%20Architecture.md) | 单元测试实现细节（从属于 Testing Guide） | 测试架构变化 |
| [UI Design System.md](TrendLens%20UI%20Design%20System.md) | UI 视觉设计规范、组件设计 | 设计语言变化 |
| [Progress.md](TrendLens%20Progress.md) | 当前待办、开发进展追踪（唯一权威） | 每次开发完成后 |
| [CLAUDE.md](CLAUDE.md)（本文件） | Claude Code 工作指引（引用式导航） | 文档结构调整 |

### 信息归属速查表

| 要查询/修改的信息 | 唯一归属文档 | 对应章节 |
|----------------|------------|---------|
| 架构分层定义 | Technical Architecture.md | 第1章 |
| 目录结构 | Technical Architecture.md | 第2章 |
| 技术栈 | Technical Architecture.md | 第3章 |
| 并发模型 | Technical Architecture.md | 第4章 |
| 模块职责 | Technical Architecture.md | 第5章 |
| 缓存策略 | Technical Architecture.md | 第6章 |
| 编码规范 | Technical Architecture.md | 第8章 |
| 构建/测试命令 | Developer Guide.md | 第2-3章 |
| 代码示例/模式 | Developer Guide.md | 第4-7章 |
| UI 设计规范 | UI Design System.md | 全文 |
| 组件设计 | UI Design System.md | 第8章 |
| 热度曲线设计 | UI Design System.md | 第9章 |
| 测试策略 | Testing Guide.md | 全文 |
| 单元测试架构 | TrendLensTests Architecture.md | 全文 |
| 阶段定义 | Development Plan.md | 第7章 |
| 当前任务 | Progress.md | 全文 |
| BaaS 策略 | Development Plan.md | 第5章 |

### 开发完成后的文档更新流程

**每次开发完成后，必须执行以下步骤：**

1. **更新 [TrendLens Progress.md](TrendLens Progress.md)**
   - 标记已完成的任务
   - 添加新发现的待办事项
   - 更新当前阶段进度

2. **更新 [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md)**
   - 更新对应阶段的完成状态（第 7 章「完整开发计划」）
   - 如有架构决策变化，更新相关章节

3. **如有技术实现变化，更新 [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md)**
   - 新增技术栈
   - 编码规范调整
   - 并发模型变化

**修改前检查清单：**

修改任何技术信息前，务必确认：

- [ ] 该信息的权威归属文档是哪个？（查看上方速查表）
- [ ] 是否需要同步更新引用该信息的其他文档？
- [ ] 修改后是否需要更新 Progress.md 的进度？
- [ ] 是否需要在 Development Plan 中标注阶段变化？

**禁止做：**

- ❌ 创建新的临时文档记录开发进展
- ❌ 在多个文档中重复记录相同信息
- ❌ 在文档中散弹式添加信息而不考虑职责划分

**推荐做：**

- ✅ 信息保持单一来源（Single Source of Truth）
- ✅ 文档间通过引用关联，而非复制粘贴
- ✅ 定期检查文档一致性
