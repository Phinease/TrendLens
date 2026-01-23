import Foundation
import SwiftData

/// 本地用户偏好设置数据源（SwiftData）
/// 必须在主线程上运行，因为 ModelContext 不是 Sendable
@MainActor
final class LocalUserPreferenceDataSource {

    // MARK: - Dependencies

    private let modelContext: ModelContext

    // MARK: - Constants

    private let defaultPreferenceId = "default"

    // MARK: - Initialization

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Public Methods

    /// 获取用户偏好设置
    func getPreference() throws -> UserPreference {
        // 获取所有偏好设置（避免 Predicate 捕获外部变量导致的 SwiftData 错误）
        let descriptor = FetchDescriptor<UserPreference>()
        let allPreferences = try modelContext.fetch(descriptor)

        // 在内存中过滤指定 ID 的偏好设置
        if let preference = allPreferences.first(where: { $0.id == defaultPreferenceId }) {
            return preference
        } else {
            // 创建默认偏好设置
            let defaultPreference = UserPreference()
            modelContext.insert(defaultPreference)
            try modelContext.save()
            return defaultPreference
        }
    }

    /// 保存用户偏好设置
    func savePreference(_ preference: UserPreference) throws {
        preference.updatedAt = Date()
        try modelContext.save()
    }
}
