import Foundation

/// 获取热榜用例
/// 负责获取和刷新热榜数据
struct FetchTrendingUseCase: Sendable {

    // MARK: - Dependencies

    private let repository: TrendingRepository

    // MARK: - Initialization

    init(repository: TrendingRepository) {
        self.repository = repository
    }

    // MARK: - Use Case Methods

    /// 获取指定平台的最新热榜
    /// - Parameters:
    ///   - platform: 平台
    ///   - forceRefresh: 是否强制刷新
    /// - Returns: 热榜快照
    func execute(
        for platform: Platform,
        forceRefresh: Bool = false
    ) async throws -> TrendSnapshotEntity {
        try await repository.fetchLatestSnapshot(
            for: platform,
            forceRefresh: forceRefresh
        )
    }

    /// 获取多个平台的最新热榜
    /// - Parameters:
    ///   - platforms: 平台列表
    ///   - forceRefresh: 是否强制刷新
    /// - Returns: 热榜快照列表
    func execute(
        for platforms: [Platform],
        forceRefresh: Bool = false
    ) async throws -> [TrendSnapshotEntity] {
        try await repository.fetchLatestSnapshots(
            for: platforms,
            forceRefresh: forceRefresh
        )
    }

    /// 获取所有平台的最新热榜
    /// - Parameter forceRefresh: 是否强制刷新
    /// - Returns: 热榜快照列表
    func executeForAll(
        forceRefresh: Bool = false
    ) async throws -> [TrendSnapshotEntity] {
        try await repository.fetchAllLatestSnapshots(forceRefresh: forceRefresh)
    }

    /// 获取聚合的热榜话题（去重、排序）
    /// - Parameters:
    ///   - platforms: 平台列表（nil 表示全部）
    ///   - sortBy: 排序方式
    ///   - forceRefresh: 是否强制刷新
    /// - Returns: 聚合后的话题列表
    func executeAggregated(
        for platforms: [Platform]? = nil,
        sortBy: SortOrder = .heat,
        forceRefresh: Bool = false
    ) async throws -> [TrendTopicEntity] {
        let snapshots: [TrendSnapshotEntity]

        if let platforms = platforms {
            snapshots = try await execute(for: platforms, forceRefresh: forceRefresh)
        } else {
            snapshots = try await executeForAll(forceRefresh: forceRefresh)
        }

        // 展平所有话题
        var allTopics = snapshots.flatMap { $0.topics }

        // 根据排序方式排序
        switch sortBy {
        case .heat:
            allTopics.sort { $0.heatValue > $1.heatValue }
        case .time:
            allTopics.sort { $0.fetchedAt > $1.fetchedAt }
        case .platform:
            allTopics.sort { $0.platform.displayName < $1.platform.displayName }
        }

        return allTopics
    }
}
