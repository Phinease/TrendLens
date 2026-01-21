import Foundation
import SwiftData

/// 热榜快照实体
/// 代表某个平台在某个时间点的热榜快照
@Model
final class TrendSnapshot {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: String

    /// 所属平台
    var platform: Platform

    /// 快照获取时间
    var fetchedAt: Date

    /// 快照有效期（TTL）
    var validUntil: Date

    /// 快照哈希值（用于去重）
    var contentHash: String

    /// ETag（用于缓存控制）
    var etag: String?

    /// 数据版本号
    var schemaVersion: Int

    /// 快照包含的话题列表
    @Relationship(deleteRule: .cascade, inverse: \TrendTopic.snapshot)
    var topics: [TrendTopic]

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        platform: Platform,
        fetchedAt: Date = Date(),
        validUntil: Date,
        contentHash: String,
        etag: String? = nil,
        schemaVersion: Int = 1,
        topics: [TrendTopic] = []
    ) {
        self.id = id
        self.platform = platform
        self.fetchedAt = fetchedAt
        self.validUntil = validUntil
        self.contentHash = contentHash
        self.etag = etag
        self.schemaVersion = schemaVersion
        self.topics = topics
    }
}

// MARK: - Computed Properties

extension TrendSnapshot {

    /// 快照是否已过期
    var isExpired: Bool {
        Date() > validUntil
    }

    /// 快照是否有效
    var isValid: Bool {
        !isExpired
    }

    /// 剩余有效时间（秒）
    var remainingValidity: TimeInterval {
        validUntil.timeIntervalSince(Date())
    }
}

// MARK: - Domain Entity Extension

extension TrendSnapshot {

    /// 转换为领域实体
    func toDomainEntity() -> TrendSnapshotEntity {
        TrendSnapshotEntity(
            id: id,
            platform: platform,
            fetchedAt: fetchedAt,
            validUntil: validUntil,
            contentHash: contentHash,
            etag: etag,
            schemaVersion: schemaVersion,
            topics: topics.map { $0.toDomainEntity() }
        )
    }
}

// MARK: - Pure Domain Entity

/// 纯领域实体（不依赖 SwiftData）
struct TrendSnapshotEntity: Identifiable, Codable, Sendable {
    let id: String
    let platform: Platform
    let fetchedAt: Date
    let validUntil: Date
    let contentHash: String
    let etag: String?
    let schemaVersion: Int
    let topics: [TrendTopicEntity]

    var isExpired: Bool {
        Date() > validUntil
    }

    var isValid: Bool {
        !isExpired
    }
}
