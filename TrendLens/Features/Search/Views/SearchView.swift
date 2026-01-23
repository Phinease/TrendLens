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
    @FocusState private var isSearchFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme

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
#endif
            .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
            .sheet(item: $selectedTopic) { topic in
                TopicDetailSheet(topic: topic)
            }
        }
    }

    // MARK: - Search Bar

    private var searchBar: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(isSearchFieldFocused ? .primary : .secondary)

            TextField("搜索热点话题", text: $searchText)
                .textFieldStyle(.plain)
                .submitLabel(.search)
                .onSubmit {
                    performSearch()
                }
                .focused($isSearchFieldFocused)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    viewModel.clearResults()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(DesignSystem.Neutral.container(colorScheme))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    isSearchFieldFocused
                        ? LinearGradient(
                            colors: [
                                DesignSystem.HeatSpectrum.cool.opacity(0.5),
                                DesignSystem.HeatSpectrum.warm.opacity(0.5)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [DesignSystem.Neutral.borderSubtle(colorScheme)],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                    lineWidth: isSearchFieldFocused ? 2 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .cardShadow()
        .padding(.horizontal, DesignSystem.Spacing.md)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSearchFieldFocused)
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
        FluidRibbon(selectedPlatform: $selectedPlatform)
            .onChange(of: selectedPlatform) { _, _ in
                performSearch()
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
        EmptyStateView(
            state: .custom(
                icon: "text.magnifyingglass",
                title: "搜索全平台热点",
                description: "输入关键词开始搜索",
                buttonTitle: nil
            )
        )
    }

    private var noResultsView: some View {
        EmptyStateView(
            state: .noSearchResults(query: searchText),
            action: {
                searchText = ""
                viewModel.clearResults()
            }
        )
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

                ForEach(Array(viewModel.searchResults.enumerated()), id: \.element.id) { index, topic in
                    StandardCard(topic: topic, rank: topic.rank)
                        .onTapGesture {
                            selectedTopic = topic
                        }
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
