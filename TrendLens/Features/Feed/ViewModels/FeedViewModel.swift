//
//  FeedViewModel.swift
//  TrendLens
//

import Foundation
import OSLog
import SwiftUI

/// 首页 ViewModel
@MainActor
@Observable
final class FeedViewModel {

    private(set) var topics: [TrendTopicEntity] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    private(set) var lastUpdatedAt: Date?

    private let fetchTrendingUseCase: FetchTrendingUseCase
    private let manageFavoritesUseCase: ManageFavoritesUseCase

    init(
        fetchTrendingUseCase: FetchTrendingUseCase,
        manageFavoritesUseCase: ManageFavoritesUseCase
    ) {
        self.fetchTrendingUseCase = fetchTrendingUseCase
        self.manageFavoritesUseCase = manageFavoritesUseCase
    }

    func fetchTopics(forceRefresh: Bool = false) async {
        AppLog.data.info("FEED_FETCH START forceRefresh=\(forceRefresh) currentCount=\(self.topics.count)")
        isLoading = true
        error = nil

        do {
            topics = try await timed("FEED_FETCH") {
                try await fetchTrendingUseCase.executeAggregated(
                    for: nil, sortBy: .heat, forceRefresh: forceRefresh
                )
            }
            lastUpdatedAt = .now
            AppLog.data.info("FEED_FETCH SUCCESS count=\(self.topics.count)")
        } catch {
            AppLog.data.error("FEED_FETCH FAILED error=\(error.localizedDescription)")
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
            AppLog.data.info("FAVORITE_TOGGLE topicId=\(topicId) newState=\(!isFavorite)")
        } catch {
            AppLog.data.error("FAVORITE_TOGGLE FAILED error=\(error.localizedDescription)")
            self.error = error
        }
    }
}
