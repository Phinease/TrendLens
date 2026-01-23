//
//  FeedView.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// Feed 页面 - 全平台热榜聚合
struct FeedView: View {

    // MARK: - State

    @State private var viewModel = DependencyContainer.shared.makeFeedViewModel()
    @State private var selectedPlatform: Platform? = nil
    @State private var selectedTopic: TrendTopicEntity? = nil
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Computed Properties

    private var displayedTopics: [TrendTopicEntity] {
        if let platform = selectedPlatform {
            return viewModel.topics.filter { $0.platform == platform }
        }
        return viewModel.topics
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
                // FluidRibbon 平台选择器
                FluidRibbon(selectedPlatform: $selectedPlatform)

                // 内容区域
                contentView
            }
            .navigationTitle("热榜")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
            .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
            .refreshable {
                await refreshData()
            }
            .sheet(item: $selectedTopic) { topic in
                TopicDetailSheet(topic: topic)
            }
            .task {
                // 页面加载时获取数据
                if viewModel.topics.isEmpty {
                    await viewModel.fetchTopics()
                }
            }
        }
    }


    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if isLoading {
            SkeletonList(count: 6)
                .padding(.top, DesignSystem.Spacing.sm)
        } else if hasError {
            ErrorView(
                error: viewModel.error ?? AppError.unknown("加载失败"),
                retryAction: {
                    Task { await viewModel.fetchTopics(forceRefresh: true) }
                }
            )
        } else if displayedTopics.isEmpty {
            EmptyStateView(
                state: selectedPlatform.map { .noPlatformData(platform: $0) } ?? .noTrends
            ) {
                Task { await viewModel.fetchTopics(forceRefresh: true) }
            }
        } else {
            topicList
        }
    }

    private var topicList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(displayedTopics.enumerated()), id: \.element.id) { index, topic in
                    let isHeroCard = topic.rank <= 3
                    let spacing = isHeroCard ? DesignSystem.Spacing.md : DesignSystem.Spacing.sm

                    Group {
                        if isHeroCard {
                            HeroCard(topic: topic, rank: topic.rank)
                                .onTapGesture {
                                    selectedTopic = topic
                                }
                        } else {
                            StandardCard(topic: topic, rank: topic.rank)
                                .onTapGesture {
                                    selectedTopic = topic
                                }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, spacing / 2)
                }

                // 底部留白，为后续 FloatingDock 预留空间
                Spacer()
                    .frame(height: 80)
            }
        }
    }

    // MARK: - Actions

    private func refreshData() async {
        // 刷新所有平台数据
        await DependencyContainer.shared.refreshAllData()
        // 重新获取数据
        await viewModel.fetchTopics(forceRefresh: true)
    }

    private func toggleFavorite(_ topic: TrendTopicEntity) {
        Task {
            await viewModel.toggleFavorite(topicId: topic.id)
            // 刷新数据以更新收藏状态
            await viewModel.fetchTopics()
        }
    }
}

// MARK: - Topic Detail Sheet

/// 话题详情底部弹出框
struct TopicDetailSheet: View {

    let topic: TrendTopicEntity
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // 标题区域
                    headerSection

                    Divider()

                    // 热度曲线
                    if !topic.heatHistory.isEmpty {
                        curveSection
                    }

                    Divider()

                    // 话题信息
                    infoSection
                }
                .padding(DesignSystem.Spacing.md)
            }
            .navigationTitle("话题详情")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        // 分享功能
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
#if os(iOS)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
#endif
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                RankBadge(rank: topic.rank, platform: topic.platform)

                Text(topic.title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(.primary)
            }

            if let description = topic.description {
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: DesignSystem.Spacing.md) {
                PlatformBadge(platform: topic.platform, style: .full)

                HeatLevelBadge(heatValue: topic.heatValue)

                RankChangeIndicator(rankChange: topic.rankChange, style: .full)
            }
        }
    }

    private var curveSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HeatCurveView(
                dataPoints: topic.heatHistory,
                platform: topic.platform,
                style: .full
            )
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("话题信息")
                .font(DesignSystem.Typography.headline)

            infoRow(title: "当前热度", value: topic.heatValue.formattedHeat)
            infoRow(title: "当前排名", value: "#\(topic.rank)")
            infoRow(title: "数据更新", value: topic.fetchedAt.formatted(date: .abbreviated, time: .shortened))

            if !topic.tags.isEmpty {
                HStack {
                    Text("标签")
                        .font(DesignSystem.Typography.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    ForEach(topic.tags, id: \.self) { tag in
                        Text("#\(tag)")
                            .font(DesignSystem.Typography.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, DesignSystem.Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value)
                .font(DesignSystem.Typography.mono)
                .foregroundStyle(.primary)
        }
    }
}

// MARK: - Preview

#Preview("Feed View") {
    FeedViewPreview()
}

// Preview 专用视图，使用 Mock 数据
private struct FeedViewPreview: View {
    @State private var selectedPlatform: Platform? = nil
    @State private var selectedTopic: TrendTopicEntity? = nil
    @Environment(\.colorScheme) private var colorScheme

    private let mockTopics: [TrendTopicEntity] = {
        let platforms = Platform.allCases
        return platforms.enumerated().flatMap { platformIndex, platform in
            (1...10).map { rankIndex in
                TrendTopicEntity(
                    id: "\(platform.rawValue)-\(rankIndex)",
                    platform: platform,
                    title: "\(platform.displayName) 热点话题 #\(rankIndex)",
                    description: "这是一个示例话题描述",
                    heatValue: 1_000_000 - (rankIndex * 50_000),
                    rank: rankIndex,
                    link: nil,
                    tags: ["热点", "示例"],
                    fetchedAt: Date(),
                    rankChange: rankIndex % 3 == 0 ? .up(Int.random(in: 1...5)) : (rankIndex % 3 == 1 ? .down(Int.random(in: 1...3)) : .unchanged),
                    heatHistory: (0..<8).map { i in
                        HeatDataPoint(
                            timestamp: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                            heatValue: 1_000_000 - (rankIndex * 50_000) + Int.random(in: -50_000...50_000),
                            rank: rankIndex
                        )
                    },
                    summary: "AI 摘要: \(platform.displayName) 的热点话题摘要",
                    isFavorite: false
                )
            }
        }
    }()

    private var displayedTopics: [TrendTopicEntity] {
        if let platform = selectedPlatform {
            return mockTopics.filter { $0.platform == platform }
        }
        return mockTopics
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // FluidRibbon 平台选择器
                FluidRibbon(selectedPlatform: $selectedPlatform)

                // 内容区域
                topicList
            }
            .navigationTitle("热榜")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
            .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
            .sheet(item: $selectedTopic) { topic in
                TopicDetailSheet(topic: topic)
            }
        }
    }

    private var topicList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(displayedTopics.enumerated()), id: \.element.id) { index, topic in
                    let isHeroCard = topic.rank <= 3
                    let spacing = isHeroCard ? DesignSystem.Spacing.md : DesignSystem.Spacing.sm

                    Group {
                        if isHeroCard {
                            HeroCard(topic: topic, rank: topic.rank)
                                .onTapGesture {
                                    selectedTopic = topic
                                }
                        } else {
                            StandardCard(topic: topic, rank: topic.rank)
                                .onTapGesture {
                                    selectedTopic = topic
                                }
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, spacing / 2)
                }

                // 底部留白
                Spacer()
                    .frame(height: 80)
            }
        }
    }
}

#Preview("Topic Detail") {
    let sampleTopic = TrendTopicEntity(
        id: "preview-1",
        platform: .weibo,
        title: "示例热点话题标题",
        description: "这是一个示例话题的详细描述",
        heatValue: 1_500_000,
        rank: 1,
        link: nil,
        tags: ["热点", "示例"],
        fetchedAt: Date(),
        rankChange: .up(3),
        heatHistory: (0..<8).map { i in
            HeatDataPoint(
                timestamp: Date().addingTimeInterval(TimeInterval(-i * 7200)),
                heatValue: 1_500_000 + Int.random(in: -100_000...100_000),
                rank: max(1, 5 - i / 2)
            )
        },
        summary: "这是一个示例话题的 AI 摘要，用于展示话题详情页面的布局和样式。",
        isFavorite: false
    )

    TopicDetailSheet(topic: sampleTopic)
}
