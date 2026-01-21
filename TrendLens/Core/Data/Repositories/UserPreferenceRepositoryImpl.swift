import Foundation

/// 用户偏好设置仓库实现
actor UserPreferenceRepositoryImpl: UserPreferenceRepository {

    // MARK: - Dependencies

    private let localDataSource: LocalUserPreferenceDataSource

    // MARK: - Initialization

    init(localDataSource: LocalUserPreferenceDataSource) {
        self.localDataSource = localDataSource
    }

    // MARK: - UserPreferenceRepository

    func getUserPreference() async throws -> UserPreference {
        try await localDataSource.getPreference()
    }

    func updateUserPreference(_ preference: UserPreference) async throws {
        try await localDataSource.savePreference(preference)
    }

    func addFavorite(topicId: String) async throws {
        let preference = try await getUserPreference()
        preference.addFavorite(topicId: topicId)
        try await updateUserPreference(preference)
    }

    func removeFavorite(topicId: String) async throws {
        let preference = try await getUserPreference()
        preference.removeFavorite(topicId: topicId)
        try await updateUserPreference(preference)
    }

    func getFavoriteTopicIds() async throws -> [String] {
        let preference = try await getUserPreference()
        return preference.favoriteTopicIds
    }

    func isFavorite(topicId: String) async throws -> Bool {
        let preference = try await getUserPreference()
        return preference.isFavorite(topicId: topicId)
    }

    func addBlockedKeyword(_ keyword: String) async throws {
        let preference = try await getUserPreference()
        preference.addBlockedKeyword(keyword)
        try await updateUserPreference(preference)
    }

    func removeBlockedKeyword(_ keyword: String) async throws {
        let preference = try await getUserPreference()
        preference.removeBlockedKeyword(keyword)
        try await updateUserPreference(preference)
    }

    func getBlockedKeywords() async throws -> [String] {
        let preference = try await getUserPreference()
        return preference.blockedKeywords
    }

    func updateSubscribedPlatforms(_ platforms: [Platform]) async throws {
        let preference = try await getUserPreference()
        preference.subscribedPlatforms = platforms
        preference.updatedAt = Date()
        try await updateUserPreference(preference)
    }

    func getSubscribedPlatforms() async throws -> [Platform] {
        let preference = try await getUserPreference()
        return preference.subscribedPlatforms
    }
}
