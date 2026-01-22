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

    @State private var selectedPlatform: Platform? = nil
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    @State private var selectedTopic: TrendTopicEntity? = nil

    // MARK: - Computed Properties

    private var displayedTopics: [TrendTopicEntity] {
        if let platform = selectedPlatform {
            return MockData.topicsForPlatform(platform)
        }
        return MockData.allTopics
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 平台选择器
                platformSelector
                    .padding(.top, DesignSystem.Spacing.xs)

                // 内容区域
                contentView
            }
            .navigationTitle("热榜")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .background(Color(uiColor: .systemGroupedBackground))
#else
            .background(Color(nsColor: .windowBackgroundColor))
#endif
            .refreshable {
                await simulateRefresh()
            }
            .sheet(item: $selectedTopic) { topic in
                TopicDetailSheet(topic: topic)
            }
        }
    }

    // MARK: - Platform Selector

    private var platformSelector: some View {
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
        if isLoading {
            SkeletonList(count: 6)
                .padding(.top, DesignSystem.Spacing.sm)
        } else if displayedTopics.isEmpty {
            EmptyStateView(
                state: selectedPlatform.map { .noPlatformData(platform: $0) } ?? .noTrends
            ) {
                Task { await simulateRefresh() }
            }
        } else {
            topicList
        }
    }

    private var topicList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(displayedTopics) { topic in
                    TrendCard(
                        topic: topic,
                        showCurve: true,
                        onTap: {
                            selectedTopic = topic
                        },
                        onFavorite: {
                            toggleFavorite(topic)
                        }
                    )
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
    }

    // MARK: - Actions

    private func simulateRefresh() async {
        isLoading = true
        // 模拟网络延迟
        try? await Task.sleep(for: .seconds(1))
        isLoading = false
    }

    private func toggleFavorite(_ topic: TrendTopicEntity) {
        // 阶段 0.5：暂不实现实际的收藏逻辑
        // 阶段 1 将使用 SwiftData 实现
        print("Toggle favorite for: \(topic.title)")
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
    FeedView()
}

#Preview("Topic Detail") {
    TopicDetailSheet(topic: MockData.sampleTopic)
}
