//
//  FeedView.swift
//  TrendLens
//

import SwiftUI

/// 导航目的地类型
enum FeedNavigationDestination: Hashable {
    case topicDetail(TrendTopicEntity)
    case dataAnalyse(TrendTopicEntity)
}

/// Feed 页面 - 全平台热榜聚合
struct FeedView: View {

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var viewModel = DependencyContainer.shared.makeFeedViewModel()
    @State private var selectedPlatform: Platform? = nil
    @State private var navigationPath = NavigationPath()
    @State private var displayedTopics: [TrendTopicEntity] = []
    @State private var favoriteTrigger = false
    @State private var platformSwitchTrigger = false

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                FluidRibbon(selectedPlatform: $selectedPlatform)
                contentView
            }
            .navigationTitle("热榜")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
            .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
            .navigationDestination(for: FeedNavigationDestination.self) { destination in
                switch destination {
                case .topicDetail(let topic):
                    TopicDetailView(topic: topic)
                case .dataAnalyse(let topic):
                    DataAnalyseView(topic: topic)
                }
            }
            .task {
                if viewModel.topics.isEmpty {
                    await viewModel.fetchTopics()
                }
            }
            .onChange(of: selectedPlatform) { _, newPlatform in
                updateDisplayedTopics(platform: newPlatform)
            }
            .onChange(of: viewModel.topics) { _, _ in
                updateDisplayedTopics(platform: selectedPlatform)
            }
            .sensoryFeedback(.success, trigger: favoriteTrigger)
            .sensoryFeedback(.selection, trigger: platformSwitchTrigger)
        }
    }
}

// MARK: - Subviews

private extension FeedView {

    @ViewBuilder
    var contentView: some View {
        if viewModel.isLoading && viewModel.topics.isEmpty {
            SkeletonList(count: 6)
                .padding(.top, DesignSystem.Spacing.sm)
        } else if let error = viewModel.error {
            ErrorView(
                error: error,
                retryAction: { Task { await viewModel.fetchTopics(forceRefresh: true) } }
            )
        } else if displayedTopics.isEmpty {
            EmptyStateView(
                state: selectedPlatform.map { .noPlatformData(platform: $0) } ?? .noTrends
            ) { Task { await viewModel.fetchTopics(forceRefresh: true) } }
        } else {
            topicList
        }
    }

    var topicList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(displayedTopics) { topic in
                    let isHero = topic.rank <= 3
                    let spacing = isHero ? DesignSystem.Spacing.md : DesignSystem.Spacing.sm

                    Button {
                        navigationPath.append(FeedNavigationDestination.topicDetail(topic))
                    } label: {
                        if isHero {
                            HeroCard(
                                topic: topic,
                                rank: topic.rank,
                                onDetailTap: { navigationPath.append(FeedNavigationDestination.topicDetail(topic)) },
                                onDataTap: { navigationPath.append(FeedNavigationDestination.dataAnalyse(topic)) }
                            )
                        } else {
                            StandardCard(
                                topic: topic,
                                rank: topic.rank,
                                onDetailTap: { navigationPath.append(FeedNavigationDestination.topicDetail(topic)) },
                                onDataTap: { navigationPath.append(FeedNavigationDestination.dataAnalyse(topic)) }
                            )
                        }
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            toggleFavorite(topic)
                        } label: {
                            Label(
                                topic.isFavorite ? "取消收藏" : "收藏",
                                systemImage: topic.isFavorite ? "star.slash" : "star.fill"
                            )
                        }

                        Button("复制标题", systemImage: "doc.on.doc") {
                            copyTitle(topic.title)
                        }

                        ShareLink(
                            item: "\(topic.title)\n\n来自 \(topic.platform.displayName) · 热度 \(topic.heatValue.formattedHeat)"
                        )

                        Divider()

                        Button(role: .destructive) {
                            blockTopic(topic)
                        } label: {
                            Label("屏蔽", systemImage: "eye.slash")
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, spacing / 2)
                }

                Spacer()
                    .frame(height: 80)
            }
        }
        .refreshable {
            await viewModel.fetchTopics(forceRefresh: true)
        }
    }
}

// MARK: - Actions

private extension FeedView {

    func updateDisplayedTopics(platform: Platform?) {
        if let platform {
            displayedTopics = viewModel.topics.filter { $0.platform == platform }
        } else {
            displayedTopics = viewModel.topics
        }
    }

    func toggleFavorite(_ topic: TrendTopicEntity) {
        Task {
            await viewModel.toggleFavorite(topicId: topic.id)
            await viewModel.fetchTopics()
        }
        favoriteTrigger.toggle()
    }

    func blockTopic(_ topic: TrendTopicEntity) {
        Task {
            // TODO: 实现屏蔽功能
            await viewModel.fetchTopics()
        }
    }

    func copyTitle(_ title: String) {
        #if os(iOS)
        UIPasteboard.general.string = title
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(title, forType: .string)
        #endif
    }
}

// MARK: - Preview

#Preview("Feed View") {
    FeedView()
}
