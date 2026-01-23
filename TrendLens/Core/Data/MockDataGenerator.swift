//
//  MockDataGenerator.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//
//  动态 Mock 数据生成器
//  用于阶段 1 开发，替代固定的 MockData
//

import Foundation

/// Mock 数据生成器
/// 动态生成热榜快照数据，用于开发和测试
actor MockDataGenerator {

    // MARK: - Properties

    /// 话题标题模板库
    private let titleTemplates: [Platform: [String]] = [
        .weibo: [
            "某顶流官宣恋情",
            "春节档电影票房破纪录",
            "某地突发地震",
            "国产手机发布会",
            "央视春晚节目单曝光",
            "某品牌新品翻车",
            "明星离婚风波",
            "热播剧大结局",
            "网红直播翻车",
            "体育赛事精彩瞬间",
            "社会热点事件",
            "科技新品发布",
            "娱乐圈八卦",
            "时事新闻",
            "网络热梗",
            "美食探店",
            "旅游攻略",
            "健康养生",
            "教育话题",
            "房产市场"
        ],
        .xiaohongshu: [
            "早春穿搭灵感合集",
            "居家收纳神器测评",
            "新年妆容教程",
            "减脂餐食谱分享",
            "旅行好物推荐",
            "护肤品测评",
            "家居改造日记",
            "美甲教程",
            "烘焙食谱",
            "健身打卡",
            "读书笔记",
            "手账教程",
            "摄影技巧",
            "宠物日常",
            "植物养护",
            "手工DIY",
            "穿搭分享",
            "美食探店",
            "生活vlog",
            "好物分享"
        ],
        .bilibili: [
            "年度游戏大作正式发售",
            "知名UP主年度盘点",
            "番剧新番推荐",
            "鬼畜区新王诞生",
            "科技区硬核评测",
            "虚拟主播联动直播",
            "游戏攻略教程",
            "动漫解说",
            "影视剪辑",
            "音乐翻唱",
            "舞蹈区热门",
            "知识科普",
            "美食制作",
            "数码评测",
            "生活记录",
            "搞笑视频",
            "游戏实况",
            "学习分享",
            "运动健身",
            "手工制作"
        ],
        .douyin: [
            "全网爆火挑战赛",
            "神曲洗脑循环",
            "萌宠日常合集",
            "美食探店vlog",
            "变装秀名场面",
            "搞笑段子",
            "才艺展示",
            "情感故事",
            "生活技巧",
            "舞蹈教学",
            "化妆教程",
            "游戏高光",
            "旅行打卡",
            "美食制作",
            "健身教程",
            "萌娃日常",
            "情侣日常",
            "职场故事",
            "创意视频",
            "热门音乐"
        ],
        .x: [
            "AI New Breakthrough Announced",
            "Global Climate Summit 2026",
            "SpaceX Mars Mission Update",
            "Crypto Market Rally",
            "Super Bowl Preview",
            "Tech Industry News",
            "Political Debate",
            "Breaking News Alert",
            "Celebrity Announcement",
            "Sports Highlights",
            "Economic Update",
            "Science Discovery",
            "Entertainment News",
            "Social Movement",
            "Product Launch",
            "Market Analysis",
            "Cultural Event",
            "Innovation Showcase",
            "Global Affairs",
            "Trending Topic"
        ],
        .zhihu: [
            "如何评价最新发布的 AI 大模型？",
            "年轻人的第一份工作应该怎么选？",
            "读博是一种怎样的体验？",
            "有哪些值得推荐的纪录片？",
            "普通人如何开始理财？",
            "如何提高学习效率？",
            "程序员的职业发展路径",
            "如何看待当前经济形势？",
            "有哪些冷门但实用的技能？",
            "如何培养批判性思维？",
            "研究生生活是怎样的？",
            "如何选择适合自己的城市？",
            "有哪些值得一读的书籍？",
            "如何平衡工作与生活？",
            "创业需要注意什么？",
            "如何提升沟通能力？",
            "有哪些高效的时间管理方法？",
            "如何看待人工智能的发展？",
            "留学的利弊分析",
            "如何建立个人品牌？"
        ]
    ]

    /// 标签库
    private let tagsByPlatform: [Platform: [String]] = [
        .weibo: ["娱乐", "明星", "电影", "春节", "突发", "地震", "科技", "手机", "春晚", "消费", "争议"],
        .xiaohongshu: ["穿搭", "时尚", "居家", "收纳", "美妆", "教程", "美食", "减脂", "旅行", "好物"],
        .bilibili: ["游戏", "新作", "UP主", "年度", "番剧", "动漫", "鬼畜", "搞笑", "科技", "评测"],
        .douyin: ["挑战赛", "热门", "音乐", "神曲", "萌宠", "可爱", "美食", "探店", "变装", "创意"],
        .x: ["AI", "Tech", "Climate", "Politics", "Space", "Technology", "Crypto", "Finance", "Sports", "NFL"],
        .zhihu: ["AI", "科技", "职场", "建议", "教育", "学术", "纪录片", "推荐", "理财", "金融"]
    ]

    /// AI 摘要模板库
    private let summaryTemplates: [Platform: [String]] = [
        .weibo: [
            "网友热议，转发评论已破百万。该话题在微博上持续升温，相关讨论频繁出现在热搜榜单，社交媒体上关注度极高。",
            "相关话题在社交平台引发了广泛讨论，用户纷纷发表自己的观点看法。热度持续攀升，成为社交媒体上的焦点话题。",
            "该事件发生后迅速登上热搜榜单，成为网友热议的焦点。网民积极参与讨论，评论和转发数量持续增加，讨论热烈进行中。",
            "事件曝光后引发了广泛的网络关注，网友纷纷表示关切和重视。话题热度保持在高位，引发社会各界的广泛讨论和思考。"
        ],
        .xiaohongshu: [
            "该话题在小红书平台上获得了大量关注，用户积极分享相关内容和个人经验。优质笔记频繁出现，内容质量不断提升。",
            "众多用户在平台上参与讨论并分享个人见解，话题下汇集了许多有价值的内容分享和实用建议。",
            "小红书平台上的用户积极互动，该话题吸引了众多内容创作者的参与和分享。创意内容不断涌现，讨论声势浩大。",
            "用户热情高涨，相关内容不断更新。话题讨论氛围浓厚，持续吸引更多人的关注和参与。"
        ],
        .bilibili: [
            "该话题在B站UP主中引发了热烈讨论。多位知名创作者推出相关视频，观看量持续上升，互动数据不断刷新。",
            "相关视频获得了大量播放和用户互动。网友在评论区展开深入讨论，热度高涨，反响十分热烈。",
            "众多UP主争相制作相关内容来吸引粉丝。话题视频播放总量已超百万，互动热烈，是目前平台的重点关注话题。",
            "话题相关内容层出不穷，不断有优质作品发布。吸引大批用户观看和参与讨论，热度保持持续上升。"
        ],
        .douyin: [
            "该话题相关的短视频在抖音上获得了海量播放。用户积极参与各类挑战，相关作品频繁出现在推荐页面。",
            "短视频平台上该话题相关内容的播放量已经突破千万。网友热情参与，创意作品不断涌现，吸引越来越多的关注。",
            "话题挑战在抖音平台爆火，吸引了众多用户积极参与创作和分享。粉丝热情高涨，相关内容快速传播。",
            "相关短视频频频登上热榜。用户响应积极，话题讨论热烈，热度持续攀升，呈现爆发式增长。"
        ],
        .x: [
            "This topic has generated significant engagement on the platform with widespread discussion among users. Many are sharing diverse perspectives on the subject.",
            "Users from around the world are actively sharing their perspectives on this trending topic. Discussion volume remains consistently high with growing engagement.",
            "The topic continues to dominate conversations across the platform. Engagement metrics show strong activity levels with retweeting and commenting increasing.",
            "Numerous posts related to this topic are gaining traction and visibility. User interaction and debate remain intense with diverse opinions being shared."
        ],
        .zhihu: [
            "该问题在知乎上引发了知友们的热烈讨论和广泛参与。多位专业答主提供了深入细致的分析和见解，内容质量上乘。",
            "知识内容创作者围绕此话题展开了多层次的讨论，提供了多角度的思考、分析和建议。既有理论分析也有实践经验。",
            "话题相关的问答内容在知乎上获得广泛关注和认可。用户的投票和评论数持续上升，话题热度不断提升。",
            "众多用户在此话题下积极分享个人经验和深入观点。讨论的质量高，互动频繁，已成为知乎平台的热点话题。"
        ]
    ]

    // MARK: - Public Methods

    /// 生成指定平台的快照
    nonisolated func generateSnapshot(for platform: Platform, topicCount: Int = 20) -> TrendSnapshotEntity {
        let now = Date()
        let validUntil = now.addingTimeInterval(30 * 60) // 30分钟有效期

        let topics = generateTopics(for: platform, count: topicCount)

        // 计算内容哈希
        let contentHash = calculateContentHash(topics: topics)

        return TrendSnapshotEntity(
            id: UUID().uuidString,
            platform: platform,
            fetchedAt: now,
            validUntil: validUntil,
            contentHash: contentHash,
            etag: UUID().uuidString,
            schemaVersion: 1,
            topics: topics
        )
    }

    /// 生成所有平台的快照
    nonisolated func generateAllSnapshots(topicsPerPlatform: Int = 20) -> [TrendSnapshotEntity] {
        Platform.allCases.map { platform in
            generateSnapshot(for: platform, topicCount: topicsPerPlatform)
        }
    }

    // MARK: - Private Methods

    /// 生成话题列表
    private nonisolated func generateTopics(for platform: Platform, count: Int) -> [TrendTopicEntity] {
        let templates = titleTemplates[platform] ?? []
        let tags = tagsByPlatform[platform] ?? []

        return (1...count).map { rank in
            let title = templates.randomElement() ?? "热门话题 \(rank)"
            let baseHeat = generateBaseHeat(for: rank)
            let heatValue = baseHeat + Int.random(in: -baseHeat/10...baseHeat/10)

            return TrendTopicEntity(
                id: "\(platform.rawValue)-\(UUID().uuidString)",
                platform: platform,
                title: "\(title) \(generateSuffix())",
                description: generateDescription(for: platform),
                heatValue: heatValue,
                rank: rank,
                link: nil,
                tags: generateTags(from: tags),
                fetchedAt: Date().addingTimeInterval(TimeInterval(-Int.random(in: 0...7200))),
                rankChange: generateRankChange(for: rank),
                heatHistory: generateHeatHistory(baseHeat: heatValue, rank: rank),
                summary: generateSummary(for: platform),
                isFavorite: false
            )
        }
    }

    /// 生成基础热度值（根据排名）
    private nonisolated func generateBaseHeat(for rank: Int) -> Int {
        switch rank {
        case 1:
            return Int.random(in: 2_000_000...3_500_000)
        case 2...3:
            return Int.random(in: 1_000_000...2_000_000)
        case 4...10:
            return Int.random(in: 500_000...1_000_000)
        case 11...20:
            return Int.random(in: 200_000...500_000)
        case 21...50:
            return Int.random(in: 50_000...200_000)
        default:
            return Int.random(in: 10_000...50_000)
        }
    }

    /// 生成标题后缀（增加多样性）
    private nonisolated func generateSuffix() -> String {
        let suffixes = ["", "引热议", "冲上热搜", "网友热议", "全网关注", ""]
        return suffixes.randomElement() ?? ""
    }

    /// 生成描述
    private nonisolated func generateDescription(for platform: Platform) -> String? {
        let descriptions = [
            "相关话题引发广泛讨论",
            "网友纷纷发表看法",
            "详情请点击查看",
            "最新消息更新",
            nil,
            nil
        ]
        return descriptions.randomElement() ?? nil
    }

    /// 生成 AI 摘要（必需，始终返回）
    private nonisolated func generateSummary(for platform: Platform) -> String {
        let templates = summaryTemplates[platform] ?? []
        return templates.randomElement() ?? "该话题在平台上引发了广泛讨论，用户参与度高，热度持续攀升。"
    }

    /// 生成标签
    private nonisolated func generateTags(from tagPool: [String]) -> [String] {
        let count = Int.random(in: 1...3)
        return Array(tagPool.shuffled().prefix(count))
    }

    /// 生成排名变化
    private nonisolated func generateRankChange(for rank: Int) -> RankChange {
        let random = Int.random(in: 0...100)

        switch random {
        case 0...10:
            return .new
        case 11...40:
            return .up(Int.random(in: 1...10))
        case 41...70:
            return .down(Int.random(in: 1...10))
        default:
            return .unchanged
        }
    }

    /// 生成热度历史数据
    private nonisolated func generateHeatHistory(baseHeat: Int, rank: Int) -> [HeatDataPoint] {
        let now = Date()
        let pointCount = 8

        // 根据排名决定趋势
        let trend: HeatTrend = rank <= 3 ? .rising : (rank <= 10 ? .stable : .falling)

        return (0..<pointCount).map { i in
            let hoursAgo = (pointCount - 1 - i) * 2
            let timestamp = now.addingTimeInterval(TimeInterval(-hoursAgo * 3600))

            let variation = Int.random(in: -baseHeat/10...baseHeat/10)
            let trendOffset: Int

            switch trend {
            case .rising:
                trendOffset = i * (baseHeat / pointCount / 2)
            case .falling:
                trendOffset = -i * (baseHeat / pointCount / 2)
            case .stable:
                trendOffset = 0
            case .explosive:
                trendOffset = i * i * (baseHeat / pointCount / 4)
            }

            let heatValue = max(1000, baseHeat + variation + trendOffset)
            let estimatedRank = max(1, rank - i / 2)

            return HeatDataPoint(
                timestamp: timestamp,
                heatValue: heatValue,
                rank: estimatedRank
            )
        }
    }

    /// 计算内容哈希
    private nonisolated func calculateContentHash(topics: [TrendTopicEntity]) -> String {
        let content = topics.map { "\($0.id)-\($0.title)-\($0.heatValue)" }.joined(separator: "|")
        return String(content.hashValue)
    }

    // MARK: - Heat Trend

    private enum HeatTrend {
        case rising
        case falling
        case stable
        case explosive
    }
}
