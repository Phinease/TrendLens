//
//  TrendsViewModel.swift
//  TrendLens
//

import Foundation
import OSLog
import SwiftUI

/// 趋势页 ViewModel
@MainActor
@Observable
final class TrendsViewModel {

    private(set) var keywords: [TrendKeywordEntity] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    var sortOrder: TrendSortOrder = .trendValue

    private var linkedTopicsCache: [String: [TrendTopicEntity]] = [:]
    private let fetchTrendsUseCase: FetchTrendsUseCase

    init(fetchTrendsUseCase: FetchTrendsUseCase) {
        self.fetchTrendsUseCase = fetchTrendsUseCase
    }

    func fetchKeywords() async {
        AppLog.data.info("TRENDS_FETCH START sortBy=\(self.sortOrder.rawValue)")
        isLoading = true
        error = nil

        do {
            keywords = try await timed("TRENDS_FETCH") {
                try await fetchTrendsUseCase.execute(sortBy: sortOrder)
            }
            AppLog.data.info("TRENDS_FETCH SUCCESS count=\(self.keywords.count)")
        } catch {
            AppLog.data.error("TRENDS_FETCH FAILED error=\(error.localizedDescription)")
            self.error = error
        }
        isLoading = false
    }

    func fetchLinkedTopics(for keywordId: String) async -> [TrendTopicEntity] {
        if let cached = linkedTopicsCache[keywordId] {
            AppLog.cache.info("LINKED_TOPICS CACHE_HIT keywordId=\(keywordId) count=\(cached.count)")
            return cached
        }

        AppLog.data.info("LINKED_TOPICS FETCH keywordId=\(keywordId)")
        do {
            let topics = try await timed("LINKED_TOPICS") {
                try await fetchTrendsUseCase.fetchLinkedTopics(for: keywordId)
            }
            linkedTopicsCache[keywordId] = topics
            AppLog.data.info("LINKED_TOPICS SUCCESS keywordId=\(keywordId) count=\(topics.count)")
            return topics
        } catch {
            AppLog.data.error("LINKED_TOPICS FAILED keywordId=\(keywordId) error=\(error.localizedDescription)")
            return []
        }
    }
}
