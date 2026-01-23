import Foundation
import SwiftUI

/// 设置页 ViewModel
@MainActor
@Observable
final class SettingsViewModel {

    // MARK: - Published State

    private(set) var subscribedPlatforms: [Platform] = []
    private(set) var blockedKeywords: [String] = []
    var refreshInterval: Int = 10
    var isBackgroundRefreshEnabled = true
    private(set) var error: Error?

    // MARK: - Dependencies

    private let preferenceRepository: UserPreferenceRepository

    // MARK: - Initialization

    init(preferenceRepository: UserPreferenceRepository) {
        self.preferenceRepository = preferenceRepository
        Task {
            await loadPreferences()
        }
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

    func togglePlatformSubscription(_ platform: Platform, isSubscribed: Bool) async {
        var platforms = subscribedPlatforms
        if isSubscribed {
            if !platforms.contains(platform) {
                platforms.append(platform)
            }
        } else {
            platforms.removeAll { $0 == platform }
        }

        do {
            try await preferenceRepository.updateSubscribedPlatforms(platforms)
            subscribedPlatforms = platforms
        } catch {
            self.error = error
        }
    }

    func addBlockedKeyword(_ keyword: String) async {
        guard !keyword.isEmpty else { return }

        do {
            try await preferenceRepository.addBlockedKeyword(keyword)
            if !blockedKeywords.contains(keyword) {
                blockedKeywords.append(keyword)
            }
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

    func savePreferences() async {
        // 保存刷新间隔和后台刷新设置
        // 这里可以添加保存逻辑
        print("Saving preferences: refreshInterval=\(refreshInterval), backgroundRefresh=\(isBackgroundRefreshEnabled)")
    }
}
