import Foundation

/// 热榜数据仓库实现
actor TrendingRepositoryImpl: TrendingRepository {

    // MARK: - Dependencies

    private let localDataSource: LocalTrendingDataSource
    private let remoteDataSource: RemoteTrendingDataSource

    // MARK: - Initialization

    init(
        localDataSource: LocalTrendingDataSource,
        remoteDataSource: RemoteTrendingDataSource
    ) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
    }

    // MARK: - TrendingRepository

    func fetchLatestSnapshot(
        for platform: Platform,
        forceRefresh: Bool
    ) async throws -> TrendSnapshotEntity {
        // 1. 如果不强制刷新，先检查本地缓存
        if !forceRefresh {
            if let cached = try await localDataSource.getLatestSnapshot(for: platform),
               cached.isValid {
                return cached.toDomainEntity()
            }
        }

        // 2. 从远程获取数据
        do {
            let etag = try await localDataSource.getETag(for: platform)
            let snapshot = try await remoteDataSource.fetchSnapshot(
                for: platform,
                etag: etag
            )

            // 3. 保存到本地
            try await localDataSource.saveSnapshot(snapshot)

            return snapshot
        } catch NetworkError.notModified {
            // 304 Not Modified - 返回缓存
            if let cached = try await localDataSource.getLatestSnapshot(for: platform) {
                return cached.toDomainEntity()
            }
            throw NetworkError.noData
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
        try await localDataSource.getLatestSnapshot(for: platform)?.toDomainEntity()
    }

    func searchTopics(
        query: String,
        in platforms: [Platform]?
    ) async throws -> [TrendTopicEntity] {
        try await localDataSource.searchTopics(query: query, in: platforms)
    }

    func getTopicDetail(topicId: String) async throws -> TrendTopicEntity? {
        try await localDataSource.getTopic(by: topicId)?.toDomainEntity()
    }

    func clearExpiredCache() async throws {
        try await localDataSource.clearExpiredSnapshots()
    }
}
