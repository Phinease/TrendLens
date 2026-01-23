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
    @State private var showingSplash = true

    // MARK: - SwiftData ModelContainer

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            TrendTopic.self,
            TrendSnapshot.self,
            UserPreference.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // MARK: - Scene

    var body: some Scene {
        WindowGroup {
            ZStack {
                if showingSplash {
                    SplashView()
                        .transition(.opacity)
                } else {
                    MainNavigationView()
                        .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: showingSplash)
            .task {
                // 初始化数据库
                await DependencyContainer.shared.initializeDataIfNeeded()

                // 启动页显示 2 秒后切换到主界面
                try? await Task.sleep(for: .seconds(2))
                showingSplash = false
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
