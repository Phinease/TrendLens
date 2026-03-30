//
//  LocalTrendingDataSource.swift
//  TrendLens
//

import Foundation
import OSLog
import SwiftData

/// 本地热榜数据源（SwiftData）
@MainActor
final class LocalTrendingDataSource {

    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Snapshots

    func getLatestSnapshot(for platform: Platform) throws -> TrendSnapshot? {
        let descriptor = FetchDescriptor<TrendSnapshot>(
            sortBy: [SortDescriptor(\.fetchedAt, order: .reverse)]
        )
        let allSnapshots = try modelContext.fetch(descriptor)
        let snapshot = allSnapshots.first { $0.platform == platform }
        AppLog.cache.debug("LOCAL_SNAPSHOT platform=\(platform.rawValue) found=\(snapshot != nil) total=\(allSnapshots.count)")
        return snapshot
    }

    func saveSnapshot(_ entity: TrendSnapshotEntity) throws {
        let snapshot = TrendSnapshot(
            id: entity.id,
            platform: entity.platform,
            fetchedAt: entity.fetchedAt,
            validUntil: entity.validUntil,
            contentHash: entity.contentHash,
            etag: entity.etag,
            schemaVersion: entity.schemaVersion
        )

        modelContext.insert(snapshot)

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
            topic.snapshot = snapshot
            return topic
        }
        snapshot.topics = topics
        try modelContext.save()
        AppLog.cache.info("LOCAL_SAVE platform=\(entity.platform.rawValue) topics=\(entity.topics.count)")
    }

    func getETag(for platform: Platform) throws -> String? {
        try getLatestSnapshot(for: platform)?.etag
    }

    // MARK: - Topics

    func searchTopics(query: String, in platforms: [Platform]?) throws -> [TrendTopicEntity] {
        let descriptor = FetchDescriptor<TrendTopic>(
            sortBy: [SortDescriptor(\.heatValue, order: .reverse)]
        )
        let allTopics = try modelContext.fetch(descriptor)
        let queryLower = query.lowercased()

        var filtered = allTopics.filter { $0.title.lowercased().contains(queryLower) }
        if let platforms {
            filtered = filtered.filter { platforms.contains($0.platform) }
        }

        AppLog.cache.debug("LOCAL_SEARCH query=\(query) results=\(filtered.count)")
        return filtered.map { $0.toDomainEntity() }
    }

    func getTopic(by id: String) throws -> TrendTopic? {
        let descriptor = FetchDescriptor<TrendTopic>()
        let allTopics = try modelContext.fetch(descriptor)
        return allTopics.first { $0.id == id }
    }

    // MARK: - Cleanup

    func clearExpiredSnapshots() throws {
        let now = Date.now
        let descriptor = FetchDescriptor<TrendSnapshot>()
        let allSnapshots = try modelContext.fetch(descriptor)
        let expired = allSnapshots.filter { $0.validUntil < now }

        for snapshot in expired {
            modelContext.delete(snapshot)
        }
        if !expired.isEmpty {
            try modelContext.save()
            AppLog.cache.info("LOCAL_CLEANUP deleted=\(expired.count) expired snapshots")
        }
    }
}
