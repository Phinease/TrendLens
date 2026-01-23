import Foundation

/// 管理收藏用例
struct ManageFavoritesUseCase {

    // MARK: - Dependencies

    private let trendingRepository: TrendingRepository
    private let preferenceRepository: UserPreferenceRepository

    // MARK: - Initialization

    init(
        trendingRepository: TrendingRepository,
        preferenceRepository: UserPreferenceRepository
    ) {
        self.trendingRepository = trendingRepository
        self.preferenceRepository = preferenceRepository
    }

    // MARK: - Use Case Methods

    /// 添加收藏
    /// - Parameter topicId: 话题 ID
    func addFavorite(topicId: String) async throws {
        try await preferenceRepository.addFavorite(topicId: topicId)
    }

    /// 移除收藏
    /// - Parameter topicId: 话题 ID
    func removeFavorite(topicId: String) async throws {
        try await preferenceRepository.removeFavorite(topicId: topicId)
    }

    /// 获取所有收藏的话题
    /// - Returns: 收藏的话题列表
    func getFavoriteTopics() async throws -> [TrendTopicEntity] {
        let favoriteIds = try await preferenceRepository.getFavoriteTopicIds()

        var topics: [TrendTopicEntity] = []
        for id in favoriteIds {
            if let topic = try await trendingRepository.getTopicDetail(topicId: id) {
                topics.append(topic)
            }
        }

        return topics
    }

    /// 检查话题是否已收藏
    /// - Parameter topicId: 话题 ID
    /// - Returns: 是否已收藏
    func isFavorite(topicId: String) async throws -> Bool {
        try await preferenceRepository.isFavorite(topicId: topicId)
    }
}
