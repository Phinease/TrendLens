import Foundation
import SwiftUI

/// 搜索页 ViewModel
@MainActor
@Observable
final class SearchViewModel {

    // MARK: - Published State

    private(set) var searchResults: [TrendTopicEntity] = []
    private(set) var isLoading = false
    private(set) var error: Error?
    var searchQuery: String = ""

    // MARK: - Dependencies

    private let searchTrendingUseCase: SearchTrendingUseCase

    // MARK: - Initialization

    init(searchTrendingUseCase: SearchTrendingUseCase) {
        self.searchTrendingUseCase = searchTrendingUseCase
    }

    // MARK: - Public Methods

    func search(query: String, in platforms: [Platform]?) async {
        print("🔎 [SearchViewModel] search called - query: \(query), platforms: \(platforms?.map { $0.rawValue } ?? ["all"])")

        guard !query.isEmpty else {
            searchResults = []
            return
        }

        isLoading = true
        error = nil

        do {
            print("🔎 [SearchViewModel] Executing search use case...")
            searchResults = try await searchTrendingUseCase.execute(
                query: query,
                in: platforms
            )
            print("🔎 [SearchViewModel] Search completed - found \(searchResults.count) results")
        } catch {
            print("❌ [SearchViewModel] Search failed - error: \(error)")
            self.error = error
        }

        isLoading = false
    }

    func clearResults() {
        searchQuery = ""
        searchResults = []
    }
}
