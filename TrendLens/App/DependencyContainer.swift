import Foundation
import SwiftData

/// 依赖注入容器
/// 负责管理和提供应用程序的所有依赖
@MainActor
final class DependencyContainer {

    // MARK: - Singleton

    static let shared = DependencyContainer()

    // MARK: - Dependencies

    private let modelContainer: ModelContainer
    private let networkClient: NetworkClient

    // MARK: - Initialization

    private init() {
        // 初始化 SwiftData ModelContainer
        do {
            self.modelContainer = try ModelContainer(
                for: TrendSnapshot.self,
                TrendTopic.self,
                UserPreference.self
            )
        } catch {
            fatalError("Failed to initialize ModelContainer: \(error)")
        }

        // 初始化网络客户端
        self.networkClient = NetworkClient()
    }

    // MARK: - Factory Methods - Data Layer

    func makeTrendingRepository() -> TrendingRepository {
        let localDataSource = LocalTrendingDataSource(modelContext: modelContainer.mainContext)
        let remoteDataSource = RemoteTrendingDataSource(networkClient: networkClient)
        return TrendingRepositoryImpl(
            localDataSource: localDataSource,
            remoteDataSource: remoteDataSource
        )
    }

    func makeUserPreferenceRepository() -> UserPreferenceRepository {
        let localDataSource = LocalUserPreferenceDataSource(modelContext: modelContainer.mainContext)
        return UserPreferenceRepositoryImpl(localDataSource: localDataSource)
    }

    // MARK: - Factory Methods - Use Cases

    func makeFetchTrendingUseCase() -> FetchTrendingUseCase {
        FetchTrendingUseCase(repository: makeTrendingRepository())
    }

    func makeComparePlatformsUseCase() -> ComparePlatformsUseCase {
        ComparePlatformsUseCase(repository: makeTrendingRepository())
    }

    func makeSearchTrendingUseCase() -> SearchTrendingUseCase {
        SearchTrendingUseCase(repository: makeTrendingRepository())
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

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(preferenceRepository: makeUserPreferenceRepository())
    }

    // MARK: - Public Access

    var modelContainerForPreview: ModelContainer {
        modelContainer
    }
}
