import Foundation

/// 平台对比用例
/// 负责计算多个平台热榜的交集和差集
struct ComparePlatformsUseCase: Sendable {

    // MARK: - Dependencies

    private let repository: TrendingRepository

    // MARK: - Initialization

    init(repository: TrendingRepository) {
        self.repository = repository
    }

    // MARK: - Use Case Methods

    /// 计算多个平台热榜的交集
    /// - Parameters:
    ///   - platforms: 要对比的平台列表
    ///   - similarityThreshold: 标题相似度阈值（0.0-1.0）
    /// - Returns: 交集话题列表
    func findIntersection(
        in platforms: [Platform],
        similarityThreshold: Double = 0.8
    ) async throws -> [ComparisonResult] {
        guard platforms.count >= 2 else {
            throw ComparisonError.insufficientPlatforms
        }

        let snapshots = try await repository.fetchLatestSnapshots(
            for: platforms,
            forceRefresh: false
        )

        // 创建话题分组字典（按标题相似度分组）
        var topicGroups: [[TrendTopicEntity]] = []

        for snapshot in snapshots {
            for topic in snapshot.topics {
                var foundGroup = false

                for i in 0..<topicGroups.count {
                    let group = topicGroups[i]
                    if let firstTopic = group.first,
                       calculateSimilarity(topic.title, firstTopic.title) >= similarityThreshold {
                        topicGroups[i].append(topic)
                        foundGroup = true
                        break
                    }
                }

                if !foundGroup {
                    topicGroups.append([topic])
                }
            }
        }

        // 筛选出在所有平台都出现的话题组
        let intersectionGroups = topicGroups.filter { group in
            let platformsInGroup = Set(group.map { $0.platform })
            return platformsInGroup.count == platforms.count
        }

        // 转换为 ComparisonResult
        return intersectionGroups.map { group in
            ComparisonResult(
                title: group.first!.title,
                topics: group,
                platforms: Set(group.map { $0.platform }),
                averageHeat: group.map { $0.heatValue }.reduce(0, +) / group.count
            )
        }.sorted { $0.averageHeat > $1.averageHeat }
    }

    /// 计算平台独有的热榜话题
    /// - Parameters:
    ///   - platform: 目标平台
    ///   - otherPlatforms: 对比的其他平台
    ///   - similarityThreshold: 标题相似度阈值
    /// - Returns: 该平台独有的话题列表
    func findUnique(
        in platform: Platform,
        comparedTo otherPlatforms: [Platform],
        similarityThreshold: Double = 0.8
    ) async throws -> [TrendTopicEntity] {
        let allPlatforms = [platform] + otherPlatforms
        let snapshots = try await repository.fetchLatestSnapshots(
            for: allPlatforms,
            forceRefresh: false
        )

        guard let targetSnapshot = snapshots.first(where: { $0.platform == platform }) else {
            return []
        }

        let otherSnapshots = snapshots.filter { $0.platform != platform }
        let otherTopics = otherSnapshots.flatMap { $0.topics }

        // 筛选出目标平台独有的话题
        let uniqueTopics = targetSnapshot.topics.filter { targetTopic in
            !otherTopics.contains { otherTopic in
                calculateSimilarity(targetTopic.title, otherTopic.title) >= similarityThreshold
            }
        }

        return uniqueTopics.sorted { $0.heatValue > $1.heatValue }
    }

    // MARK: - Helper Methods

    /// 计算两个字符串的相似度（简单实现，可替换为更复杂的算法）
    private func calculateSimilarity(_ str1: String, _ str2: String) -> Double {
        let normalized1 = str1.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let normalized2 = str2.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        if normalized1 == normalized2 {
            return 1.0
        }

        // 计算 Levenshtein 距离
        let distance = levenshteinDistance(normalized1, normalized2)
        let maxLength = max(normalized1.count, normalized2.count)

        return maxLength > 0 ? 1.0 - Double(distance) / Double(maxLength) : 0.0
    }

    /// Levenshtein 距离算法
    private func levenshteinDistance(_ str1: String, _ str2: String) -> Int {
        let len1 = str1.count
        let len2 = str2.count

        var matrix = Array(repeating: Array(repeating: 0, count: len2 + 1), count: len1 + 1)

        for i in 0...len1 { matrix[i][0] = i }
        for j in 0...len2 { matrix[0][j] = j }

        let arr1 = Array(str1)
        let arr2 = Array(str2)

        for i in 1...len1 {
            for j in 1...len2 {
                let cost = arr1[i - 1] == arr2[j - 1] ? 0 : 1
                matrix[i][j] = min(
                    matrix[i - 1][j] + 1,
                    matrix[i][j - 1] + 1,
                    matrix[i - 1][j - 1] + cost
                )
            }
        }

        return matrix[len1][len2]
    }
}

// MARK: - Supporting Types

/// 对比结果
struct ComparisonResult: Identifiable, Sendable {
    let id = UUID()
    let title: String
    let topics: [TrendTopicEntity]
    let platforms: Set<Platform>
    let averageHeat: Int
}

/// 对比错误
enum ComparisonError: LocalizedError {
    case insufficientPlatforms

    var errorDescription: String? {
        switch self {
        case .insufficientPlatforms:
            return "需要至少两个平台进行对比"
        }
    }
}
