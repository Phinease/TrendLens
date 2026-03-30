//
//  TrendKeywordEntity.swift
//  TrendLens
//

import Foundation

/// 趋势关键词实体
struct TrendKeywordEntity: Identifiable, Sendable, Hashable {
    let id: String              // keyword_id
    let keyword: String
    let language: String
    let isActive: Bool
    let lastQueriedAt: Date?
    let queryHitRate: Double
    let linkedTopicCount: Int
    let trendPoints: [HeatDataPoint]

    /// 最新趋势值（0-100）
    var latestTrendValue: Int {
        trendPoints.last?.heatValue ?? 0
    }

    /// 趋势方向
    var trendDirection: TrendDirection {
        guard trendPoints.count >= 2 else { return .stable }
        let recent = Array(trendPoints.suffix(6))
        let trend = recent.trend ?? 0
        if trend > 5 { return .rising }
        if trend < -5 { return .falling }
        return .stable
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id && lhs.latestTrendValue == rhs.latestTrendValue
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

/// 趋势方向
enum TrendDirection: Sendable {
    case rising
    case falling
    case stable

    var icon: String {
        switch self {
        case .rising: "arrow.up.right"
        case .falling: "arrow.down.right"
        case .stable: "arrow.right"
        }
    }
}
