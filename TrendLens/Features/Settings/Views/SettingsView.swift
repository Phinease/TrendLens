//
//  SettingsView.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// Settings 页面 - 应用设置
struct SettingsView: View {
    @State private var viewModel = DependencyContainer.shared.makeSettingsViewModel()

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        Text("平台管理")
                    } label: {
                        Label("平台管理", systemImage: "square.grid.2x2")
                    }

                    NavigationLink {
                        Text("屏蔽词")
                    } label: {
                        Label("屏蔽词", systemImage: "hand.raised")
                    }

                    NavigationLink {
                        Text("刷新设置")
                    } label: {
                        Label("刷新设置", systemImage: "arrow.clockwise")
                    }
                } header: {
                    Text("内容设置")
                }

                Section {
                    NavigationLink {
                        Text("外观")
                    } label: {
                        Label("外观", systemImage: "paintbrush")
                    }

                    NavigationLink {
                        Text("通知")
                    } label: {
                        Label("通知", systemImage: "bell")
                    }
                } header: {
                    Text("应用设置")
                }

                Section {
                    NavigationLink {
                        Text("关于")
                    } label: {
                        Label("关于 TrendLens", systemImage: "info.circle")
                    }

                    NavigationLink {
                        Text("隐私政策")
                    } label: {
                        Label("隐私政策", systemImage: "hand.raised.shield")
                    }
                } header: {
                    Text("其他")
                }
            }
            .navigationTitle("设置")
        }
    }
}

#Preview {
    SettingsView()
}
