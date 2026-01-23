//
//  HeatDataPoint.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//

import Foundation

/// 热度数据点
/// 用于记录话题在某个时间点的热度值，支持热度曲线绘制
struct HeatDataPoint: Codable, Sendable, Identifiable, Equatable {

    // MARK: - Properties

    /// 唯一标识符
    let id: UUID

    /// 时间戳
    let timestamp: Date

    /// 热度值
    let heatValue: Int

    /// 当时的排名（可选）
    let rank: Int?

    // MARK: - Initialization

    nonisolated init(
        id: UUID = UUID(),
        timestamp: Date,
        heatValue: Int,
        rank: Int? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.heatValue = heatValue
        self.rank = rank
    }
}

// MARK: - Convenience Methods

extension HeatDataPoint {

    /// 创建当前时间点的数据点
    static func now(heatValue: Int, rank: Int? = nil) -> HeatDataPoint {
        HeatDataPoint(
            timestamp: Date(),
            heatValue: heatValue,
            rank: rank
        )
    }
}

// MARK: - Array Extension

extension Array where Element == HeatDataPoint {

    /// 按时间排序（从旧到新）
    var sortedByTime: [HeatDataPoint] {
        sorted { $0.timestamp < $1.timestamp }
    }

    /// 最新的数据点
    var latest: HeatDataPoint? {
        self.max(by: { $0.timestamp < $1.timestamp })
    }

    /// 最早的数据点
    var earliest: HeatDataPoint? {
        self.min(by: { $0.timestamp < $1.timestamp })
    }

    /// 最高热度
    var maxHeat: Int? {
        map(\.heatValue).max()
    }

    /// 最低热度
    var minHeat: Int? {
        map(\.heatValue).min()
    }

    /// 热度变化趋势（正数上升，负数下降）
    var trend: Int? {
        guard count >= 2,
              let first = first,
              let last = last else { return nil }
        return last.heatValue - first.heatValue
    }

    /// 是否处于上升趋势
    var isRising: Bool {
        guard let trend = trend else { return false }
        return trend > 0
    }
}
