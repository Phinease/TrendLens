//
//  Comment.swift
//  TrendLens
//
//  Created by Claude on 2/18/26.
//

import Foundation

/// 评论实体
struct Comment: Identifiable, Codable, Sendable, Hashable, Equatable {

    // MARK: - Properties

    /// 唯一标识符
    let id: String

    /// 评论者用户名
    let username: String

    /// 评论者头像类型（使用 SF Symbols）
    let avatarSymbol: String

    /// 头像背景颜色（十六进制）
    let avatarColorHex: String

    /// 评论内容
    let content: String

    /// 评论时间
    let createdAt: Date

    /// 点赞数
    let likeCount: Int

    /// 是否已点赞（当前用户）
    var isLiked: Bool

    /// 回复数
    let replyCount: Int

    // MARK: - Initialization

    nonisolated init(
        id: String = UUID().uuidString,
        username: String,
        avatarSymbol: String = "person.circle.fill",
        avatarColorHex: String = "#007AFF",
        content: String,
        createdAt: Date = Date(),
        likeCount: Int = 0,
        isLiked: Bool = false,
        replyCount: Int = 0
    ) {
        self.id = id
        self.username = username
        self.avatarSymbol = avatarSymbol
        self.avatarColorHex = avatarColorHex
        self.content = content
        self.createdAt = createdAt
        self.likeCount = likeCount
        self.isLiked = isLiked
        self.replyCount = replyCount
    }
}

// MARK: - Mock Data Generator

extension Comment {

    /// 头像符号库
    nonisolated static let avatarSymbols = [
        "person.circle.fill",
        "person.crop.circle.fill",
        "figure.stand",
        "figure.wave",
        "figure.walk",
        "star.circle.fill",
        "heart.circle.fill",
        "bolt.circle.fill",
        "leaf.circle.fill",
        "flame.circle.fill",
        "moon.circle.fill",
        "sun.max.circle.fill",
        "cloud.circle.fill",
        "sparkles",
        "wand.and.stars"
    ]

    /// 头像颜色库
    nonisolated static let avatarColors = [
        "#007AFF", // 蓝色
        "#34C759", // 绿色
        "#FF9500", // 橙色
        "#FF2D55", // 粉色
        "#AF52DE", // 紫色
        "#5856D6", // 靛蓝
        "#FF3B30", // 红色
        "#00C7BE", // 青色
        "#32ADE6", // 天蓝
        "#FFD60A"  // 黄色
    ]

    /// 用户名库
    nonisolated static let usernames = [
        "科技观察者", "热点追踪", "理性分析", "吃瓜群众", "路人甲",
        "深度思考", "围观网友", "热心市民", "好奇宝宝", "专业评论",
        "小明同学", "隔壁老王", "技术大佬", "设计师小李", "产品经理",
        "数据分析师", "内容创作者", "资深用户", "新手上路", "匿名用户"
    ]

    /// 评论内容模板库
    nonisolated static let commentTemplates = [
        "这个话题太火了，必须关注！",
        "终于等到这个消息了，期待已久",
        "说得很有道理，学习了",
        "这个观点很新颖，值得思考",
        "已收藏，慢慢看",
        "前排围观，等大佬分析",
        "涨知识了，感谢分享",
        "这件事情确实值得关注",
        "分析得很到位，赞一个",
        "希望能有更多后续报道",
        "看完之后有很多感想",
        "这个角度很独特，之前没想到",
        "转发给朋友看看",
        "评论区卧虎藏龙啊",
        "坐等官方回应",
        "这波分析我给满分",
        "热度这么高是有原因的",
        "每次看这种话题都很有收获",
        "建议大家理性讨论",
        "这条信息很有价值"
    ]

    /// 生成随机评论
    nonisolated static func generateMockComment() -> Comment {
        let now = Date()
        let randomMinutesAgo = Int.random(in: 1...1440) // 1分钟到24小时前
        let createdAt = now.addingTimeInterval(TimeInterval(-randomMinutesAgo * 60))

        return Comment(
            id: UUID().uuidString,
            username: usernames.randomElement() ?? "匿名用户",
            avatarSymbol: avatarSymbols.randomElement() ?? "person.circle.fill",
            avatarColorHex: avatarColors.randomElement() ?? "#007AFF",
            content: commentTemplates.randomElement() ?? "好的",
            createdAt: createdAt,
            likeCount: Int.random(in: 0...999),
            isLiked: Bool.random(),
            replyCount: Int.random(in: 0...50)
        )
    }

    /// 生成多条随机评论
    nonisolated static func generateMockComments(count: Int) -> [Comment] {
        (0..<count).map { _ in generateMockComment() }
            .sorted { $0.likeCount > $1.likeCount } // 按点赞数排序
    }
}
