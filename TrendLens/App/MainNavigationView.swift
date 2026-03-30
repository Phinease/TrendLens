//
//  MainNavigationView.swift
//  TrendLens
//

import SwiftUI

/// 主导航容器 - 根据平台自动选择合适的导航方式
struct MainNavigationView: View {
    @State private var selectedTab: NavigationTab = .feed
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
#if os(macOS)
        macLayout
#else
        if horizontalSizeClass == .compact {
            compactLayout
        } else {
            regularLayout
        }
#endif
    }

    // MARK: - Compact Layout (TabView with Liquid Glass)

    private var compactLayout: some View {
        TabView(selection: $selectedTab) {
            Tab("热榜", systemImage: "flame", value: NavigationTab.feed) {
                FeedView()
            }

            Tab("对比", systemImage: "chart.bar.xaxis", value: NavigationTab.compare) {
                CompareView()
            }

            Tab("趋势", systemImage: "chart.line.uptrend.xyaxis", value: NavigationTab.trends) {
                TrendsView()
            }

            Tab("搜索", systemImage: "magnifyingglass", value: NavigationTab.search) {
                SearchView()
            }

            Tab("设置", systemImage: "gear", value: NavigationTab.settings) {
                SettingsView()
            }
        }
    }

    // MARK: - Regular Layout (NavigationSplitView for iPad)

    private var regularLayout: some View {
        NavigationSplitView {
            List {
                ForEach(NavigationTab.allCases, id: \.self) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Label(tab.title, systemImage: tab.icon)
                    }
                    .listRowBackground(
                        selectedTab == tab ? Color.accentColor.opacity(0.2) : Color.clear
                    )
                }
            }
            .navigationTitle("TrendLens")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
        } detail: {
            selectedView
        }
    }

#if os(macOS)
    // MARK: - macOS Layout (NavigationSplitView)

    private var macLayout: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                ForEach(NavigationTab.allCases, id: \.self) { tab in
                    Label(tab.title, systemImage: tab.icon)
                        .tag(tab)
                }
            }
            .navigationTitle("TrendLens")
            .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } detail: {
            selectedView
        }
        .frame(minWidth: 800, minHeight: 600)
    }
#endif

    // MARK: - Detail View

    @ViewBuilder
    private var selectedView: some View {
        switch selectedTab {
        case .feed:
            FeedView()
        case .compare:
            CompareView()
        case .trends:
            TrendsView()
        case .search:
            SearchView()
        case .settings:
            SettingsView()
        }
    }
}

// MARK: - Navigation Tab

enum NavigationTab: String, CaseIterable {
    case feed
    case compare
    case trends
    case search
    case settings

    var title: String {
        switch self {
        case .feed: "热榜"
        case .compare: "对比"
        case .trends: "趋势"
        case .search: "搜索"
        case .settings: "设置"
        }
    }

    var icon: String {
        switch self {
        case .feed: "flame"
        case .compare: "chart.bar.xaxis"
        case .trends: "chart.line.uptrend.xyaxis"
        case .search: "magnifyingglass"
        case .settings: "gear"
        }
    }
}

// MARK: - Preview

#Preview("iPhone") {
    MainNavigationView()
}

#Preview("iPad") {
    MainNavigationView()
}
