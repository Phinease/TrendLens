import Foundation

/// 用户偏好设置仓库协议
protocol UserPreferenceRepository {

    /// 获取用户偏好设置（仅用于内部实现）
    /// - Returns: 用户偏好实体
    func getUserPreference() async throws -> UserPreferenceEntity

    /// 更新用户偏好设置（仅用于内部实现）
    /// - Parameter preference: 新的偏好设置
    func updateUserPreference(_ preference: UserPreferenceEntity) async throws

    /// 添加收藏话题
    /// - Parameter topicId: 话题 ID
    func addFavorite(topicId: String) async throws

    /// 移除收藏话题
    /// - Parameter topicId: 话题 ID
    func removeFavorite(topicId: String) async throws

    /// 获取所有收藏的话题 ID
    /// - Returns: 收藏的话题 ID 列表
    func getFavoriteTopicIds() async throws -> [String]

    /// 检查话题是否已收藏
    /// - Parameter topicId: 话题 ID
    /// - Returns: 是否已收藏
    func isFavorite(topicId: String) async throws -> Bool

    /// 添加屏蔽词
    /// - Parameter keyword: 屏蔽词
    func addBlockedKeyword(_ keyword: String) async throws

    /// 移除屏蔽词
    /// - Parameter keyword: 屏蔽词
    func removeBlockedKeyword(_ keyword: String) async throws

    /// 获取所有屏蔽词
    /// - Returns: 屏蔽词列表
    func getBlockedKeywords() async throws -> [String]

    /// 更新订阅的平台列表
    /// - Parameter platforms: 新的平台列表
    func updateSubscribedPlatforms(_ platforms: [Platform]) async throws

    /// 获取订阅的平台列表
    /// - Returns: 订阅的平台列表
    func getSubscribedPlatforms() async throws -> [Platform]
}
