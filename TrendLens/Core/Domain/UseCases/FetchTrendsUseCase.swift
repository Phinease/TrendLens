//
//  FetchTrendsUseCase.swift
//  TrendLens
//

import Foundation

/// 获取趋势数据用例
struct FetchTrendsUseCase: Sendable {

    private let repository: TrendRepository

    init(repository: TrendRepository) {
        self.repository = repository
    }

    /// 获取趋势关键词列表，按指定方式排序
    func execute(sortBy: TrendSortOrder = .trendValue) async throws -> [TrendKeywordEntity] {
        let keywords = try await repository.fetchTrendKeywords()

        return switch sortBy {
        case .trendValue:
            keywords.sorted { $0.latestTrendValue > $1.latestTrendValue }
        case .linkedTopics:
            keywords.sorted { $0.linkedTopicCount > $1.linkedTopicCount }
        }
    }

    /// 获取关键词关联的话题列表
    func fetchLinkedTopics(for keywordId: String) async throws -> [TrendTopicEntity] {
        try await repository.fetchLinkedTopics(for: keywordId)
    }
}

/// 趋势排序方式
enum TrendSortOrder: String, CaseIterable, Identifiable {
    case trendValue
    case linkedTopics

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .trendValue: "趋势值"
        case .linkedTopics: "关联话题"
        }
    }
}
