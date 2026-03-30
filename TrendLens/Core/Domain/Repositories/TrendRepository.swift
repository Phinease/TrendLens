//
//  TrendRepository.swift
//  TrendLens
//

import Foundation

/// 趋势数据仓库协议
protocol TrendRepository: Sendable {
    /// 获取活跃趋势关键词列表（含趋势数据和关联话题计数）
    func fetchTrendKeywords() async throws -> [TrendKeywordEntity]

    /// 获取关键词关联的话题列表
    func fetchLinkedTopics(for keywordId: String) async throws -> [TrendTopicEntity]
}
