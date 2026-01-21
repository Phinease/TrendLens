import Foundation
import SwiftUI

/// 设置页 ViewModel
@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - Published State

    private(set) var subscribedPlatforms: [Platform] = []
    private(set) var blockedKeywords: [String] = []
    private(set) var refreshInterval: Int = 10
    private(set) var isBackgroundRefreshEnabled = true
    private(set) var error: Error?

    // MARK: - Dependencies

    private let preferenceRepository: UserPreferenceRepository

    // MARK: - Initialization

    init(preferenceRepository: UserPreferenceRepository) {
        self.preferenceRepository = preferenceRepository
    }

    // MARK: - Public Methods

    func loadPreferences() async {
        do {
            subscribedPlatforms = try await preferenceRepository.getSubscribedPlatforms()
            blockedKeywords = try await preferenceRepository.getBlockedKeywords()
        } catch {
            self.error = error
        }
    }

    func updateSubscribedPlatforms(_ platforms: [Platform]) async {
        do {
            try await preferenceRepository.updateSubscribedPlatforms(platforms)
            subscribedPlatforms = platforms
        } catch {
            self.error = error
        }
    }

    func addBlockedKeyword(_ keyword: String) async {
        do {
            try await preferenceRepository.addBlockedKeyword(keyword)
            blockedKeywords.append(keyword)
        } catch {
            self.error = error
        }
    }

    func removeBlockedKeyword(_ keyword: String) async {
        do {
            try await preferenceRepository.removeBlockedKeyword(keyword)
            blockedKeywords.removeAll { $0 == keyword }
        } catch {
            self.error = error
        }
    }
}
