import Foundation
import OSLog
import SwiftData

/// 依赖注入容器
/// 负责管理和提供应用程序的所有依赖
@MainActor
final class DependencyContainer {

    // MARK: - Singleton

    static let shared = DependencyContainer()

    // MARK: - Dependencies

    private var modelContainer: ModelContainer?

    // MARK: - Initialization

    private init() {}

    /// 配置容器（由 TrendLensApp 调用，传入统一的 ModelContainer）
    func configure(with container: ModelContainer) {
        guard modelContainer == nil else { return }
        modelContainer = container
    }

    // MARK: - Private Helpers

    private var container: ModelContainer {
        guard let modelContainer else {
            fatalError("DependencyContainer.configure(with:) must be called before use")
        }
        return modelContainer
    }

    // MARK: - Factory Methods - Data Layer

    func makeTrendingRepository() -> TrendingRepository {
        let localDataSource = LocalTrendingDataSource(modelContext: container.mainContext)
        let remoteDataSource = RemoteTrendingDataSource()
        return TrendingRepositoryImpl(
            localDataSource: localDataSource,
            remoteDataSource: remoteDataSource
        )
    }

    func makeTrendRepository() -> TrendRepository {
        TrendRepositoryImpl(remoteDataSource: RemoteTrendingDataSource())
    }

    func makeUserPreferenceRepository() -> UserPreferenceRepository {
        let localDataSource = LocalUserPreferenceDataSource(modelContext: container.mainContext)
        return UserPreferenceRepositoryImpl(localDataSource: localDataSource)
    }

    // MARK: - Factory Methods - Use Cases

    func makeFetchTrendingUseCase() -> FetchTrendingUseCase {
        FetchTrendingUseCase(
            repository: makeTrendingRepository(),
            preferenceRepository: makeUserPreferenceRepository()
        )
    }

    func makeComparePlatformsUseCase() -> ComparePlatformsUseCase {
        ComparePlatformsUseCase(repository: makeTrendingRepository())
    }

    func makeSearchTrendingUseCase() -> SearchTrendingUseCase {
        SearchTrendingUseCase(repository: makeTrendingRepository())
    }

    func makeFetchTrendsUseCase() -> FetchTrendsUseCase {
        FetchTrendsUseCase(repository: makeTrendRepository())
    }

    func makeManageFavoritesUseCase() -> ManageFavoritesUseCase {
        ManageFavoritesUseCase(
            trendingRepository: makeTrendingRepository(),
            preferenceRepository: makeUserPreferenceRepository()
        )
    }

    // MARK: - Factory Methods - ViewModels

    func makeFeedViewModel() -> FeedViewModel {
        FeedViewModel(
            fetchTrendingUseCase: makeFetchTrendingUseCase(),
            manageFavoritesUseCase: makeManageFavoritesUseCase()
        )
    }

    func makeCompareViewModel() -> CompareViewModel {
        CompareViewModel(comparePlatformsUseCase: makeComparePlatformsUseCase())
    }

    func makeSearchViewModel() -> SearchViewModel {
        SearchViewModel(searchTrendingUseCase: makeSearchTrendingUseCase())
    }

    func makeTrendsViewModel() -> TrendsViewModel {
        TrendsViewModel(fetchTrendsUseCase: makeFetchTrendsUseCase())
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(preferenceRepository: makeUserPreferenceRepository())
    }

    // MARK: - Data Initialization

    /// 初始化数据库（首次启动检查）
    func initializeDataIfNeeded() async {
        let context = container.mainContext
        let descriptor = FetchDescriptor<TrendSnapshot>()

        do {
            let existingSnapshots = try context.fetch(descriptor)
            if existingSnapshots.isEmpty {
                AppLog.lifecycle.info("DB_INIT empty, will fetch on first load")
            }
        } catch {
            AppLog.lifecycle.error("DB_INIT FAILED error=\(error.localizedDescription)")
        }
    }
}
