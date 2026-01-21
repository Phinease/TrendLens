import Foundation

/// 热榜数据仓库协议
/// 定义热榜数据的获取、缓存和查询接口
protocol TrendingRepository: Sendable {

    /// 获取指定平台的最新热榜
    /// - Parameters:
    ///   - platform: 平台
    ///   - forceRefresh: 是否强制刷新（忽略缓存）
    /// - Returns: 热榜快照
    func fetchLatestSnapshot(
        for platform: Platform,
        forceRefresh: Bool
    ) async throws -> TrendSnapshotEntity

    /// 获取多个平台的最新热榜
    /// - Parameters:
    ///   - platforms: 平台列表
    ///   - forceRefresh: 是否强制刷新
    /// - Returns: 热榜快照列表
    func fetchLatestSnapshots(
        for platforms: [Platform],
        forceRefresh: Bool
    ) async throws -> [TrendSnapshotEntity]

    /// 获取所有平台的最新热榜
    /// - Parameter forceRefresh: 是否强制刷新
    /// - Returns: 热榜快照列表
    func fetchAllLatestSnapshots(
        forceRefresh: Bool
    ) async throws -> [TrendSnapshotEntity]

    /// 获取本地缓存的快照
    /// - Parameter platform: 平台
    /// - Returns: 缓存的快照（如果存在）
    func getCachedSnapshot(for platform: Platform) async throws -> TrendSnapshotEntity?

    /// 搜索话题
    /// - Parameters:
    ///   - query: 搜索关键词
    ///   - platforms: 限定平台（nil 表示全部）
    /// - Returns: 匹配的话题列表
    func searchTopics(
        query: String,
        in platforms: [Platform]?
    ) async throws -> [TrendTopicEntity]

    /// 获取话题详情
    /// - Parameter topicId: 话题 ID
    /// - Returns: 话题实体
    func getTopicDetail(topicId: String) async throws -> TrendTopicEntity?

    /// 清除过期缓存
    func clearExpiredCache() async throws
}
