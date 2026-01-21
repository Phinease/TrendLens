import Foundation
import SwiftData

/// 本地热榜数据源（SwiftData）
actor LocalTrendingDataSource {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// 获取指定平台的最新快照
    func getLatestSnapshot(for platform: Platform) throws -> TrendSnapshot? {
        let descriptor = FetchDescriptor<TrendSnapshot>(
            predicate: #Predicate { $0.platform == platform },
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )

        let snapshots = try modelContext.fetch(descriptor)
        return snapshots.first
    }

    /// 保存快照
    func saveSnapshot(_ entity: TrendSnapshotEntity) throws {
        // FIXME: 实现从 Entity 转换为 SwiftData Model 并保存
        // 这里需要创建 TrendSnapshot 和 TrendTopic 实例
        throw NSError(domain: "LocalTrendingDataSource", code: -1, userInfo: [NSLocalizedDescriptionKey: "Not implemented"])
    }

    /// 获取 ETag
    func getETag(for platform: Platform) throws -> String? {
        let snapshot = try getLatestSnapshot(for: platform)
        return snapshot?.etag
    }

    /// 搜索话题
    func searchTopics(query: String, in platforms: [Platform]?) throws -> [TrendTopicEntity] {
        var predicate: Predicate<TrendTopic>

        if let platforms = platforms {
            predicate = #Predicate { topic in
                platforms.contains(topic.platform) &&
                topic.title.localizedStandardContains(query)
            }
        } else {
            predicate = #Predicate { topic in
                topic.title.localizedStandardContains(query)
            }
        }

        let descriptor = FetchDescriptor<TrendTopic>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.heatValue, order: .reverse)]
        )

        let topics = try modelContext.fetch(descriptor)
        return topics.map { $0.toDomainEntity() }
    }

    /// 获取话题详情
    func getTopic(by id: String) throws -> TrendTopic? {
        let descriptor = FetchDescriptor<TrendTopic>(
            predicate: #Predicate { $0.id == id }
        )

        return try modelContext.fetch(descriptor).first
    }

    /// 清除过期快照
    func clearExpiredSnapshots() throws {
        let now = Date()
        let descriptor = FetchDescriptor<TrendSnapshot>(
            predicate: #Predicate { $0.validUntil < now }
        )

        let expiredSnapshots = try modelContext.fetch(descriptor)

        for snapshot in expiredSnapshots {
            modelContext.delete(snapshot)
        }

        try modelContext.save()
    }
}
