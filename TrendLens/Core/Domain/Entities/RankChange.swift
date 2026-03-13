//
//  RankChange.swift
//  TrendLens
//

import Foundation

/// 排名变化类型
enum RankChange: Codable, Sendable, Equatable, Hashable {
    /// 新上榜
    case new
    /// 排名上升（包含上升的位数）
    case up(Int)
    /// 排名下降（包含下降的位数）
    case down(Int)
    /// 排名不变
    case unchanged

    /// 变化值（上升为正，下降为负，新上榜和不变为0）
    var value: Int {
        switch self {
        case .new, .unchanged: return 0
        case .up(let n): return n
        case .down(let n): return -n
        }
    }

    /// 是否为正向变化
    var isPositive: Bool {
        switch self {
        case .new, .up: return true
        case .down, .unchanged: return false
        }
    }
}
