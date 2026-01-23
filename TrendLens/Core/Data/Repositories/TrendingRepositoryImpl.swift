import Foundation

/// 热榜数据仓库实现
/// 必须在主线程上运行，因为依赖的 LocalTrendingDataSource 使用 ModelContext
@MainActor
final class TrendingRepositoryImpl: TrendingRepository {

    // MARK: - Dependencies

    private let localDataSource: LocalTrendingDataSource
    private let remoteDataSource: RemoteTrendingDataSource

    // MARK: - Configuration

    /// 是否启用远程数据获取（阶段 1 MVP: false, 阶段 2+: true）
    private let isRemoteEnabled = false

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
        print("📊 [TrendingRepositoryImpl] fetchLatestSnapshot - platform: \(platform.rawValue), forceRefresh: \(forceRefresh), remoteEnabled: \(isRemoteEnabled)")

        // 阶段 1 MVP：仅使用本地数据
        if !isRemoteEnabled {
            print("📊 [TrendingRepositoryImpl] Remote disabled - using local data only")

            // 获取本地缓存（即使过期也返回）
            if let cached = try await localDataSource.getLatestSnapshot(for: platform) {
                print("📊 [TrendingRepositoryImpl] Found local snapshot - valid: \(cached.isValid)")
                return cached.toDomainEntity()
            } else {
                print("❌ [TrendingRepositoryImpl] No local data found for \(platform.rawValue)")
                throw AppError.notFound
            }
        }

        // 阶段 2+：支持远程数据获取
        // 1. 如果不强制刷新，先检查本地缓存
        if !forceRefresh {
            if let cached = try await localDataSource.getLatestSnapshot(for: platform),
               cached.isValid {
                print("📊 [TrendingRepositoryImpl] Using valid cache")
                return cached.toDomainEntity()
            }
        }

        // 2. 从远程获取数据
        print("📊 [TrendingRepositoryImpl] Fetching from remote...")
        do {
            let etag = try await localDataSource.getETag(for: platform)
            let snapshot = try await remoteDataSource.fetchSnapshot(
                for: platform,
                etag: etag
            )

            // 3. 保存到本地
            try await localDataSource.saveSnapshot(snapshot)
            print("📊 [TrendingRepositoryImpl] Remote fetch successful")

            return snapshot
        } catch NetworkError.notModified {
            // 304 Not Modified - 返回缓存
            print("📊 [TrendingRepositoryImpl] 304 Not Modified - using cache")
            if let cached = try await localDataSource.getLatestSnapshot(for: platform) {
                return cached.toDomainEntity()
            }
            throw NetworkError.noData
        } catch {
            print("❌ [TrendingRepositoryImpl] Remote fetch failed: \(error)")
            throw error
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
        print("📊 [TrendingRepositoryImpl] searchTopics called - query: \(query), platforms: \(platforms?.map { $0.rawValue } ?? ["all"])")

        do {
            let results = try await localDataSource.searchTopics(query: query, in: platforms)
            print("📊 [TrendingRepositoryImpl] searchTopics completed - found \(results.count) results")
            return results
        } catch {
            print("❌ [TrendingRepositoryImpl] searchTopics failed - error: \(error)")
            throw error
        }
    }

    func getTopicDetail(topicId: String) async throws -> TrendTopicEntity? {
        try await localDataSource.getTopic(by: topicId)?.toDomainEntity()
    }

    func clearExpiredCache() async throws {
        try await localDataSource.clearExpiredSnapshots()
    }
}
