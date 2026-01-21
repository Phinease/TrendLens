//
//  MainNavigationView.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// 主导航容器 - 根据平台自动选择合适的导航方式
struct MainNavigationView: View {
    @State private var selectedTab: NavigationTab = .feed

    var body: some View {
#if os(iOS)
        // iPhone/iPad 根据屏幕尺寸决定
        if UIDevice.current.userInterfaceIdiom == .phone {
            iphoneLayout
        } else {
            ipadLayout
        }
#elseif os(macOS)
        macLayout
#else
        iphoneLayout
#endif
    }

    // MARK: - iPhone Layout (TabView)

    private var iphoneLayout: some View {
        TabView(selection: $selectedTab) {
            FeedView()
                .tabItem {
                    Label("热榜", systemImage: "flame")
                }
                .tag(NavigationTab.feed)

            CompareView()
                .tabItem {
                    Label("对比", systemImage: "chart.bar.xaxis")
                }
                .tag(NavigationTab.compare)

            SearchView()
                .tabItem {
                    Label("搜索", systemImage: "magnifyingglass")
                }
                .tag(NavigationTab.search)

            SettingsView()
                .tabItem {
                    Label("设置", systemImage: "gear")
                }
                .tag(NavigationTab.settings)
        }
    }

    // MARK: - iPad Layout (NavigationSplitView)

    private var ipadLayout: some View {
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
    case search
    case settings

    var title: String {
        switch self {
        case .feed: return "热榜"
        case .compare: return "对比"
        case .search: return "搜索"
        case .settings: return "设置"
        }
    }

    var icon: String {
        switch self {
        case .feed: return "flame"
        case .compare: return "chart.bar.xaxis"
        case .search: return "magnifyingglass"
        case .settings: return "gear"
        }
    }
}

// MARK: - Preview

#Preview("iPhone") {
    MainNavigationView()
}

#Preview("iPad") {
    MainNavigationView()
        .previewDevice(PreviewDevice(rawValue: "iPad Pro (12.9-inch)"))
}
