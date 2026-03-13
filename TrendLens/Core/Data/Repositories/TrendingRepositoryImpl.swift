import Foundation

/// 热榜数据仓库实现
/// 必须在主线程上运行，因为依赖的 LocalTrendingDataSource 使用 ModelContext
@MainActor
final class TrendingRepositoryImpl: TrendingRepository {

    // MARK: - Dependencies

    private let localDataSource: LocalTrendingDataSource
    private let remoteDataSource: RemoteTrendingDataSource

    // MARK: - Configuration

    /// 是否启用远程数据获取
    private let isRemoteEnabled: Bool

    // MARK: - Initialization

    init(
        localDataSource: LocalTrendingDataSource,
        remoteDataSource: RemoteTrendingDataSource,
        isRemoteEnabled: Bool = true
    ) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
        self.isRemoteEnabled = isRemoteEnabled
    }

    // MARK: - TrendingRepository

    func fetchLatestSnapshot(
        for platform: Platform,
        forceRefresh: Bool
    ) async throws -> TrendSnapshotEntity {
        // If remote disabled, use local only
        if !isRemoteEnabled {
            if let cached = try localDataSource.getLatestSnapshot(for: platform) {
                return cached.toDomainEntity()
            } else {
                throw AppError.notFound
            }
        }

        // Check local cache first (unless force refresh)
        if !forceRefresh {
            if let cached = try localDataSource.getLatestSnapshot(for: platform),
               cached.isValid {
                return cached.toDomainEntity()
            }
        }

        // Fetch from Supabase
        do {
            let snapshot = try await remoteDataSource.fetchSnapshot(for: platform)
            try localDataSource.saveSnapshot(snapshot)
            return snapshot
        } catch {
            // Fall back to stale cache on network failure
            if let cached = try? localDataSource.getLatestSnapshot(for: platform) {
                return cached.toDomainEntity()
            }
            throw AppError.network(underlying: error)
        }
    }

    func fetchLatestSnapshots(
        for platforms: [Platform],
        forceRefresh: Bool
    ) async throws -> [TrendSnapshotEntity] {
        try await withThrowingTaskGroup(of: TrendSnapshotEntity.self) { group in
            for platform in platforms {
                group.addTask {
                    try await self.fetchLatestSnapshot(
                        for: platform,
                        forceRefresh: forceRefresh
                    )
                }
            }

            var snapshots: [TrendSnapshotEntity] = []
            for try await snapshot in group {
                snapshots.append(snapshot)
            }

            return snapshots
        }
    }

    func fetchAllLatestSnapshots(
        forceRefresh: Bool
    ) async throws -> [TrendSnapshotEntity] {
        try await fetchLatestSnapshots(
            for: Platform.allCases,
            forceRefresh: forceRefresh
        )
    }

    func getCachedSnapshot(
        for platform: Platform
    ) async throws -> TrendSnapshotEntity? {
        try localDataSource.getLatestSnapshot(for: platform)?.toDomainEntity()
    }

    func searchTopics(
        query: String,
        in platforms: [Platform]?
    ) async throws -> [TrendTopicEntity] {
        if isRemoteEnabled {
            do {
                let dtos = try await remoteDataSource.searchTopics(query: query, platforms: platforms)
                return dtos.map { remoteDataSource.mapToEntity($0) }
            } catch {
                // Fall back to local search
                return try localDataSource.searchTopics(query: query, in: platforms)
            }
        }
        return try localDataSource.searchTopics(query: query, in: platforms)
    }

    func getTopicDetail(topicId: String) async throws -> TrendTopicEntity? {
        guard var topic = try localDataSource.getTopic(by: topicId)?.toDomainEntity() else {
            return nil
        }

        // Lazy load heat history from Supabase
        if isRemoteEnabled {
            let history = try? await remoteDataSource.fetchHeatHistory(for: topicId)
            if let history, !history.isEmpty {
                topic = TrendTopicEntity(
                    id: topic.id,
                    platform: topic.platform,
                    title: topic.title,
                    description: topic.description,
                    heatValue: topic.heatValue,
                    rank: topic.rank,
                    link: topic.link,
                    tags: topic.tags,
                    fetchedAt: topic.fetchedAt,
                    rankChange: topic.rankChange,
                    heatHistory: history,
                    summary: topic.summary,
                    isFavorite: topic.isFavorite,
                    content: topic.content,
                    imageURLs: topic.imageURLs,
                    comments: topic.comments
                )
            }
        }

        return topic
    }

    func clearExpiredCache() async throws {
        try localDataSource.clearExpiredSnapshots()
    }
}
