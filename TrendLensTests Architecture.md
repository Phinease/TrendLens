# TrendLensTests 单元测试架构

> 使用 Swift Testing 框架的单元测试规范。
>
> 测试策略总览见 `TrendLens Testing Guide.md`

---

## 1. 目录结构

```
TrendLensTests/
├── Domain/
│   ├── Entities/          # TopicTests, SnapshotTests, PlatformTests
│   └── UseCases/          # FetchTrendingUseCaseTests, ComparePlatformsUseCaseTests
├── Data/
│   ├── Repositories/      # TrendingRepositoryTests
│   ├── DataSources/       # TopicLocalDataSourceTests, TrendingRemoteDataSourceTests
│   └── Mappers/           # TopicMapperTests
├── Presentation/
│   └── [Feature]/         # FeedViewModelTests, CompareViewModelTests
├── Infrastructure/
│   └── Network/           # NetworkClientTests
├── Mocks/                 # Mock 对象
└── Helpers/               # TestData, TestModelContainer
```

---

## 2. 测试范围

| 层级 | 测试对象 | Mock 对象 |
|------|----------|-----------|
| Domain/Entities | 计算属性、Equatable、Codable | 无 |
| Domain/UseCases | 业务逻辑、过滤、排序 | MockRepository |
| Data/Repositories | 缓存策略、错误处理、数据协调 | MockDataSource |
| Data/Mappers | DTO↔Entity↔Model 转换 | 无 |
| Presentation/ViewModels | 状态变化、错误处理 | MockUseCase |
| Infrastructure/Network | 请求构建、响应解析、错误映射 | MockURLProtocol |

---

## 3. 测试规范

### 3.1 命名

```
test_[被测方法]_[条件]_[预期结果]
// 例: test_rankChange_whenRankImproved_returnsUp
```

### 3.2 结构（AAA 模式）

```swift
@Test func methodName_condition_expectedResult() async throws {
    // Arrange - 准备数据和 Mock
    // Act - 执行被测方法
    // Assert - 验证结果
}
```

### 3.3 断言

- `#expect(value == expected)`
- `#expect(throws: ErrorType.self) { ... }`
- `#expect(array.isEmpty)`

### 3.4 参数化测试

```swift
@Test("描述", arguments: [case1, case2, case3])
func testMethod(input: Type) { }
```

---

## 4. Mock 设计原则

### 4.1 Mock Repository 结构

```
MockTrendingRepository:
  - 调用记录: fetchTopicsCalled, fetchTopicsArguments
  - 返回值配置: fetchTopicsResult: Result<[Topic], Error>
  - 重置方法: reset()
```

### 4.2 Mock 策略

- UseCase 测试 → Mock Repository
- ViewModel 测试 → Mock UseCase  
- Repository 测试 → Mock DataSource
- Network 测试 → MockURLProtocol

---

## 5. 辅助工具

### 5.1 TestData 工厂

提供静态方法创建测试数据：

- `makeTopic(id:, title:, rank:, platform:)`
- `makeSnapshot(platform:, topicCount:)`
- `makeUserPreference(blockedKeywords:)`

### 5.2 内存 SwiftData 容器

`TestModelContainer.create()` 返回 `isStoredInMemoryOnly: true` 的容器

### 5.3 MockURLProtocol

拦截网络请求，返回预设响应/错误

---

## 6. 关键测试场景

### Entities

- 计算属性（rankChange: up/down/same/new）
- 缓存过期判断（isExpired）

### UseCases

- 正常获取数据
- 屏蔽词过滤
- 排序规则应用
- 错误传播

### Repositories

- 缓存有效时不请求网络
- 缓存过期时请求网络
- 强制刷新时总是请求网络
- 网络失败时返回过期缓存
- 304 时返回缓存

### ViewModels

- 初始状态正确
- 加载时设置 isLoading
- 成功后更新数据
- 失败后设置 error
- 重复加载保护
