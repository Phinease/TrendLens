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

    // MARK: - Initialization

    private init() {
        // 初始化 SwiftData ModelContainer（含 schema reset 容错）
        do {
            self.modelContainer = try ModelContainer(
                for: TrendSnapshot.self,
                TrendTopic.self,
                UserPreference.self
            )
        } catch {
            // Schema migration failed (e.g. Platform enum rawValue change) — delete old store and retry
            print("⚠️ ModelContainer init failed: \(error). Resetting SwiftData store...")
            let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")
            try? FileManager.default.removeItem(at: storeURL)
            // Also remove WAL/SHM if present
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            do {
                self.modelContainer = try ModelContainer(
                    for: TrendSnapshot.self,
                    TrendTopic.self,
                    UserPreference.self
                )
            } catch {
                fatalError("Failed to initialize ModelContainer after reset: \(error)")
            }
        }
    }

    // MARK: - Factory Methods - Data Layer

    func makeTrendingRepository() -> TrendingRepository {
        let localDataSource = LocalTrendingDataSource(modelContext: modelContainer.mainContext)
        let remoteDataSource = RemoteTrendingDataSource()
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

    /// 初始化数据库（远程模式下首次启动从 Supabase 拉取）
    func initializeDataIfNeeded() async {
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<TrendSnapshot>()

        do {
            let existingSnapshots = try context.fetch(descriptor)

            if existingSnapshots.isEmpty {
                print("📦 Database is empty, will fetch from Supabase on first load")
                // Data will be fetched through the normal repository flow
                // when FeedViewModel loads. No mock data needed.
            }
        } catch {
            print("❌ Failed to check database: \(error)")
        }
    }
}
