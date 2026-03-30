//
//  TrendLensApp.swift
//  TrendLens
//
//  Created by Shuangrui CHEN on 1/16/26.
//

import SwiftUI
import SwiftData

@main
struct TrendLensApp: App {
    /// DI 已配置，可以安全创建 MainNavigationView
    @State private var isConfigured = false
    /// Splash 覆盖层是否显示
    @State private var showSplash = true
    /// Splash 动画已播放完毕
    @State private var splashAnimationDone = false
    /// 数据初始化已完成
    @State private var dataInitDone = false

    private static let schemaVersion = 2

    private let modelContainer: ModelContainer = {
        let storeURL = URL.applicationSupportDirectory.appending(path: "default.store")

        let savedVersion = UserDefaults.standard.integer(forKey: "trendlens_schema_version")
        if savedVersion < schemaVersion {
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            UserDefaults.standard.set(schemaVersion, forKey: "trendlens_schema_version")
        }

        do {
            return try ModelContainer(
                for: TrendSnapshot.self, TrendTopic.self, UserPreference.self
            )
        } catch {
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("wal"))
            try? FileManager.default.removeItem(at: storeURL.appendingPathExtension("shm"))
            do {
                return try ModelContainer(
                    for: TrendSnapshot.self, TrendTopic.self, UserPreference.self
                )
            } catch {
                fatalError("Failed to create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ZStack {
                // 主界面（DI 配置完成后才创建）
                if isConfigured {
                    MainNavigationView()
                }

                // Splash 覆盖层（淡出移除）
                if showSplash {
                    SplashView {
                        splashAnimationDone = true
                        dismissSplashIfReady()
                    }
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            .task {
                // 1. 配置 DI（极快）
                DependencyContainer.shared.configure(with: modelContainer)

                // 2. 标记已配置 → MainNavigationView 开始创建（在 Splash 下方）
                isConfigured = true

                // 3. 数据预加载
                await DependencyContainer.shared.initializeDataIfNeeded()

                // 4. 数据就绪
                dataInitDone = true
                dismissSplashIfReady()
            }
        }
        .modelContainer(modelContainer)
    }

    /// 两个条件都满足时，淡出 Splash
    private func dismissSplashIfReady() {
        guard splashAnimationDone && dataInitDone && showSplash else { return }
        withAnimation(.easeInOut(duration: 0.5)) {
            showSplash = false
        }
    }
}
