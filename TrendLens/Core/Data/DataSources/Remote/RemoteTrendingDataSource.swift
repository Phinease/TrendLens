import Foundation
import Supabase
import CryptoKit

// MARK: - Supabase DTOs

struct SupabaseTopicDTO: Decodable {
    let topicKey: String
    let platformId: String
    let title: String
    let description: String?
    let content: String?
    let summary: String?
    let link: String?
    let imageUrls: [String]?
    let tags: [String]?
    let heatValue: Int?
    let rank: Int?
    let rankChange: RankChangeDTO?
    let fetchedAt: Date
    let isOnList: Bool

    enum CodingKeys: String, CodingKey {
        case topicKey = "topic_key"
        case platformId = "platform_id"
        case title, description, content, summary, link
        case imageUrls = "image_urls"
        case tags
        case heatValue = "heat_value"
        case rank
        case rankChange = "rank_change"
        case fetchedAt = "fetched_at"
        case isOnList = "is_on_list"
    }
}

struct RankChangeDTO: Decodable {
    let type: String
    let value: Int?

    nonisolated func toDomain() -> RankChange {
        switch type {
        case "new": return .new
        case "up": return .up(value ?? 0)
        case "down": return .down(value ?? 0)
        default: return .unchanged
        }
    }
}

struct SupabaseHeatHistoryDTO: Decodable {
    let topicKey: String
    let timestamp: Date
    let heatValue: Int?
    let rank: Int?

    enum CodingKeys: String, CodingKey {
        case topicKey = "topic_key"
        case timestamp
        case heatValue = "heat_value"
        case rank
    }
}

struct SupabaseTopicTrendDTO: Decodable {
    let keyword: String
    let relevance: Double
    let dataSource: String
    let resolution: String
    let geo: String
    let timestamps: [Date]
    let trendValues: [Int]
    let queriedAt: Date

    enum CodingKeys: String, CodingKey {
        case keyword
        case relevance
        case dataSource = "data_source"
        case resolution
        case geo
        case timestamps
        case trendValues = "trend_values"
        case queriedAt = "queried_at"
    }
}

struct TopicTrendSeries: Sendable, Equatable {
    let keyword: String
    let dataSource: String
    let resolution: String
    let geo: String
    let relevance: Double
    let points: [HeatDataPoint]
}

// MARK: - Remote Data Source

/// 远程热榜数据源（Supabase）
actor RemoteTrendingDataSource {

    private let client: SupabaseClient

    init(client: SupabaseClient = supabaseClient) {
        self.client = client
    }

    // MARK: - Public Methods

    /// 获取指定平台在榜话题
    func fetchTopics(for platform: Platform) async throws -> [SupabaseTopicDTO] {
        try await client.from("topics")
            .select()
            .eq("platform_id", value: platform.rawValue)
            .eq("is_on_list", value: true)
            .order("rank")
            .execute()
            .value
    }

    /// 获取所有在榜话题
    func fetchAllOnListTopics() async throws -> [SupabaseTopicDTO] {
        try await client.from("topics")
            .select()
            .eq("is_on_list", value: true)
            .order("heat_value", ascending: false)
            .limit(200)
            .execute()
            .value
    }

    /// 获取话题热度历史
    func fetchHeatHistory(for topicKey: String, limit: Int = 96) async throws -> [HeatDataPoint] {
        let dtos: [SupabaseHeatHistoryDTO] = try await client.from("heat_history")
            .select()
            .eq("topic_key", value: topicKey)
            .order("timestamp", ascending: false)
            .limit(limit)
            .execute()
            .value

        return dtos.map { dto in
            HeatDataPoint(
                timestamp: dto.timestamp,
                heatValue: dto.heatValue ?? 0,
                rank: dto.rank
            )
        }.reversed()
    }

    /// 获取话题关联的 Google Trends 趋势数据
    func fetchTopicTrendSeries(for topicKey: String) async throws -> TopicTrendSeries? {
        let params: [String: String] = ["p_topic_key": topicKey]
        let dtos: [SupabaseTopicTrendDTO] = try await client
            .rpc("get_topic_trend_data", params: params)
            .execute()
            .value

        let candidate = dtos
            .map { dto in
                let points = zip(dto.timestamps, dto.trendValues).map { timestamp, value in
                    HeatDataPoint(timestamp: timestamp, heatValue: value)
                }

                return TopicTrendSeries(
                    keyword: dto.keyword,
                    dataSource: dto.dataSource,
                    resolution: dto.resolution,
                    geo: dto.geo,
                    relevance: dto.relevance,
                    points: points.sorted { $0.timestamp < $1.timestamp }
                )
            }
            .filter { $0.points.count >= 2 }
            .sorted {
                if $0.relevance == $1.relevance {
                    return $0.points.count > $1.points.count
                }
                return $0.relevance > $1.relevance
            }
            .first

        return candidate
    }

    /// 搜索话题
    func searchTopics(query: String, platforms: [Platform]?) async throws -> [SupabaseTopicDTO] {
        var request = client.from("topics")
            .select()
            .ilike("title", pattern: "%\(query)%")
            .eq("is_on_list", value: true)

        if let platforms = platforms, !platforms.isEmpty {
            let ids = platforms.map(\.rawValue)
            request = request.in("platform_id", values: ids)
        }

        return try await request
            .order("heat_value", ascending: false)
            .limit(50)
            .execute()
            .value
    }

    /// 获取快照（合成自话题查询结果）
    func fetchSnapshot(for platform: Platform) async throws -> TrendSnapshotEntity {
        let dtos = try await fetchTopics(for: platform)
        return synthesizeSnapshot(from: dtos, platform: platform)
    }

    // MARK: - DTO → Domain Mapping

    nonisolated func mapToEntity(_ dto: SupabaseTopicDTO) -> TrendTopicEntity {
        TrendTopicEntity(
            id: dto.topicKey,
            platform: Platform(rawValue: dto.platformId) ?? .weibo,
            title: dto.title,
            description: dto.description,
            heatValue: dto.heatValue ?? 0,
            rank: dto.rank ?? 0,
            link: dto.link,
            tags: dto.tags ?? [],
            fetchedAt: dto.fetchedAt,
            rankChange: dto.rankChange?.toDomain() ?? .unchanged,
            heatHistory: [],
            summary: dto.summary ?? "",
            isFavorite: false,
            content: dto.content,
            imageURLs: dto.imageUrls ?? [],
            comments: []
        )
    }

    // MARK: - Private

    private nonisolated func synthesizeSnapshot(
        from dtos: [SupabaseTopicDTO],
        platform: Platform
    ) -> TrendSnapshotEntity {
        let now = Date()
        let topics = dtos.map { mapToEntity($0) }
        let sortedKeys = topics.map(\.id).sorted().joined(separator: ",")
        let hashData = Data(sortedKeys.utf8)
        let contentHash = SHA256.hash(data: hashData).compactMap { String(format: "%02x", $0) }.joined()

        return TrendSnapshotEntity(
            id: "\(platform.rawValue)_\(ISO8601DateFormatter().string(from: now))",
            platform: platform,
            fetchedAt: now,
            validUntil: now.addingTimeInterval(900), // 15 min TTL
            contentHash: contentHash,
            etag: nil,
            schemaVersion: 1,
            topics: topics
        )
    }
}
