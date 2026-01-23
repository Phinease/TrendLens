import Foundation

/// 搜索热榜用例
struct SearchTrendingUseCase {

    // MARK: - Dependencies

    private let repository: TrendingRepository

    // MARK: - Initialization

    init(repository: TrendingRepository) {
        self.repository = repository
    }

    // MARK: - Use Case Methods

    /// 搜索话题
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - platforms: 限定平台（nil 表示全部）
    /// - Returns: 匹配的话题列表
    func execute(
        query: String,
        in platforms: [Platform]? = nil
    ) async throws -> [TrendTopicEntity] {
        try await repository.searchTopics(query: query, in: platforms)
    }
}
