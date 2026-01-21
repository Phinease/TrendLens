import Foundation

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
}
