import Foundation
import SwiftUI

/// 首页 ViewModel
@MainActor
@Observable
final class FeedViewModel {

    // MARK: - Published State

    private(set) var topics: [TrendTopicEntity] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var lastUpdatedAt: Date?

    // MARK: - Dependencies

    private let fetchTrendingUseCase: FetchTrendingUseCase
    private let manageFavoritesUseCase: ManageFavoritesUseCase

    // MARK: - Initialization

    init(
        fetchTrendingUseCase: FetchTrendingUseCase,
        manageFavoritesUseCase: ManageFavoritesUseCase
    ) {
        self.fetchTrendingUseCase = fetchTrendingUseCase
        self.manageFavoritesUseCase = manageFavoritesUseCase
    }

    // MARK: - Public Methods

    func fetchTopics(forceRefresh: Bool = false) async {
        isLoading = true
        error = nil

        do {
            topics = try await fetchTrendingUseCase.executeAggregated(
                for: nil,
                sortBy: .heat,
                forceRefresh: forceRefresh
            )
            lastUpdatedAt = Date()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func toggleFavorite(topicId: String) async {
        do {
            let isFavorite = try await manageFavoritesUseCase.isFavorite(topicId: topicId)

            if isFavorite {
                try await manageFavoritesUseCase.removeFavorite(topicId: topicId)
            } else {
                try await manageFavoritesUseCase.addFavorite(topicId: topicId)
            }
        } catch {
            self.error = error
        }
    }
}
