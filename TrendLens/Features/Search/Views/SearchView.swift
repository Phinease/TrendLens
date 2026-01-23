//
//  SearchView.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// Search 页面 - 搜索热点话题
struct SearchView: View {

    // MARK: - State

    @State private var viewModel = DependencyContainer.shared.makeSearchViewModel()
    @State private var searchText = ""
    @State private var selectedPlatform: Platform? = nil
    @State private var selectedTopic: TrendTopicEntity? = nil

    // MARK: - Computed Properties

    private var isSearching: Bool {
        !searchText.isEmpty
    }

    private var isLoading: Bool {
        viewModel.isLoading
    }

    private var hasError: Bool {
        viewModel.error != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 搜索框
                searchBar
                    .padding(.top, DesignSystem.Spacing.sm)

                // 平台筛选
                if isSearching {
                    platformFilter
                }

                // 内容区域
                contentView
            }
            .navigationTitle("搜索")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .background(Color(uiColor: .systemGroupedBackground))
#else
            .background(Color(nsColor: .windowBackgroundColor))
#endif
            .sheet(item: $selectedTopic) { topic in
                TopicDetailSheet(topic: topic)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("搜索热点话题", text: $searchText)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.clearResults()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Material.regular)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
        .padding(.horizontal, DesignSystem.Spacing.md)
        .onChange(of: searchText) { oldValue, newValue in
            // 实时搜索（debounce）
            if !newValue.isEmpty {
                Task {
                    try? await Task.sleep(for: .milliseconds(300))
                    if searchText == newValue {
                        performSearch()
                    }
                }
            }
        }
    }

    // MARK: - Platform Filter

    private var platformFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                // 全部
                platformChip(nil, title: "全部", icon: "flame.fill")

                // 各平台
                ForEach(Platform.allCases) { platform in
                    platformChip(platform, title: platform.displayName, icon: platform.iconName)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.xs)
        }
    }

    private func platformChip(_ platform: Platform?, title: String, icon: String) -> some View {
        let isSelected = selectedPlatform == platform

        return Button {
            withAnimation(DesignSystem.Animation.standard) {
                selectedPlatform = platform
                performSearch()
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: icon)
                    .font(.system(size: 12))

                Text(title)
                    .font(DesignSystem.Typography.footnote)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .foregroundStyle(isSelected ? .white : .primary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(chipBackground(platform: platform, isSelected: isSelected))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func chipBackground(platform: Platform?, isSelected: Bool) -> some View {
        if isSelected {
            if let platform = platform {
                DesignSystem.PlatformGradient.gradient(for: platform)
            } else {
                LinearGradient(
                    colors: [.accentColor, .accentColor.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        } else {
            Color.gray.opacity(0.1)
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if !isSearching {
            emptyStateView
        } else if isLoading {
            LoadingView(message: "搜索中...")
        } else if hasError {
            ErrorView(
                error: viewModel.error ?? AppError.unknown("搜索失败"),
                retryAction: {
                    performSearch()
                }
            )
        } else if viewModel.searchResults.isEmpty {
            noResultsView
        } else {
            searchResultsView
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "text.magnifyingglass")
                .font(.system(size: 80))
                .foregroundStyle(.secondary.opacity(0.3))

            Text("搜索全平台热点")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(.secondary)

            Text("输入关键词开始搜索")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }

    private var noResultsView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundStyle(.secondary.opacity(0.3))

            Text("未找到相关话题")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(.secondary)

            Text("试试其他关键词")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }

    private var searchResultsView: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                HStack {
                    Text("找到 \(viewModel.searchResults.count) 个结果")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)

                    Spacer()
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.top, DesignSystem.Spacing.sm)

                ForEach(viewModel.searchResults) { topic in
                    TrendCard(
                        topic: topic,
                        showCurve: false,
                        onTap: {
                            selectedTopic = topic
                        },
                        onFavorite: {
                            // TODO: 实现收藏功能
                        }
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
    }

    // MARK: - Actions

    private func performSearch() {
        guard !searchText.isEmpty else { return }

        Task {
            let platforms = selectedPlatform.map { [$0] }
            await viewModel.search(query: searchText, in: platforms)
        }
    }
}

#Preview {
    SearchView()
}
