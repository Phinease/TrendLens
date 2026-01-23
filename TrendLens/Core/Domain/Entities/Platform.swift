import Foundation
import SwiftUI

/// 支持的热榜平台
enum Platform: String, Codable, CaseIterable, Identifiable, Sendable {
    case weibo = "weibo"
    case xiaohongshu = "xiaohongshu"
    case bilibili = "bilibili"
    case douyin = "douyin"
    case x = "x"
    case zhihu = "zhihu"

    var id: String { rawValue }

    /// 平台显示名称
    var displayName: String {
        switch self {
        case .weibo: return "微博"
        case .xiaohongshu: return "小红书"
        case .bilibili: return "哔哩哔哩"
        case .douyin: return "抖音"
        case .x: return "X"
        case .zhihu: return "知乎"
        }
    }

    /// 平台图标名称（SF Symbols 或自定义）
    var iconName: String {
        switch self {
        case .weibo: return "w.square.fill"
        case .xiaohongshu: return "book.fill"
        case .bilibili: return "play.tv.fill"
        case .douyin: return "music.note"
        case .x: return "x.square.fill"
        case .zhihu: return "lightbulb.fill"
        }
    }

    /// 平台主题色
    var themeColor: String {
        switch self {
        case .weibo: return "#E6162D"
        case .xiaohongshu: return "#FF2442"
        case .bilibili: return "#00A1D6"
        case .douyin: return "#000000"
        case .x: return "#1DA1F2"
        case .zhihu: return "#0084FF"
        }
    }

    /// 平台 Hint 色（仅用于 Icon 识别）
    var hintColor: Color {
        switch self {
        case .weibo: return Color(hex: "FF6B6B")
        case .xiaohongshu: return Color(hex: "F43F5E")
        case .bilibili: return Color(hex: "22D3D8")
        case .douyin: return Color(hex: "A855F7")
        case .x: return Color(hex: "6366F1")
        case .zhihu: return Color(hex: "8B5CF6")
        }
    }

    /// 平台选择渐变色（仅用于下划线）
    var selectionGradient: LinearGradient {
        let colors = switch self {
        case .weibo:
            [Color(hex: "FF6B6B"), Color(hex: "FB923C")]
        case .xiaohongshu:
            [Color(hex: "F43F5E"), Color(hex: "FDA4AF")]
        case .bilibili:
            [Color(hex: "22D3D8"), Color(hex: "34D399")]
        case .douyin:
            [Color(hex: "A855F7"), Color(hex: "D8B4FE")]
        case .x:
            [Color(hex: "6366F1"), Color(hex: "818CF8")]
        case .zhihu:
            [Color(hex: "8B5CF6"), Color(hex: "C4B5FD")]
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
