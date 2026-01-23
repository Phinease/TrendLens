import Foundation

/// 远程热榜数据源
actor RemoteTrendingDataSource {

    // MARK: - Dependencies

    private let networkClient: NetworkClient

    // MARK: - Configuration

    /// 远程数据源基础 URL
    /// TODO: 配置实际的 CDN/API 地址
    private let baseURL = "https://api.trendlens.example.com"

    // MARK: - Initialization

    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }

    // MARK: - Public Methods

    /// 从远程获取热榜快照
    /// - Parameters:
    ///   - platform: 平台
    ///   - etag: ETag（用于缓存控制）
    /// - Returns: 热榜快照实体
    func fetchSnapshot(
        for platform: Platform,
        etag: String?
    ) async throws -> TrendSnapshotEntity {
        let url = try buildSnapshotURL(for: platform)

        let (dto, newETag) = try await networkClient.fetchAndDecode(
            TrendSnapshotDTO.self,
            from: url,
            etag: etag
        )

        return dto.toDomainEntity(etag: newETag)
    }

    // MARK: - Helper Methods

    private func buildSnapshotURL(for platform: Platform) throws -> URL {
        // 构建 CDN URL，例如：
        // https://cdn.trendlens.example.com/snapshots/weibo/latest.json
        let urlString = "\(baseURL)/snapshots/\(platform.rawValue)/latest.json"

        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }

        return url
    }
}

// MARK: - DTO (Data Transfer Object)

/// 热榜快照 DTO（从 API 接收的格式）
struct TrendSnapshotDTO: Codable, @unchecked Sendable {
    let id: String
    let platform: String
    let fetchedAt: String
    let validUntil: String
    let contentHash: String
    let schemaVersion: Int
    let topics: [TrendTopicDTO]

    nonisolated func toDomainEntity(etag: String?) -> TrendSnapshotEntity {
        let dateFormatter = ISO8601DateFormatter()

        return TrendSnapshotEntity(
            id: id,
            platform: Platform(rawValue: platform) ?? .weibo,
            fetchedAt: dateFormatter.date(from: fetchedAt) ?? Date(),
            validUntil: dateFormatter.date(from: validUntil) ?? Date(),
            contentHash: contentHash,
            etag: etag,
            schemaVersion: schemaVersion,
            topics: topics.map { $0.toDomainEntity() }
        )
    }
}

/// 热榜话题 DTO
struct TrendTopicDTO: Codable, @unchecked Sendable {
    let id: String
    let platform: String
    let title: String
    let description: String?
    let heatValue: Int
    let rank: Int
    let link: String?
    let tags: [String]
    let fetchedAt: String

    nonisolated func toDomainEntity() -> TrendTopicEntity {
        let dateFormatter = ISO8601DateFormatter()

        return TrendTopicEntity(
            id: id,
            platform: Platform(rawValue: platform) ?? .weibo,
            title: title,
            description: description,
            heatValue: heatValue,
            rank: rank,
            link: link,
            tags: tags,
            fetchedAt: dateFormatter.date(from: fetchedAt) ?? Date()
        )
    }
}
