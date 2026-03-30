//
//  SearchViewModel.swift
//  TrendLens
//

import Foundation
import OSLog
import SwiftUI

/// 搜索页 ViewModel
@MainActor
@Observable
final class SearchViewModel {

    private(set) var searchResults: [TrendTopicEntity] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    var searchQuery: String = ""

    private let searchTrendingUseCase: SearchTrendingUseCase

    init(searchTrendingUseCase: SearchTrendingUseCase) {
        self.searchTrendingUseCase = searchTrendingUseCase
    }

    func search(query: String, in platforms: [Platform]?) async {
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        AppLog.data.info("SEARCH START query=\(query) platforms=\(platforms?.map(\.rawValue).joined(separator: ",") ?? "all")")
        isLoading = true
        error = nil

        do {
            searchResults = try await timed("SEARCH") {
                try await searchTrendingUseCase.execute(query: query, in: platforms)
            }
            AppLog.data.info("SEARCH SUCCESS count=\(self.searchResults.count)")
        } catch {
            AppLog.data.error("SEARCH FAILED error=\(error.localizedDescription)")
            self.error = error
        }
        isLoading = false
    }

    func clearResults() {
        searchQuery = ""
        searchResults = []
    }
}
