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

    // MARK: - Data Initialization

    /// 初始化数据库（首次启动时填充 Mock 数据）
    func initializeDataIfNeeded() async {
        // 检查数据库是否为空
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<TrendSnapshot>()

        do {
            let existingSnapshots = try context.fetch(descriptor)

            // 如果数据库为空，填充初始数据
            if existingSnapshots.isEmpty {
                print("📦 Database is empty, initializing with mock data...")
                await fillInitialData()
            } else {
                print("✅ Database already contains data, skipping initialization")
            }
        } catch {
            print("❌ Failed to check database: \(error)")
        }
    }

    /// 填充初始数据
    private func fillInitialData() async {
        let generator = MockDataGenerator()

        do {
            // 为每个平台生成快照
            let snapshots = generator.generateAllSnapshots(topicsPerPlatform: 15)

            // 保存到数据库
            let localDataSource = LocalTrendingDataSource(modelContext: modelContainer.mainContext)

            for snapshot in snapshots {
                try await localDataSource.saveSnapshot(snapshot)
                print("✅ Saved snapshot for \(snapshot.platform.displayName)")
            }

            print("🎉 Initial data filled successfully!")
        } catch {
            print("❌ Failed to fill initial data: \(error)")
        }
    }

    /// 刷新所有平台数据（用于下拉刷新）
    func refreshAllData() async {
        let generator = MockDataGenerator()

        do {
            let snapshots = generator.generateAllSnapshots(topicsPerPlatform: 15)
            let localDataSource = LocalTrendingDataSource(modelContext: modelContainer.mainContext)

            for snapshot in snapshots {
                try await localDataSource.saveSnapshot(snapshot)
            }

            print("🔄 Data refreshed successfully!")
        } catch {
            print("❌ Failed to refresh data: \(error)")
        }
    }
}
