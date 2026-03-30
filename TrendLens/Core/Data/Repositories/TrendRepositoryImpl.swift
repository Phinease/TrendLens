//
//  TrendRepositoryImpl.swift
//  TrendLens
//

import Foundation

/// 趋势数据仓库实现
@MainActor
final class TrendRepositoryImpl: TrendRepository {

    private let remoteDataSource: RemoteTrendingDataSource

    init(remoteDataSource: RemoteTrendingDataSource) {
        self.remoteDataSource = remoteDataSource
    }

    nonisolated func fetchTrendKeywords() async throws -> [TrendKeywordEntity] {
        try await remoteDataSource.fetchTrendKeywords()
    }

    nonisolated func fetchLinkedTopics(for keywordId: String) async throws -> [TrendTopicEntity] {
        try await remoteDataSource.fetchLinkedTopics(for: keywordId)
    }
}
