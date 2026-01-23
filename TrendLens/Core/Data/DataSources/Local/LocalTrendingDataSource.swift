import Foundation
import SwiftData

/// 本地热榜数据源（SwiftData）
/// 必须在主线程上运行，因为 ModelContext 不是 Sendable
@MainActor
final class LocalTrendingDataSource {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// 获取指定平台的最新快照
    func getLatestSnapshot(for platform: Platform) throws -> TrendSnapshot? {
        print("📸 [LocalTrendingDataSource] getLatestSnapshot called - platform: \(platform.rawValue)")

        // 获取所有快照，按时间倒序排列
        let descriptor = FetchDescriptor<TrendSnapshot>(
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )

        print("📸 [LocalTrendingDataSource] Fetching all snapshots from ModelContext...")
        let allSnapshots = try modelContext.fetch(descriptor)
        print("📸 [LocalTrendingDataSource] Fetched \(allSnapshots.count) total snapshots")

        // 在内存中过滤指定平台的快照（避免 Predicate 捕获外部变量）
        let snapshot = allSnapshots.first { $0.platform == platform }
        print("📸 [LocalTrendingDataSource] Found snapshot for \(platform.rawValue): \(snapshot != nil)")

        return snapshot
    }

    /// 保存快照
    func saveSnapshot(_ entity: TrendSnapshotEntity) throws {
        // 创建 TrendSnapshot Model
        let snapshot = TrendSnapshot(
            id: entity.id,
            platform: entity.platform,
            fetchedAt: entity.fetchedAt,
            validUntil: entity.validUntil,
            contentHash: entity.contentHash,
            etag: entity.etag,
            schemaVersion: entity.schemaVersion
        )

        // 插入 snapshot 到 ModelContext（必须先插入）
        modelContext.insert(snapshot)

        // 创建 TrendTopic Models 并关联到 snapshot
        let topics = entity.topics.map { topicEntity in
            let topic = TrendTopic(
                id: topicEntity.id,
                platform: topicEntity.platform,
                title: topicEntity.title,
                topicDescription: topicEntity.description,
                heatValue: topicEntity.heatValue,
                rank: topicEntity.rank,
                link: topicEntity.link,
                tags: topicEntity.tags,
                fetchedAt: topicEntity.fetchedAt,
                rankChange: topicEntity.rankChange,
                heatHistory: topicEntity.heatHistory,
                summary: topicEntity.summary
            )
            // 设置关联
            topic.snapshot = snapshot
            return topic
        }

        // 关联 topics 到 snapshot（建立双向关系）
        snapshot.topics = topics

        // 保存
        try modelContext.save()
    }

    /// 获取 ETag
    func getETag(for platform: Platform) throws -> String? {
        let snapshot = try getLatestSnapshot(for: platform)
        return snapshot?.etag
    }

    /// 搜索话题
    func searchTopics(query: String, in platforms: [Platform]?) throws -> [TrendTopicEntity] {
        print("🔍 [LocalTrendingDataSource] searchTopics called - query: \(query), platforms: \(platforms?.map { $0.rawValue } ?? ["all"])")

        // 获取所有话题（避免 Predicate 捕获外部变量导致的 SwiftData 错误）
        let descriptor = FetchDescriptor<TrendTopic>(
            sortBy: [SortDescriptor(\.heatValue, order: .reverse)]
        )

        print("🔍 [LocalTrendingDataSource] Fetching all topics from ModelContext...")
        let allTopics = try modelContext.fetch(descriptor)
        print("🔍 [LocalTrendingDataSource] Fetched \(allTopics.count) total topics")

        // 在内存中过滤查询（避免 Predicate 捕获外部变量）
        let queryLower = query.lowercased()
        var filteredTopics = allTopics.filter { topic in
            topic.title.lowercased().contains(queryLower)
        }
        print("🔍 [LocalTrendingDataSource] After query filter: \(filteredTopics.count) topics")

        // 在内存中过滤平台
        if let platforms = platforms {
            print("🔍 [LocalTrendingDataSource] Filtering by platforms: \(platforms.map { $0.rawValue })")
            filteredTopics = filteredTopics.filter { platforms.contains($0.platform) }
            print("🔍 [LocalTrendingDataSource] After platform filter: \(filteredTopics.count) topics")
        }

        print("🔍 [LocalTrendingDataSource] Converting to domain entities...")
        let entities = filteredTopics.map { $0.toDomainEntity() }
        print("🔍 [LocalTrendingDataSource] Conversion complete, returning \(entities.count) entities")

        return entities
    }

    /// 获取话题详情
    func getTopic(by id: String) throws -> TrendTopic? {
        print("🔖 [LocalTrendingDataSource] getTopic called - id: \(id)")

        // 获取所有话题（为了避免 Predicate 捕获外部变量）
        let descriptor = FetchDescriptor<TrendTopic>()

        print("🔖 [LocalTrendingDataSource] Fetching all topics from ModelContext...")
        let allTopics = try modelContext.fetch(descriptor)
        print("🔖 [LocalTrendingDataSource] Fetched \(allTopics.count) total topics")

        // 在内存中查找指定 ID 的话题
        let topic = allTopics.first { $0.id == id }
        print("🔖 [LocalTrendingDataSource] Found topic with id \(id): \(topic != nil)")

        return topic
    }

    /// 清除过期快照
    func clearExpiredSnapshots() throws {
        print("🗑️ [LocalTrendingDataSource] clearExpiredSnapshots called")
        let now = Date()

        // 获取所有快照（避免 Predicate 捕获外部变量）
        let descriptor = FetchDescriptor<TrendSnapshot>()

        print("🗑️ [LocalTrendingDataSource] Fetching all snapshots from ModelContext...")
        let allSnapshots = try modelContext.fetch(descriptor)
        print("🗑️ [LocalTrendingDataSource] Fetched \(allSnapshots.count) total snapshots")

        // 在内存中过滤过期的快照
        let expiredSnapshots = allSnapshots.filter { $0.validUntil < now }
        print("🗑️ [LocalTrendingDataSource] Found \(expiredSnapshots.count) expired snapshots")

        for snapshot in expiredSnapshots {
            modelContext.delete(snapshot)
        }

        if !expiredSnapshots.isEmpty {
            try modelContext.save()
            print("🗑️ [LocalTrendingDataSource] Deleted \(expiredSnapshots.count) expired snapshots")
        }
    }
}
