import Foundation

/// 用户偏好设置仓库实现
/// 必须在主线程上运行，因为依赖的 LocalUserPreferenceDataSource 使用 ModelContext
@MainActor
final class UserPreferenceRepositoryImpl: UserPreferenceRepository {

    // MARK: - Dependencies

    private let localDataSource: LocalUserPreferenceDataSource

    // MARK: - Initialization

    init(localDataSource: LocalUserPreferenceDataSource) {
        self.localDataSource = localDataSource
    }

    // MARK: - UserPreferenceRepository

    func getUserPreference() async throws -> UserPreferenceEntity {
        let preference = try localDataSource.getPreference()
        return preference.toDomainEntity()
    }

    func updateUserPreference(_ entity: UserPreferenceEntity) async throws {
        // 获取现有的 Model 对象
        let preference = try localDataSource.getPreference()

        // 更新属性
        preference.favoriteTopicIds = entity.favoriteTopicIds
        preference.blockedKeywords = entity.blockedKeywords
        preference.subscribedPlatforms = entity.subscribedPlatforms
        preference.refreshInterval = entity.refreshInterval
        preference.isBackgroundRefreshEnabled = entity.isBackgroundRefreshEnabled
        preference.sortOrder = entity.sortOrder
        preference.updatedAt = Date()

        // 保存
        try localDataSource.savePreference(preference)
    }

    func addFavorite(topicId: String) async throws {
        var entity = try await getUserPreference()
        if !entity.favoriteTopicIds.contains(topicId) {
            entity.favoriteTopicIds.append(topicId)
            entity.updatedAt = Date()
            try await updateUserPreference(entity)
        }
    }

    func removeFavorite(topicId: String) async throws {
        var entity = try await getUserPreference()
        entity.favoriteTopicIds.removeAll { $0 == topicId }
        entity.updatedAt = Date()
        try await updateUserPreference(entity)
    }

    func getFavoriteTopicIds() async throws -> [String] {
        let entity = try await getUserPreference()
        return entity.favoriteTopicIds
    }

    func isFavorite(topicId: String) async throws -> Bool {
        let entity = try await getUserPreference()
        return entity.favoriteTopicIds.contains(topicId)
    }

    func addBlockedKeyword(_ keyword: String) async throws {
        var entity = try await getUserPreference()
        if !entity.blockedKeywords.contains(keyword) {
            entity.blockedKeywords.append(keyword)
            entity.updatedAt = Date()
            try await updateUserPreference(entity)
        }
    }

    func removeBlockedKeyword(_ keyword: String) async throws {
        var entity = try await getUserPreference()
        entity.blockedKeywords.removeAll { $0 == keyword }
        entity.updatedAt = Date()
        try await updateUserPreference(entity)
    }

    func getBlockedKeywords() async throws -> [String] {
        let entity = try await getUserPreference()
        return entity.blockedKeywords
    }

    func updateSubscribedPlatforms(_ platforms: [Platform]) async throws {
        var entity = try await getUserPreference()
        entity.subscribedPlatforms = platforms
        entity.updatedAt = Date()
        try await updateUserPreference(entity)
    }

    func getSubscribedPlatforms() async throws -> [Platform] {
        let entity = try await getUserPreference()
        return entity.subscribedPlatforms
    }
}
