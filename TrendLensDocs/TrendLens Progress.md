# TrendLens 开发进展

> **文档定位：** 当前开发进度与任务追踪（唯一权威来源）
> **阶段定义参考：** [TrendLens Development Plan.md](TrendLens%20Development%20Plan.md) 第 7 章
>
> **当前阶段：** 阶段 2 - 端到端验证完成（2.4.5）
> **最后更新：** 2026-03-13

---

## 已完成阶段

| 阶段 | 完成日期 | 核心交付 |
|------|---------|---------|
| **0 项目基建** | 2026-01-21 | Clean Architecture 三层架构、依赖注入、三端导航、启动页 |
| **0.5 UI 设计深化** | 2026-01-22 | Prismatic Flow 设计系统、14 个 UI 组件、热度曲线 |
| **1 MVP** | 2026-01-23 | Mock 数据生成、Feed/Compare/Search/Settings 完整实现 |
| **1.5 UI 重构** | 2026-01-24 ~ 02-18 | Ethereal Insight 设计语言、HeroCard、FluidRibbon、TopicDetail/DataAnalyse 分离（1.5.7 验收延后至阶段 6） |

---

## 当前阶段

### 阶段 2：后端数据采集 + 远程数据集成 🚧

**目标**：建立 Python 后端数据采集系统，通过 Supabase 存储数据，iOS 应用连接远程数据源替换本地 Mock 数据。

**设计文档**：
- 数据源选型：[backend/docs/hot-news-data-sources-v2.md](../backend/docs/hot-news-data-sources-v2.md)
- 数据需求：[backend/docs/data-requirements.md](../backend/docs/data-requirements.md)
- 数据存储策略：[backend/docs/data-storage-strategy.md](../backend/docs/data-storage-strategy.md)
- 全量调研：[backend/docs/data-sources-v1.md](../backend/docs/data-sources-v1.md)

**技术栈**：Python 后端 + Supabase (PostgreSQL + pgvector) + Jina Embeddings v3 + Supabase Data API

**Supabase 配置**：
- Project: TrendLens
- 已启用 Data API（RESTful，用于 iOS 端 supabase-swift 连接）

---

#### 2.1 数据源接口验证

- [x] **2.1.1 P0 核心源**（7 源）✅ — 全部验证通过，详见 [hot-news-data-sources-v2.md](../backend/docs/hot-news-data-sources-v2.md)
- [ ] **2.1.2 P1 补充源**（6 源）— sina-news, thepaper, tencent-hot, hackernews, 36kr-renqi, douban
- [ ] **2.1.3 P2 延伸源**（7 源）— wallstreetcn, cankaoxiaoxi, github-trending, netease-news, tieba, ithome, kaopu
- [ ] **2.1.4 补充缺失的数据源**

---

#### 2.2 数据库建模 ✅

6 张核心表 + 3 张趋势表 + pgvector HNSW 索引 + RLS + 20 平台种子数据。详见 [data-storage-strategy.md](../backend/docs/data-storage-strategy.md)。

> ~~2.2.6 pg_cron~~ — 免费版不支持，改由 Python 后端调度器执行。

---

#### 2.3 Python 后端开发

**代码位置**：`backend/src/trendlens/`（45+ Python 源文件，7 个包）
**技术栈**：uv + Python 3.12+ / httpx / structlog / jieba / Jina Embeddings / Supabase PostgREST
**详细架构**：[backend-architecture.md](../backend/docs/backend-architecture.md)

| 子任务 | 状态 | 摘要 |
|--------|------|------|
| 2.3.1 项目初始化 | ✅ | uv 项目、配置管理、日志系统、CLI 入口、数据模型 |
| 2.3.2 采集器基础设施 | ✅ | BaseFetcher ABC + 自动注册、httpx HTTP/2 + SOCKS、tenacity 重试 |
| 2.3.3 P0 核心源采集器 | ✅ | 7/7 平台全部验证通过（zhihu/baidu/bilibili-hs/bilibili-hv/toutiao/weibo/douyin） |
| 2.3.4 数据处理管道 | ✅ | topic_key 三级降级、热度排名映射、jieba 实体提取、Jina 批量嵌入 |
| 2.3.5 存储层 | ✅ | PostgREST 客户端 + 6 个 store 模块（topics/heat/embedding/cluster/snapshot/maintenance） |
| 2.3.6 匹配算法 | ✅ | 三信号融合（实体 Jaccard 0.3 + 向量余弦 0.7）+ Union-Find 聚类 |
| 2.3.7 编排器 + 调度器 | ✅ | 11 步完整管道、APScheduler 15 分钟周期、Semaphore=5 并发控制 |
| 2.3.8 数据源修复 | ✅ | weibo/douyin 改用 xxapi.cn 免登录 API |
| 2.3.9 内容抓取 | ✅ | 7 平台 Scraper（5 实现 + weibo/douyin Stub）、Semaphore=10 并发 |
| 2.3.10 质量过滤 | ✅ | LLM 编号过滤法 + content=description 去重 |
| 2.3.11 热力数据采集 | ✅ | LLM 关键词提取 → Google Trends → 趋势管道 60 分钟周期 |
| 2.3.12 Tag 补充 | ✅ | LLM 15 类分类 + merge_tags 合并算法 |

- [ ] **2.3.13 向量嵌入存储验证** ⏸️ 延后 — pgvector 支持确认、持久化验证、RPC 函数部署
- [ ] **2.3.14 P1/P2 源扩展** ⏸️ 延后 — P1（6 源）+ P2（7 源）实现与数据质量验证

---

#### 2.4 iOS 远程数据层 ✅ + 2.5 平台枚举调整 ✅

**完成日期**：2026-03-06

**交付内容**：
- supabase-swift 2.x SPM 依赖集成
- Secrets.xcconfig 配置（gitignored）+ Info.plist 注入
- Platform 枚举更新：6 → 7 平台（weibo/zhihu/baidu/bilibili-hs/bilibili-hv/douyin/toutiao），移除 xiaohongshu/x/bilibili
- RemoteTrendingDataSource 完全重写（Supabase SDK 查询，5 个方法）
- DTO 层（SupabaseTopicDTO/RankChangeDTO/SupabaseHeatHistoryDTO）
- TrendingRepositoryImpl：isRemoteEnabled=true、TTL 缓存、网络失败降级、搜索直连 Supabase、热度历史懒加载
- DependencyContainer：移除 NetworkClient/refreshAllData、SwiftData schema reset 容错
- MockDataGenerator：更新为 7 平台模板（开发/测试后备）
- DesignSystem：PlatformGradient + PlatformColor 全部更新
- 三端编译通过（iPhone 17 Pro / iPad Pro 13" M5 / macOS signing-only issue）

- [x] **2.4.1 Supabase Swift SDK 集成** ✅
- [x] **2.4.2 RemoteDataSource 实现** ✅
- [x] **2.4.3 缓存与离线策略** ✅ — TTL 15min，网络失败返回过期缓存
- [x] **2.4.4 数据刷新** ✅ — 下拉刷新 forceRefresh、TaskGroup 并行
- [x] **2.4.5 端到端验证** ✅ (2026-03-13) — 模拟器连通 Supabase，数据流通确认

**2.4.5 修复内容**：
- 修复 Supabase URL 双重 `https://` 拼接问题（SupabaseConfig.swift 移除多余前缀）
- 更新 Supabase API Key（旧 JWT → 新 `sb_publishable_` 格式）
- 修复 DTO snake_case 映射（SupabaseTopicDTO/SupabaseHeatHistoryDTO 添加 CodingKeys）
- 清理 14 个编译警告：
  - Comment.swift: 4x `nonisolated(unsafe)` → `nonisolated static let`
  - SupabaseConfig.swift: 1x `nonisolated(unsafe)` → `nonisolated let`
  - TrendingRepositoryImpl.swift: 9x 多余 `await` 移除（LocalDataSource 方法为同步）
  - RankChange: 提取到独立文件，与 `@Model` 上下文解耦

---

## ⚠️ 重要开发原则

**阶段 2 开发原则：**

1. **后端先行**：先完成后端数据采集，确认数据质量，再对接 iOS 端
2. **逐源验证**：每实现一个数据源，立即验证数据完整性和正确性
3. **数据优先于 UI**：先确保数据管道稳定，UI 调整随后进行
4. **保持 Mock 兼容**：iOS 端保留 Mock 数据能力，方便开发调试

**编译要求**

```bash
# iOS Simulator
xcodebuild -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# iPad Simulator
xcodebuild -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=iOS Simulator,name=iPad Pro 13-inch (M5)'

# macOS
xcodebuild -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=macOS'
```

---

## 未来阶段

### 阶段 3：后台刷新 + 通知

- BGTaskScheduler 集成
- 本地通知（热点突发提醒、收藏话题更新）
- 电量和流量优化

### 阶段 5：用户体系（可选）

- BaaS 选型和集成
- 云端偏好同步（收藏、屏蔽词、订阅平台）
- 匿名用户迁移
- 隐私和安全

### 阶段 6：质量与发布

- 单元测试（Domain 90%, Data 80%, Presentation 75%）
- UI 测试
- 性能优化（启动 < 2s, 列表 60fps）
- 深色模式走查、动态字体、VoiceOver（原 Phase 1.5.7 内容）
- 隐私合规
- 发布准备（App Store 提交）

---

## 术语参考

所有项目术语定义见 [TrendLens Technical Architecture.md](TrendLens%20Technical%20Architecture.md) 第 10 章。
