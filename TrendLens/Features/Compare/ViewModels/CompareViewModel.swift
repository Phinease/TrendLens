import Foundation
import SwiftUI

/// 对比页 ViewModel
@MainActor
@Observable
final class CompareViewModel {

    // MARK: - Published State

    private(set) var intersectionResults: [ComparisonResult] = []
    private(set) var uniqueResults: [TrendTopicEntity] = []
    private(set) var selectedPlatforms: Set<Platform> = []
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Dependencies

    private let comparePlatformsUseCase: ComparePlatformsUseCase

    // MARK: - Initialization

    init(comparePlatformsUseCase: ComparePlatformsUseCase) {
        self.comparePlatformsUseCase = comparePlatformsUseCase
    }

    // MARK: - Public Methods

    func findIntersection() async {
        guard selectedPlatforms.count >= 2 else { return }

        isLoading = true
        error = nil

        do {
            intersectionResults = try await comparePlatformsUseCase.findIntersection(
                in: Array(selectedPlatforms),
                similarityThreshold: 0.8
            )
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func findUnique(for platform: Platform) async {
        let otherPlatforms = selectedPlatforms.filter { $0 != platform }
        guard !otherPlatforms.isEmpty else { return }

        isLoading = true
        error = nil

        do {
            uniqueResults = try await comparePlatformsUseCase.findUnique(
                in: platform,
                comparedTo: Array(otherPlatforms),
                similarityThreshold: 0.8
            )
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func togglePlatform(_ platform: Platform) {
        if selectedPlatforms.contains(platform) {
            selectedPlatforms.remove(platform)
        } else {
            selectedPlatforms.insert(platform)
        }
    }
}
