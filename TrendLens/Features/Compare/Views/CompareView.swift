//
//  CompareView.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// Compare 页面 - 平台对比分析
struct CompareView: View {

    // MARK: - State

    @State private var viewModel = DependencyContainer.shared.makeCompareViewModel()
    @State private var selectedPlatforms: Set<Platform> = []
    @State private var selectedTopic: TrendTopicEntity? = nil

    // MARK: - Computed Properties

    private var canCompare: Bool {
        selectedPlatforms.count >= 2
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
                // 平台选择器
                platformSelector
                    .padding(.top, DesignSystem.Spacing.sm)

                // 内容区域
                contentView
            }
            .navigationTitle("对比")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            .background(Color(uiColor: .systemGroupedBackground))
#else
            .background(Color(nsColor: .windowBackgroundColor))
#endif
            .sheet(item: $selectedTopic) { topic in
                TopicDetailSheet(topic: topic)
            }
            .task {
                // 页面加载时获取数据
                if viewModel.intersectionTopics.isEmpty && viewModel.uniqueTopics.isEmpty {
                    await performComparison()
                }
            }
        }
    }

    // MARK: - Platform Selector

    private var platformSelector: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("选择平台（至少2个）")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DesignSystem.Spacing.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(Platform.allCases) { platform in
                        platformChip(platform)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.xs)
            }

            if canCompare {
                Button {
                    Task { await performComparison() }
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.xaxis")
                        Text("开始对比")
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
        }
    }

    private func platformChip(_ platform: Platform) -> some View {
        let isSelected = selectedPlatforms.contains(platform)

        return Button {
            withAnimation(DesignSystem.Animation.standard) {
                if isSelected {
                    selectedPlatforms.remove(platform)
                } else {
                    selectedPlatforms.insert(platform)
                }
            }
        } label: {
            HStack(spacing: DesignSystem.Spacing.xxs) {
                Image(systemName: platform.iconName)
                    .font(.system(size: 12))

                Text(platform.displayName)
                    .font(DesignSystem.Typography.footnote)
                    .fontWeight(isSelected ? .semibold : .regular)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12))
                }
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
    private func chipBackground(platform: Platform, isSelected: Bool) -> some View {
        if isSelected {
            DesignSystem.PlatformGradient.gradient(for: platform)
        } else {
            Color.gray.opacity(0.1)
        }
    }

    // MARK: - Content View

    @ViewBuilder
    private var contentView: some View {
        if !canCompare {
            emptyStateView
        } else if isLoading {
            LoadingView(message: "正在对比分析...")
        } else if hasError {
            ErrorView(
                error: viewModel.error ?? AppError.unknown("对比失败"),
                retryAction: {
                    Task { await performComparison() }
                }
            )
        } else if viewModel.intersectionTopics.isEmpty && viewModel.uniqueTopics.isEmpty {
            emptyResultView
        } else {
            comparisonResultView
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 80))
                .foregroundStyle(.secondary.opacity(0.3))

            Text("选择至少2个平台")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(.secondary)

            Text("发现不同平台的热点差异")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }

    private var emptyResultView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            Spacer()

            Image(systemName: "magnifyingglass")
                .font(.system(size: 80))
                .foregroundStyle(.secondary.opacity(0.3))

            Text("未找到相似话题")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(.secondary)

            Text("所选平台的热点话题差异较大")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }

    private var comparisonResultView: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.lg) {
                // 交集话题
                if !viewModel.intersectionTopics.isEmpty {
                    intersectionSection
                }

                // 平台独有话题
                if !viewModel.uniqueTopics.isEmpty {
                    uniqueTopicsSection
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
        }
    }

    private var intersectionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Image(systemName: "circle.grid.cross.fill")
                    .foregroundStyle(.blue)

                Text("共同热点")
                    .font(DesignSystem.Typography.headline)

                Spacer()

                Text("\(viewModel.intersectionTopics.count) 个")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)

            ForEach(viewModel.intersectionTopics) { topic in
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
    }

    private var uniqueTopicsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(.orange)

                Text("平台独有")
                    .font(DesignSystem.Typography.headline)
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)

            ForEach(Array(viewModel.uniqueTopics.keys.sorted(by: { $0.displayName < $1.displayName })), id: \.self) { platform in
                if let topics = viewModel.uniqueTopics[platform], !topics.isEmpty {
                    platformUniqueSection(platform: platform, topics: topics)
                }
            }
        }
    }

    private func platformUniqueSection(platform: Platform, topics: [TrendTopicEntity]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                PlatformBadge(platform: platform, style: .compact)

                Text("\(topics.count) 个独有话题")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignSystem.Spacing.xs)

            ForEach(topics.prefix(5)) { topic in
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

            if topics.count > 5 {
                Text("还有 \(topics.count - 5) 个话题...")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, DesignSystem.Spacing.xs)
            }
        }
    }

    // MARK: - Actions

    private func performComparison() async {
        guard canCompare else { return }

        let platforms = Array(selectedPlatforms)
        await viewModel.comparePlatforms(platforms)
    }
}

#Preview {
    CompareView()
}

