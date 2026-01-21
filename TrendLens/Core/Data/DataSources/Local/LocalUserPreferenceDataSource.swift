import Foundation
import SwiftData

/// 本地用户偏好设置数据源（SwiftData）
actor LocalUserPreferenceDataSource {

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
        let descriptor = FetchDescriptor<UserPreference>(
            predicate: #Predicate { $0.id == defaultPreferenceId }
        )

        if let preference = try modelContext.fetch(descriptor).first {
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
