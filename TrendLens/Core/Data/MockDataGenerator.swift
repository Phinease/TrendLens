//
//  MockDataGenerator.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//
//  动态 Mock 数据生成器
//  用于开发和测试（isRemoteEnabled = false 时的后备方案）
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
        ],
        .baidu: [
            "今日实时热点汇总",
            "最新政策解读",
            "天气预报更新",
            "交通出行提醒",
            "重大科技突破",
            "医疗健康新发现",
            "教育考试资讯",
            "财经市场分析",
            "社会民生关注",
            "体育赛事速报",
            "文化娱乐动态",
            "国际新闻速递",
            "法律法规更新",
            "房产市场动态",
            "求职就业指南",
            "美食餐饮推荐",
            "旅游景点攻略",
            "汽车行业资讯",
            "数码科技评测",
            "生活百科知识"
        ],
        .bilibiliHotSearch: [
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
        .bilibiliHotVideo: [
            "百万播放量神作",
            "UP主创意挑战",
            "硬核知识科普",
            "沉浸式体验视频",
            "游戏高光时刻",
            "美食大制作",
            "旅行纪录片",
            "音乐MV制作",
            "动画短片",
            "技术分享",
            "日常vlog",
            "搞笑合集",
            "手工达人",
            "宠物日常",
            "运动挑战",
            "读书分享",
            "摄影教程",
            "穿搭分享",
            "家居改造",
            "职场经验"
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
        .toutiao: [
            "今日头条热点推荐",
            "国内要闻速报",
            "国际形势分析",
            "科技前沿动态",
            "财经投资解读",
            "社会民生关注",
            "军事新闻报道",
            "健康养生指南",
            "教育资讯更新",
            "体育赛事回顾",
            "娱乐明星动态",
            "汽车行业新闻",
            "房产市场分析",
            "三农政策解读",
            "历史文化探索",
            "法治新闻报道",
            "环保绿色生活",
            "宠物趣事分享",
            "美食文化传承",
            "旅游目的地推荐"
        ]
    ]

    /// 标签库
    private let tagsByPlatform: [Platform: [String]] = [
        .weibo: ["娱乐", "明星", "电影", "春节", "突发", "地震", "科技", "手机", "春晚", "消费", "争议"],
        .zhihu: ["AI", "科技", "职场", "建议", "教育", "学术", "纪录片", "推荐", "理财", "金融"],
        .baidu: ["热点", "实时", "政策", "天气", "交通", "科技", "健康", "教育", "财经", "民生"],
        .bilibiliHotSearch: ["游戏", "新作", "UP主", "年度", "番剧", "动漫", "鬼畜", "搞笑", "科技", "评测"],
        .bilibiliHotVideo: ["百万播放", "创意", "科普", "硬核", "游戏", "美食", "vlog", "动画", "音乐", "技术"],
        .douyin: ["挑战赛", "热门", "音乐", "神曲", "萌宠", "可爱", "美食", "探店", "变装", "创意"],
        .toutiao: ["热点", "要闻", "国际", "科技", "财经", "民生", "军事", "健康", "体育", "娱乐"]
    ]

    /// AI 摘要模板库
    private let summaryTemplates: [Platform: [String]] = [
        .weibo: [
            "网友热议，转发评论已破百万。该话题在微博上持续升温，相关讨论频繁出现在热搜榜单，社交媒体上关注度极高。",
            "相关话题在社交平台引发了广泛讨论，用户纷纷发表自己的观点看法。热度持续攀升，成为社交媒体上的焦点话题。",
            "该事件发生后迅速登上热搜榜单，成为网友热议的焦点。网民积极参与讨论，评论和转发数量持续增加，讨论热烈进行中。",
            "事件曝光后引发了广泛的网络关注，网友纷纷表示关切和重视。话题热度保持在高位，引发社会各界的广泛讨论和思考。"
        ],
        .zhihu: [
            "该问题在知乎上引发了知友们的热烈讨论和广泛参与。多位专业答主提供了深入细致的分析和见解，内容质量上乘。",
            "知识内容创作者围绕此话题展开了多层次的讨论，提供了多角度的思考、分析和建议。既有理论分析也有实践经验。",
            "话题相关的问答内容在知乎上获得广泛关注和认可。用户的投票和评论数持续上升，话题热度不断提升。",
            "众多用户在此话题下积极分享个人经验和深入观点。讨论的质量高，互动频繁，已成为知乎平台的热点话题。"
        ],
        .baidu: [
            "该话题成为百度搜索热点，搜索量急剧上升。大量用户通过搜索引擎关注此事，相关资讯持续更新。",
            "百度搜索指数显示该话题热度持续走高，用户搜索需求旺盛。相关内容在搜索结果中频繁展示。",
            "该话题在百度热搜榜上排名靠前，搜索量持续攀升。网民关注度极高，相关讨论广泛传播。",
            "搜索热度持续上涨，该话题成为全网关注焦点。百度指数数据显示用户关注度明显提升。"
        ],
        .bilibiliHotSearch: [
            "该话题在B站UP主中引发了热烈讨论。多位知名创作者推出相关视频，观看量持续上升，互动数据不断刷新。",
            "相关视频获得了大量播放和用户互动。网友在评论区展开深入讨论，热度高涨，反响十分热烈。",
            "众多UP主争相制作相关内容来吸引粉丝。话题视频播放总量已超百万，互动热烈，是目前平台的重点关注话题。",
            "话题相关内容层出不穷，不断有优质作品发布。吸引大批用户观看和参与讨论，热度保持持续上升。"
        ],
        .bilibiliHotVideo: [
            "该视频在B站引发热烈反响，播放量迅速突破百万。弹幕密度极高，用户纷纷点赞投币收藏。",
            "视频内容质量极高，获得了UP主和观众的一致好评。推荐算法持续推送，播放数据持续攀升。",
            "热门视频引发全站关注，弹幕互动活跃。视频内容独具创意，吸引了大量新老用户的观看和分享。",
            "该视频成为B站热门推荐，播放量和互动数据表现亮眼。用户在评论区热烈讨论，形成了良好的社区氛围。"
        ],
        .douyin: [
            "该话题相关的短视频在抖音上获得了海量播放。用户积极参与各类挑战，相关作品频繁出现在推荐页面。",
            "短视频平台上该话题相关内容的播放量已经突破千万。网友热情参与，创意作品不断涌现，吸引越来越多的关注。",
            "话题挑战在抖音平台爆火，吸引了众多用户积极参与创作和分享。粉丝热情高涨，相关内容快速传播。",
            "相关短视频频频登上热榜。用户响应积极，话题讨论热烈，热度持续攀升，呈现爆发式增长。"
        ],
        .toutiao: [
            "该新闻在头条平台获得大量阅读和关注。用户评论积极，转发分享广泛，成为当日热点资讯。",
            "头条推荐引擎持续推送该话题内容，阅读量快速增长。用户关注度极高，相关报道持续跟进。",
            "该话题成为今日头条热门推荐，阅读量和互动数据表现突出。评论区讨论热烈，用户参与度高。",
            "新闻报道引发广泛关注，头条平台上相关内容持续更新。读者阅读热情高涨，话题热度居高不下。"
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
                heatValue: heatValue,
                rank: rank,
                link: generateLink(for: platform),
                tags: generateTags(from: tags),
                fetchedAt: Date().addingTimeInterval(TimeInterval(-Int.random(in: 0...7200))),
                rankChange: generateRankChange(for: rank),
                heatHistory: generateHeatHistory(baseHeat: heatValue, rank: rank),
                summary: generateSummary(for: platform),
                isFavorite: false,
                imageURLs: generateImageURLs(),
                comments: Comment.generateMockComments(count: Int.random(in: 5...15))
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

    /// 生成图片 URL 列表
    private nonisolated func generateImageURLs() -> [String] {
        if Int.random(in: 0...100) < 70 {
            let count = Int.random(in: 1...4)
            return (0..<count).map { _ in
                let width = [640, 800, 1024].randomElement() ?? 800
                let height = [480, 600, 768].randomElement() ?? 600
                let seed = Int.random(in: 1...1000)
                return "https://picsum.photos/seed/\(seed)/\(width)/\(height)"
            }
        }
        return []
    }

    /// 生成链接
    private nonisolated func generateLink(for platform: Platform) -> String? {
        let links: [Platform: [String]] = [
            .weibo: ["https://weibo.com/detail/", "https://m.weibo.cn/status/"],
            .zhihu: ["https://www.zhihu.com/question/", "https://zhuanlan.zhihu.com/p/"],
            .baidu: ["https://www.baidu.com/s?wd="],
            .bilibiliHotSearch: ["https://search.bilibili.com/all?keyword="],
            .bilibiliHotVideo: ["https://www.bilibili.com/video/", "https://b23.tv/"],
            .douyin: ["https://www.douyin.com/video/"],
            .toutiao: ["https://www.toutiao.com/article/"]
        ]

        if let platformLinks = links[platform], let baseURL = platformLinks.randomElement() {
            return baseURL + UUID().uuidString.replacingOccurrences(of: "-", with: "").prefix(16)
        }
        return nil
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
