//
//  MockData.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//
//  ⚠️ 阶段 0.5 临时固定数据
//  此文件将在阶段 1 被移除，届时将使用 SwiftData 和专业的 Mock 数据生成器
//

import Foundation

// MARK: - Mock Data Provider

/// Mock 数据提供器
/// 提供固定的测试数据用于 UI 开发和展示
enum MockData {

    // MARK: - All Topics

    /// 获取所有平台的热点话题（合并）
    static var allTopics: [TrendTopicEntity] {
        Platform.allCases.flatMap { topicsForPlatform($0) }
            .sorted { $0.heatValue > $1.heatValue }
    }

    /// 获取指定平台的热点话题
    static func topicsForPlatform(_ platform: Platform) -> [TrendTopicEntity] {
        switch platform {
        case .weibo:
            return weiboTopics
        case .xiaohongshu:
            return xiaohongshuTopics
        case .bilibili:
            return bilibiliTopics
        case .douyin:
            return douyinTopics
        case .x:
            return xTopics
        case .zhihu:
            return zhihuTopics
        }
    }

    // MARK: - Heat History Generator

    /// 生成模拟热度曲线数据
    static func generateHeatHistory(
        baseHeat: Int,
        count: Int = 8,
        trend: HeatTrend = .rising
    ) -> [HeatDataPoint] {
        let now = Date()

        return (0..<count).map { i in
            let hoursAgo = (count - 1 - i) * 2 // 2小时间隔
            let timestamp = now.addingTimeInterval(TimeInterval(-hoursAgo * 3600))

            let variation = Int.random(in: -baseHeat/10...baseHeat/10)
            let trendOffset: Int
            switch trend {
            case .rising:
                trendOffset = i * (baseHeat / count / 2)
            case .falling:
                trendOffset = -i * (baseHeat / count / 2)
            case .stable:
                trendOffset = 0
            case .explosive:
                trendOffset = i * i * (baseHeat / count / 4)
            }

            return HeatDataPoint(
                timestamp: timestamp,
                heatValue: max(1000, baseHeat + variation + trendOffset),
                rank: max(1, 10 - i / 2)
            )
        }
    }

    enum HeatTrend {
        case rising
        case falling
        case stable
        case explosive
    }

    // MARK: - Weibo Topics

    static let weiboTopics: [TrendTopicEntity] = [
        TrendTopicEntity(
            id: "weibo-1",
            platform: .weibo,
            title: "某顶流官宣恋情 粉丝集体破防",
            description: "知名艺人深夜发文官宣恋情，相关话题瞬间登顶热搜",
            heatValue: 2_580_000,
            rank: 1,
            tags: ["娱乐", "明星"],
            fetchedAt: Date().addingTimeInterval(-1800),
            rankChange: .new,
            heatHistory: generateHeatHistory(baseHeat: 2_000_000, trend: .explosive)
        ),
        TrendTopicEntity(
            id: "weibo-2",
            platform: .weibo,
            title: "春节档电影票房破纪录",
            description: "2026年春节档首日票房突破15亿",
            heatValue: 1_850_000,
            rank: 2,
            tags: ["电影", "春节"],
            fetchedAt: Date().addingTimeInterval(-3600),
            rankChange: .up(3),
            heatHistory: generateHeatHistory(baseHeat: 1_500_000, trend: .rising)
        ),
        TrendTopicEntity(
            id: "weibo-3",
            platform: .weibo,
            title: "某地突发地震 震感明显",
            description: "中国地震台网正式测定相关信息",
            heatValue: 1_200_000,
            rank: 3,
            tags: ["突发", "地震"],
            fetchedAt: Date().addingTimeInterval(-7200),
            rankChange: .up(5),
            heatHistory: generateHeatHistory(baseHeat: 800_000, trend: .explosive)
        ),
        TrendTopicEntity(
            id: "weibo-4",
            platform: .weibo,
            title: "国产手机发布会汇总",
            description: "多款新机型同日发布，各有亮点",
            heatValue: 680_000,
            rank: 4,
            tags: ["科技", "手机"],
            fetchedAt: Date().addingTimeInterval(-5400),
            rankChange: .down(1),
            heatHistory: generateHeatHistory(baseHeat: 700_000, trend: .falling)
        ),
        TrendTopicEntity(
            id: "weibo-5",
            platform: .weibo,
            title: "央视春晚节目单曝光",
            description: "今年春晚将有多位重磅嘉宾登台",
            heatValue: 520_000,
            rank: 5,
            tags: ["春晚", "娱乐"],
            fetchedAt: Date().addingTimeInterval(-9000),
            rankChange: .unchanged,
            heatHistory: generateHeatHistory(baseHeat: 500_000, trend: .stable)
        ),
        TrendTopicEntity(
            id: "weibo-6",
            platform: .weibo,
            title: "某品牌新品翻车",
            description: "知名品牌新品宣传引发争议",
            heatValue: 380_000,
            rank: 6,
            tags: ["消费", "争议"],
            fetchedAt: Date().addingTimeInterval(-10800),
            rankChange: .up(8),
            heatHistory: generateHeatHistory(baseHeat: 300_000, trend: .rising)
        )
    ]

    // MARK: - Xiaohongshu Topics

    static let xiaohongshuTopics: [TrendTopicEntity] = [
        TrendTopicEntity(
            id: "xhs-1",
            platform: .xiaohongshu,
            title: "2026早春穿搭灵感合集",
            description: "时尚博主们的早春look分享",
            heatValue: 890_000,
            rank: 1,
            tags: ["穿搭", "时尚"],
            fetchedAt: Date().addingTimeInterval(-2700),
            rankChange: .new,
            heatHistory: generateHeatHistory(baseHeat: 700_000, trend: .rising)
        ),
        TrendTopicEntity(
            id: "xhs-2",
            platform: .xiaohongshu,
            title: "居家收纳神器测评",
            description: "这些收纳好物真的太实用了",
            heatValue: 650_000,
            rank: 2,
            tags: ["居家", "收纳"],
            fetchedAt: Date().addingTimeInterval(-5400),
            rankChange: .up(2),
            heatHistory: generateHeatHistory(baseHeat: 550_000, trend: .rising)
        ),
        TrendTopicEntity(
            id: "xhs-3",
            platform: .xiaohongshu,
            title: "新年妆容教程",
            description: "超详细的新年妆教程来啦",
            heatValue: 480_000,
            rank: 3,
            tags: ["美妆", "教程"],
            fetchedAt: Date().addingTimeInterval(-7200),
            rankChange: .down(1),
            heatHistory: generateHeatHistory(baseHeat: 500_000, trend: .falling)
        ),
        TrendTopicEntity(
            id: "xhs-4",
            platform: .xiaohongshu,
            title: "减脂餐食谱分享",
            description: "好吃不胖的减脂餐做法",
            heatValue: 320_000,
            rank: 4,
            tags: ["美食", "减脂"],
            fetchedAt: Date().addingTimeInterval(-10800),
            rankChange: .unchanged,
            heatHistory: generateHeatHistory(baseHeat: 300_000, trend: .stable)
        ),
        TrendTopicEntity(
            id: "xhs-5",
            platform: .xiaohongshu,
            title: "旅行好物推荐",
            description: "出门必带的旅行神器",
            heatValue: 280_000,
            rank: 5,
            tags: ["旅行", "好物"],
            fetchedAt: Date().addingTimeInterval(-14400),
            rankChange: .up(4),
            heatHistory: generateHeatHistory(baseHeat: 200_000, trend: .rising)
        )
    ]

    // MARK: - Bilibili Topics

    static let bilibiliTopics: [TrendTopicEntity] = [
        TrendTopicEntity(
            id: "bili-1",
            platform: .bilibili,
            title: "年度游戏大作正式发售",
            description: "万众期待的3A大作终于来了",
            heatValue: 1_650_000,
            rank: 1,
            tags: ["游戏", "新作"],
            fetchedAt: Date().addingTimeInterval(-1800),
            rankChange: .new,
            heatHistory: generateHeatHistory(baseHeat: 1_200_000, trend: .explosive)
        ),
        TrendTopicEntity(
            id: "bili-2",
            platform: .bilibili,
            title: "知名UP主年度盘点",
            description: "头部创作者的年度创作总结",
            heatValue: 980_000,
            rank: 2,
            tags: ["UP主", "年度"],
            fetchedAt: Date().addingTimeInterval(-3600),
            rankChange: .up(1),
            heatHistory: generateHeatHistory(baseHeat: 800_000, trend: .rising)
        ),
        TrendTopicEntity(
            id: "bili-3",
            platform: .bilibili,
            title: "番剧新番推荐",
            description: "1月新番哪部最值得追",
            heatValue: 720_000,
            rank: 3,
            tags: ["番剧", "动漫"],
            fetchedAt: Date().addingTimeInterval(-5400),
            rankChange: .down(1),
            heatHistory: generateHeatHistory(baseHeat: 750_000, trend: .falling)
        ),
        TrendTopicEntity(
            id: "bili-4",
            platform: .bilibili,
            title: "鬼畜区新王诞生",
            description: "这个作品太魔性了",
            heatValue: 550_000,
            rank: 4,
            tags: ["鬼畜", "搞笑"],
            fetchedAt: Date().addingTimeInterval(-7200),
            rankChange: .up(6),
            heatHistory: generateHeatHistory(baseHeat: 400_000, trend: .rising)
        ),
        TrendTopicEntity(
            id: "bili-5",
            platform: .bilibili,
            title: "科技区硬核评测",
            description: "最新电子产品深度测评",
            heatValue: 420_000,
            rank: 5,
            tags: ["科技", "评测"],
            fetchedAt: Date().addingTimeInterval(-10800),
            rankChange: .unchanged,
            heatHistory: generateHeatHistory(baseHeat: 400_000, trend: .stable)
        ),
        TrendTopicEntity(
            id: "bili-6",
            platform: .bilibili,
            title: "虚拟主播联动直播",
            description: "超人气V圈联动活动",
            heatValue: 380_000,
            rank: 6,
            tags: ["虚拟主播", "直播"],
            fetchedAt: Date().addingTimeInterval(-14400),
            rankChange: .down(2),
            heatHistory: generateHeatHistory(baseHeat: 450_000, trend: .falling)
        )
    ]

    // MARK: - Douyin Topics

    static let douyinTopics: [TrendTopicEntity] = [
        TrendTopicEntity(
            id: "douyin-1",
            platform: .douyin,
            title: "全网爆火挑战赛",
            description: "这个挑战也太上头了",
            heatValue: 3_200_000,
            rank: 1,
            tags: ["挑战赛", "热门"],
            fetchedAt: Date().addingTimeInterval(-900),
            rankChange: .new,
            heatHistory: generateHeatHistory(baseHeat: 2_500_000, trend: .explosive)
        ),
        TrendTopicEntity(
            id: "douyin-2",
            platform: .douyin,
            title: "神曲洗脑循环",
            description: "一听就停不下来的BGM",
            heatValue: 2_100_000,
            rank: 2,
            tags: ["音乐", "神曲"],
            fetchedAt: Date().addingTimeInterval(-2700),
            rankChange: .up(2),
            heatHistory: generateHeatHistory(baseHeat: 1_800_000, trend: .rising)
        ),
        TrendTopicEntity(
            id: "douyin-3",
            platform: .douyin,
            title: "萌宠日常合集",
            description: "被这些小可爱治愈了",
            heatValue: 1_500_000,
            rank: 3,
            tags: ["萌宠", "可爱"],
            fetchedAt: Date().addingTimeInterval(-5400),
            rankChange: .unchanged,
            heatHistory: generateHeatHistory(baseHeat: 1_500_000, trend: .stable)
        ),
        TrendTopicEntity(
            id: "douyin-4",
            platform: .douyin,
            title: "美食探店vlog",
            description: "带你吃遍各地美食",
            heatValue: 980_000,
            rank: 4,
            tags: ["美食", "探店"],
            fetchedAt: Date().addingTimeInterval(-7200),
            rankChange: .down(1),
            heatHistory: generateHeatHistory(baseHeat: 1_000_000, trend: .falling)
        ),
        TrendTopicEntity(
            id: "douyin-5",
            platform: .douyin,
            title: "变装秀名场面",
            description: "这个变装太惊艳了",
            heatValue: 750_000,
            rank: 5,
            tags: ["变装", "创意"],
            fetchedAt: Date().addingTimeInterval(-10800),
            rankChange: .up(5),
            heatHistory: generateHeatHistory(baseHeat: 500_000, trend: .rising)
        )
    ]

    // MARK: - X Topics

    static let xTopics: [TrendTopicEntity] = [
        TrendTopicEntity(
            id: "x-1",
            platform: .x,
            title: "AI New Breakthrough Announced",
            description: "Major tech company reveals next-gen AI model",
            heatValue: 1_850_000,
            rank: 1,
            tags: ["AI", "Tech"],
            fetchedAt: Date().addingTimeInterval(-1800),
            rankChange: .new,
            heatHistory: generateHeatHistory(baseHeat: 1_500_000, trend: .explosive)
        ),
        TrendTopicEntity(
            id: "x-2",
            platform: .x,
            title: "Global Climate Summit 2026",
            description: "World leaders gather for crucial climate talks",
            heatValue: 1_200_000,
            rank: 2,
            tags: ["Climate", "Politics"],
            fetchedAt: Date().addingTimeInterval(-3600),
            rankChange: .up(1),
            heatHistory: generateHeatHistory(baseHeat: 1_000_000, trend: .rising)
        ),
        TrendTopicEntity(
            id: "x-3",
            platform: .x,
            title: "SpaceX Mars Mission Update",
            description: "Latest progress on Mars colonization project",
            heatValue: 890_000,
            rank: 3,
            tags: ["Space", "Technology"],
            fetchedAt: Date().addingTimeInterval(-5400),
            rankChange: .down(1),
            heatHistory: generateHeatHistory(baseHeat: 920_000, trend: .falling)
        ),
        TrendTopicEntity(
            id: "x-4",
            platform: .x,
            title: "Crypto Market Rally",
            description: "Major cryptocurrencies see significant gains",
            heatValue: 650_000,
            rank: 4,
            tags: ["Crypto", "Finance"],
            fetchedAt: Date().addingTimeInterval(-7200),
            rankChange: .up(8),
            heatHistory: generateHeatHistory(baseHeat: 400_000, trend: .rising)
        ),
        TrendTopicEntity(
            id: "x-5",
            platform: .x,
            title: "Super Bowl LXII Preview",
            description: "Everything you need to know about the big game",
            heatValue: 520_000,
            rank: 5,
            tags: ["Sports", "NFL"],
            fetchedAt: Date().addingTimeInterval(-10800),
            rankChange: .unchanged,
            heatHistory: generateHeatHistory(baseHeat: 500_000, trend: .stable)
        )
    ]

    // MARK: - Zhihu Topics

    static let zhihuTopics: [TrendTopicEntity] = [
        TrendTopicEntity(
            id: "zhihu-1",
            platform: .zhihu,
            title: "如何评价最新发布的 AI 大模型？",
            description: "各路专家深度解读新模型的技术突破",
            heatValue: 780_000,
            rank: 1,
            tags: ["AI", "科技"],
            fetchedAt: Date().addingTimeInterval(-2700),
            rankChange: .new,
            heatHistory: generateHeatHistory(baseHeat: 600_000, trend: .rising)
        ),
        TrendTopicEntity(
            id: "zhihu-2",
            platform: .zhihu,
            title: "年轻人的第一份工作应该怎么选？",
            description: "职场前辈们的建议分享",
            heatValue: 520_000,
            rank: 2,
            tags: ["职场", "建议"],
            fetchedAt: Date().addingTimeInterval(-5400),
            rankChange: .up(3),
            heatHistory: generateHeatHistory(baseHeat: 400_000, trend: .rising)
        ),
        TrendTopicEntity(
            id: "zhihu-3",
            platform: .zhihu,
            title: "读博是一种怎样的体验？",
            description: "在读博士和毕业博士的真实分享",
            heatValue: 380_000,
            rank: 3,
            tags: ["教育", "学术"],
            fetchedAt: Date().addingTimeInterval(-7200),
            rankChange: .unchanged,
            heatHistory: generateHeatHistory(baseHeat: 380_000, trend: .stable)
        ),
        TrendTopicEntity(
            id: "zhihu-4",
            platform: .zhihu,
            title: "有哪些值得推荐的纪录片？",
            description: "豆瓣高分纪录片推荐",
            heatValue: 280_000,
            rank: 4,
            tags: ["纪录片", "推荐"],
            fetchedAt: Date().addingTimeInterval(-10800),
            rankChange: .down(2),
            heatHistory: generateHeatHistory(baseHeat: 320_000, trend: .falling)
        ),
        TrendTopicEntity(
            id: "zhihu-5",
            platform: .zhihu,
            title: "普通人如何开始理财？",
            description: "从零开始的理财入门指南",
            heatValue: 220_000,
            rank: 5,
            tags: ["理财", "金融"],
            fetchedAt: Date().addingTimeInterval(-14400),
            rankChange: .up(5),
            heatHistory: generateHeatHistory(baseHeat: 150_000, trend: .rising)
        )
    ]
}

// MARK: - Preview Helpers

#if DEBUG
extension MockData {
    /// 用于 Preview 的单个话题
    static var sampleTopic: TrendTopicEntity {
        weiboTopics[0]
    }

    /// 用于 Preview 的话题列表
    static var sampleTopics: [TrendTopicEntity] {
        Array(allTopics.prefix(10))
    }
}
#endif
