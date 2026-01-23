//
//  SettingsView.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// Settings 页面 - 应用设置
struct SettingsView: View {

    // MARK: - State

    @State private var viewModel = DependencyContainer.shared.makeSettingsViewModel()
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // 平台管理
                Section {
                    NavigationLink {
                        PlatformManagementView(viewModel: viewModel)
                    } label: {
                        Label("订阅平台", systemImage: "square.grid.2x2")
                    }
                } header: {
                    Text("内容设置")
                }

                // 屏蔽词管理
                Section {
                    NavigationLink {
                        BlockedKeywordsView(viewModel: viewModel)
                    } label: {
                        Label("屏蔽词", systemImage: "hand.raised")
                    }
                }

                // 刷新设置
                Section {
                    NavigationLink {
                        RefreshSettingsView(viewModel: viewModel)
                    } label: {
                        Label("刷新设置", systemImage: "arrow.clockwise")
                    }
                }

                // 关于
                Section {
                    NavigationLink {
                        AboutView()
                    } label: {
                        Label("关于 TrendLens", systemImage: "info.circle")
                    }
                } header: {
                    Text("其他")
                }
            }
            .navigationTitle("设置")
            .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
        }
    }
}

// MARK: - Platform Management View

struct PlatformManagementView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        List {
            ForEach(Platform.allCases) { platform in
                Toggle(isOn: binding(for: platform)) {
                    HStack {
                        Image(systemName: platform.iconName)
                            .foregroundStyle(Color(hex: platform.themeColor))

                        Text(platform.displayName)
                    }
                }
            }
        }
        .navigationTitle("订阅平台")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private func binding(for platform: Platform) -> Binding<Bool> {
        Binding(
            get: { viewModel.subscribedPlatforms.contains(platform) },
            set: { isSubscribed in
                Task {
                    await viewModel.togglePlatformSubscription(platform, isSubscribed: isSubscribed)
                }
            }
        )
    }
}

// MARK: - Blocked Keywords View

struct BlockedKeywordsView: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var newKeyword = ""
    @State private var showingAddSheet = false

    var body: some View {
        List {
            Section {
                ForEach(viewModel.blockedKeywords, id: \.self) { keyword in
                    Text(keyword)
                }
                .onDelete { indexSet in
                    Task {
                        for index in indexSet {
                            await viewModel.removeBlockedKeyword(viewModel.blockedKeywords[index])
                        }
                    }
                }
            } header: {
                Text("已屏蔽的关键词")
            } footer: {
                Text("包含这些关键词的话题将不会显示")
            }
        }
        .navigationTitle("屏蔽词")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddKeywordSheet(viewModel: viewModel, newKeyword: $newKeyword)
        }
    }
}

// MARK: - Add Keyword Sheet

struct AddKeywordSheet: View {
    @Bindable var viewModel: SettingsViewModel
    @Binding var newKeyword: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("输入关键词", text: $newKeyword)
                } footer: {
                    Text("包含此关键词的话题将被过滤")
                }
            }
            .navigationTitle("添加屏蔽词")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("添加") {
                        Task {
                            await viewModel.addBlockedKeyword(newKeyword)
                            newKeyword = ""
                            dismiss()
                        }
                    }
                    .disabled(newKeyword.isEmpty)
                }
            }
        }
    }
}

// MARK: - Refresh Settings View

struct RefreshSettingsView: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Picker("刷新间隔", selection: $viewModel.refreshInterval) {
                    Text("15 分钟").tag(15)
                    Text("30 分钟").tag(30)
                    Text("1 小时").tag(60)
                    Text("手动刷新").tag(0)
                }
            } footer: {
                Text("设置自动刷新热榜数据的时间间隔")
            }

            Section {
                Toggle("后台刷新", isOn: $viewModel.isBackgroundRefreshEnabled)
            } footer: {
                Text("允许应用在后台自动刷新数据")
            }
        }
        .navigationTitle("刷新设置")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .onChange(of: viewModel.refreshInterval) { _, _ in
            Task {
                await viewModel.savePreferences()
            }
        }
        .onChange(of: viewModel.isBackgroundRefreshEnabled) { _, _ in
            Task {
                await viewModel.savePreferences()
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        List {
            Section {
                HStack {
                    Text("版本")
                    Spacer()
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("构建号")
                    Spacer()
                    Text("1")
                        .foregroundStyle(.secondary)
                }
            }

            Section {
                Link(destination: URL(string: "https://github.com")!) {
                    HStack {
                        Text("GitHub")
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("开源")
            }

            Section {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Text("TrendLens")
                        .font(DesignSystem.Typography.headline)

                    Text("跨平台热搜聚合应用")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)

                    Text("© 2026 TrendLens. All rights reserved.")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.top, DesignSystem.Spacing.xs)
                }
                .padding(.vertical, DesignSystem.Spacing.xs)
            }
        }
        .navigationTitle("关于")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
