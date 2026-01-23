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
            // Phase 1.5.1: 临时显示 CardGalleryView 用于卡片验证
            // Phase 2 时恢复为 MainNavigationView
            CardGalleryView()
        }
        .modelContainer(sharedModelContainer)
    }
}
