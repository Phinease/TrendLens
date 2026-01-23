import Foundation
import SwiftUI

/// 对比页 ViewModel
@MainActor
@Observable
final class CompareViewModel {

    // MARK: - Published State

    private(set) var intersectionTopics: [TrendTopicEntity] = []
    private(set) var uniqueTopics: [Platform: [TrendTopicEntity]] = [:]
    private(set) var isLoading = false
    private(set) var error: Error?

    // MARK: - Dependencies

    private let comparePlatformsUseCase: ComparePlatformsUseCase

    // MARK: - Initialization

    init(comparePlatformsUseCase: ComparePlatformsUseCase) {
        self.comparePlatformsUseCase = comparePlatformsUseCase
    }

    // MARK: - Public Methods

    func comparePlatforms(_ platforms: [Platform]) async {
        guard platforms.count >= 2 else { return }

        isLoading = true
        error = nil

        do {
            // 查找交集
            let intersectionResults = try await comparePlatformsUseCase.findIntersection(
                in: platforms,
                similarityThreshold: 0.8
            )

            // 提取交集话题
            intersectionTopics = intersectionResults.flatMap { result in
                result.topics
            }

            // 查找每个平台的独有话题
            var uniqueDict: [Platform: [TrendTopicEntity]] = [:]
            for platform in platforms {
                let otherPlatforms = platforms.filter { $0 != platform }
                let unique = try await comparePlatformsUseCase.findUnique(
                    in: platform,
                    comparedTo: otherPlatforms,
                    similarityThreshold: 0.8
                )
                uniqueDict[platform] = unique
            }
            uniqueTopics = uniqueDict

        } catch {
            self.error = error
        }

        isLoading = false
    }
}
