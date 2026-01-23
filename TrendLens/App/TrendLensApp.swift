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
            if showingSplash {
                SplashView()
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation {
                                showingSplash = false
                            }
                        }
                    }
            } else {
                FeedView()
            }
        }
        .modelContainer(sharedModelContainer)
    }
}
