import Foundation
import SwiftUI

/// 支持的热榜平台（与后端 platform_id 一致）
enum Platform: String, Codable, CaseIterable, Identifiable, Sendable {
    case weibo = "weibo"
    case zhihu = "zhihu"
    case baidu = "baidu"
    case bilibiliHotSearch = "bilibili-hs"
    case bilibiliHotVideo = "bilibili-hv"
    case douyin = "douyin"
    case toutiao = "toutiao"

    var id: String { rawValue }

    /// 平台显示名称
    var displayName: String {
        switch self {
        case .weibo: return "微博"
        case .zhihu: return "知乎"
        case .baidu: return "百度"
        case .bilibiliHotSearch: return "B站热搜"
        case .bilibiliHotVideo: return "B站热门"
        case .douyin: return "抖音"
        case .toutiao: return "头条"
        }
    }

    /// 平台图标名称（SF Symbols）
    var iconName: String {
        switch self {
        case .weibo: return "w.square.fill"
        case .zhihu: return "lightbulb.fill"
        case .baidu: return "magnifyingglass.circle.fill"
        case .bilibiliHotSearch: return "play.tv.fill"
        case .bilibiliHotVideo: return "film.fill"
        case .douyin: return "music.note"
        case .toutiao: return "newspaper.fill"
        }
    }

    /// 平台主题色
    var themeColor: String {
        switch self {
        case .weibo: return "#E6162D"
        case .zhihu: return "#0084FF"
        case .baidu: return "#2319DC"
        case .bilibiliHotSearch: return "#00A1D6"
        case .bilibiliHotVideo: return "#FB7299"
        case .douyin: return "#000000"
        case .toutiao: return "#F85959"
        }
    }

    /// 平台 Hint 色（仅用于 Icon 识别）
    var hintColor: Color {
        switch self {
        case .weibo: return Color(hex: "FF6B6B")
        case .zhihu: return Color(hex: "8B5CF6")
        case .baidu: return Color(hex: "6366F1")
        case .bilibiliHotSearch: return Color(hex: "22D3D8")
        case .bilibiliHotVideo: return Color(hex: "FB7299")
        case .douyin: return Color(hex: "A855F7")
        case .toutiao: return Color(hex: "F87171")
        }
    }

    /// 平台选择渐变色（仅用于下划线）
    var selectionGradient: LinearGradient {
        let colors = switch self {
        case .weibo:
            [Color(hex: "FF6B6B"), Color(hex: "FB923C")]
        case .zhihu:
            [Color(hex: "8B5CF6"), Color(hex: "C4B5FD")]
        case .baidu:
            [Color(hex: "6366F1"), Color(hex: "818CF8")]
        case .bilibiliHotSearch:
            [Color(hex: "22D3D8"), Color(hex: "34D399")]
        case .bilibiliHotVideo:
            [Color(hex: "FB7299"), Color(hex: "FDA4AF")]
        case .douyin:
            [Color(hex: "A855F7"), Color(hex: "D8B4FE")]
        case .toutiao:
            [Color(hex: "F87171"), Color(hex: "FB923C")]
        }
        return LinearGradient(
            colors: colors,
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Color Extension for Platform

extension Color {
    /// 为 Color 添加 hex 初始化方法（如果不存在的话）
    // 注：此方法在 DesignSystem 中已存在，此处仅作备注
}
