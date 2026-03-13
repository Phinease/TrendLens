import Foundation
import SwiftData

/// 热榜话题实体
/// 代表单个热榜条目
@Model
final class TrendTopic {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: String

    /// 所属平台
    var platform: Platform

    /// 话题标题
    var title: String

    /// 话题描述（可选）
    var topicDescription: String?

    /// 热度值
    var heatValue: Int

    /// 排名
    var rank: Int

    /// 话题链接（可选）
    var link: String?

    /// 话题标签
    var tags: [String]

    /// 获取时间
    var fetchedAt: Date

    /// 排名变化（新增字段）
    var rankChange: RankChange

    /// 热度历史数据（新增字段，用于绘制曲线）
    var heatHistory: [HeatDataPoint]

    /// AI 摘要（核心信息，必需）
    var summary: String

    /// 所属快照
    var snapshot: TrendSnapshot?

    // MARK: - Initialization

    init(
        id: String = UUID().uuidString,
        platform: Platform,
        title: String,
        topicDescription: String? = nil,
        heatValue: Int,
        rank: Int,
        link: String? = nil,
        tags: [String] = [],
        fetchedAt: Date = Date(),
        rankChange: RankChange = .unchanged,
        heatHistory: [HeatDataPoint] = [],
        summary: String
    ) {
        self.id = id
        self.platform = platform
        self.title = title
        self.topicDescription = topicDescription
        self.heatValue = heatValue
        self.rank = rank
        self.link = link
        self.tags = tags
        self.fetchedAt = fetchedAt
        self.rankChange = rankChange
        self.heatHistory = heatHistory
        self.summary = summary
    }
}

// MARK: - Domain Entity Extension

extension TrendTopic {

    /// 转换为领域实体（如果需要与 SwiftData Model 分离）
    /// 使用保存的 rankChange 和 heatHistory 数据
    func toDomainEntity(
        isFavorite: Bool = false,
        content: String? = nil,
        imageURLs: [String] = [],
        comments: [Comment] = []
    ) -> TrendTopicEntity {
        TrendTopicEntity(
            id: id,
            platform: platform,
            title: title,
            description: topicDescription,
            heatValue: heatValue,
            rank: rank,
            link: link,
            tags: tags,
            fetchedAt: fetchedAt,
            rankChange: rankChange,
            heatHistory: heatHistory,
            summary: summary,
            isFavorite: isFavorite,
            content: content,
            imageURLs: imageURLs,
            comments: comments
        )
    }
}

// MARK: - Pure Domain Entity (Optional)

/// 纯领域实体（不依赖 SwiftData）
struct TrendTopicEntity: Identifiable, Codable, Sendable, Hashable, Equatable {
    let id: String
    let platform: Platform
    let title: String
    let description: String?
    let heatValue: Int
    let rank: Int
    let link: String?
    let tags: [String]
    let fetchedAt: Date

    /// 排名变化
    let rankChange: RankChange

    /// 热度历史数据（用于绘制曲线）
    let heatHistory: [HeatDataPoint]

    /// AI 摘要（核心信息，必需）
    let summary: String

    /// 是否已收藏
    var isFavorite: Bool

    /// 详细新闻内容（可选）
    let content: String?

    /// 图片 URL 列表（可选）
    let imageURLs: [String]

    /// 评论列表（可选）
    let comments: [Comment]

    nonisolated init(
        id: String,
        platform: Platform,
        title: String,
        description: String? = nil,
        heatValue: Int,
        rank: Int,
        link: String? = nil,
        tags: [String] = [],
        fetchedAt: Date = Date(),
        rankChange: RankChange = .unchanged,
        heatHistory: [HeatDataPoint] = [],
        summary: String,
        isFavorite: Bool = false,
        content: String? = nil,
        imageURLs: [String] = [],
        comments: [Comment] = []
    ) {
        self.id = id
        self.platform = platform
        self.title = title
        self.description = description
        self.heatValue = heatValue
        self.rank = rank
        self.link = link
        self.tags = tags
        self.fetchedAt = fetchedAt
        self.rankChange = rankChange
        self.heatHistory = heatHistory
        self.summary = summary
        self.isFavorite = isFavorite
        self.content = content
        self.imageURLs = imageURLs
        self.comments = comments
    }
}
