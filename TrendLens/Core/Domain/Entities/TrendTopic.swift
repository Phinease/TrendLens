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
        fetchedAt: Date = Date()
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
    }
}

// MARK: - Domain Entity Extension

extension TrendTopic {

    /// 转换为领域实体（如果需要与 SwiftData Model 分离）
    func toDomainEntity(
        rankChange: RankChange = .unchanged,
        heatHistory: [HeatDataPoint] = [],
        isFavorite: Bool = false
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
            isFavorite: isFavorite
        )
    }
}

// MARK: - Rank Change Type

/// 排名变化类型
enum RankChange: Codable, Sendable, Equatable {
    /// 新上榜
    case new
    /// 排名上升（包含上升的位数）
    case up(Int)
    /// 排名下降（包含下降的位数）
    case down(Int)
    /// 排名不变
    case unchanged

    /// 变化值（上升为正，下降为负，新上榜和不变为0）
    var value: Int {
        switch self {
        case .new, .unchanged: return 0
        case .up(let n): return n
        case .down(let n): return -n
        }
    }

    /// 是否为正向变化
    var isPositive: Bool {
        switch self {
        case .new, .up: return true
        case .down, .unchanged: return false
        }
    }
}

// MARK: - Pure Domain Entity (Optional)

/// 纯领域实体（不依赖 SwiftData）
struct TrendTopicEntity: Identifiable, Codable, Sendable {
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

    /// 是否已收藏
    var isFavorite: Bool

    init(
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
        isFavorite: Bool = false
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
        self.isFavorite = isFavorite
    }
}
