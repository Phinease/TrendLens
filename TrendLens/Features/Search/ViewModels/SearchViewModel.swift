import Foundation
import SwiftUI

/// 搜索页 ViewModel
@MainActor
@Observable
final class SearchViewModel {

    // MARK: - Published State

    private(set) var searchResults: [TrendTopicEntity] = []
    private(set) var isSearching = false
    private(set) var error: Error?
    var searchQuery: String = ""

    // MARK: - Dependencies

    private let searchTrendingUseCase: SearchTrendingUseCase

    // MARK: - Initialization

    init(searchTrendingUseCase: SearchTrendingUseCase) {
        self.searchTrendingUseCase = searchTrendingUseCase
    }

    // MARK: - Public Methods

    func search() async {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }

        isSearching = true
        error = nil

        do {
            searchResults = try await searchTrendingUseCase.execute(
                query: searchQuery,
                in: nil
            )
        } catch {
            self.error = error
        }

        isSearching = false
    }

    func clearSearch() {
        searchQuery = ""
        searchResults = []
    }
}
