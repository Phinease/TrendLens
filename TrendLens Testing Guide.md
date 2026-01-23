# TrendLens 测试指南

> 测试策略、技术栈与质量要求。
>
> 单元测试详见 `TrendLensTests Architecture.md`，UI 测试详见 `TrendLensUITests Architecture.md`

---

## 1. 测试金字塔

```
        ┌─────────┐
        │ UI Tests│  ← 少量关键流程
       ─┴─────────┴─
      ┌─────────────┐
      │ Integration │  ← 模块协作
     ─┴─────────────┴─
    ┌─────────────────┐
    │   Unit Tests    │  ← 大量单元测试
    └─────────────────┘
```

---

## 2. 技术栈

| 框架 | 用途 |
|------|------|
| **Swift Testing** | 单元测试、集成测试（`@Test`, `#expect`） |
| **XCTest** | UI 测试、性能测试 |
| **XCUITest** | UI 自动化 |

**选择原则**：单元/集成测试用 Swift Testing，UI/性能测试用 XCTest

---

## 3. 测试范围

| 层级 | 测试对象 | 类型 |
|------|----------|------|
| Domain | Entities, UseCases | Unit |
| Data | Repositories, Mappers, DataSources | Unit + Integration |
| Presentation | ViewModels | Unit |
| Infrastructure | NetworkClient | Unit |
| UI | 关键用户流程 | UI |

---

## 4. 覆盖率要求

| 层级 | 最低 | 目标 |
|------|------|------|
| Domain | 80% | 90% |
| Data | 70% | 80% |
| Presentation | 60% | 75% |
| 整体 | 65% | 80% |

---

## 5. 运行方法

### Xcode

- `Cmd + U`：运行所有测试
- `Ctrl + Opt + Cmd + U`：运行上次失败的测试

### 命令行

```bash
# 单元测试
xcodebuild test -project TrendLens.xcodeproj -scheme TrendLens \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -only-testing:TrendLensTests

# UI 测试
xcodebuild test ... -only-testing:TrendLensUITests

# 覆盖率
xcodebuild test ... -enableCodeCoverage YES
```

---

## 6. 测试规范

### 命名

```
test_[被测方法]_[条件]_[预期结果]
```

### 结构（AAA）

```
Arrange → Act → Assert
```

### Mock 策略

| 被测对象 | Mock 对象 |
|----------|-----------|
| UseCase | MockRepository |
| ViewModel | MockUseCase |
| Repository | MockDataSource |
| Network | MockURLProtocol |

---

## 7. 必测场景

### Domain

- Entity 计算属性
- UseCase 业务逻辑、边界条件

### Data

- Repository 缓存策略（有效/过期/网络失败）
- Mapper 转换正确性

### Presentation

- ViewModel 状态变化
- 错误处理

### UI

- 首页加载、刷新
- 核心用户流程
- 错误/空状态

---

## 8. CI 集成

```yaml
# GitHub Actions 示例
- name: Run Tests
  run: |
    xcodebuild test -project TrendLens.xcodeproj -scheme TrendLens \
      -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
      -enableCodeCoverage YES
```

---

## 9. 最佳实践

1. **独立性**：每个测试互不依赖
2. **可重复**：任何环境结果一致
3. **快速**：单元测试毫秒级
4. **及时**：代码与测试同步编写
5. **Mock 设计**：记录调用 + 配置返回值 + 支持重置
