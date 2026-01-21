import Foundation
import SwiftData

/// 用户偏好设置实体
@Model
final class UserPreference {

    // MARK: - Properties

    /// 唯一标识符
    @Attribute(.unique) var id: String

    /// 收藏的话题 ID 列表
    var favoriteTopicIds: [String]

    /// 屏蔽词列表
    var blockedKeywords: [String]

    /// 订阅的平台列表
    var subscribedPlatforms: [Platform]

    /// 刷新间隔（分钟）
    var refreshInterval: Int

    /// 是否启用后台刷新
    var isBackgroundRefreshEnabled: Bool

    /// 排序方式
    var sortOrder: SortOrder

    /// 创建时间
    var createdAt: Date

    /// 最后更新时间
    var updatedAt: Date

    // MARK: - Initialization

    init(
        id: String = "default",
        favoriteTopicIds: [String] = [],
        blockedKeywords: [String] = [],
        subscribedPlatforms: [Platform] = Platform.allCases,
        refreshInterval: Int = 10,
        isBackgroundRefreshEnabled: Bool = true,
        sortOrder: SortOrder = .heat,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.favoriteTopicIds = favoriteTopicIds
        self.blockedKeywords = blockedKeywords
        self.subscribedPlatforms = subscribedPlatforms
        self.refreshInterval = refreshInterval
        self.isBackgroundRefreshEnabled = isBackgroundRefreshEnabled
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Sort Order

/// 排序方式
enum SortOrder: String, Codable, CaseIterable, Sendable {
    case heat           // 按热度
    case time           // 按时间
    case platform       // 按平台

    var displayName: String {
        switch self {
        case .heat: return "热度优先"
        case .time: return "时间优先"
        case .platform: return "平台分组"
        }
    }
}

// MARK: - Domain Entity Extension

extension UserPreference {

    /// 添加收藏
    func addFavorite(topicId: String) {
        if !favoriteTopicIds.contains(topicId) {
            favoriteTopicIds.append(topicId)
            updatedAt = Date()
        }
    }

    /// 移除收藏
    func removeFavorite(topicId: String) {
        favoriteTopicIds.removeAll { $0 == topicId }
        updatedAt = Date()
    }

    /// 检查是否已收藏
    func isFavorite(topicId: String) -> Bool {
        favoriteTopicIds.contains(topicId)
    }

    /// 添加屏蔽词
    func addBlockedKeyword(_ keyword: String) {
        if !blockedKeywords.contains(keyword) {
            blockedKeywords.append(keyword)
            updatedAt = Date()
        }
    }

    /// 移除屏蔽词
    func removeBlockedKeyword(_ keyword: String) {
        blockedKeywords.removeAll { $0 == keyword }
        updatedAt = Date()
    }

    /// 检查话题是否包含屏蔽词
    func containsBlockedKeyword(in text: String) -> Bool {
        blockedKeywords.contains { keyword in
            text.lowercased().contains(keyword.lowercased())
        }
    }
}
