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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

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
#endif
            .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
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
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                if isSelected {
                    selectedPlatforms.remove(platform)
                } else {
                    selectedPlatforms.insert(platform)
                }
            }

            // 触觉反馈
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
        } label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                // 平台图标
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(platform.hintColor)
                        .frame(width: 16, height: 16)

                    Image(systemName: platform.iconName)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(.white)
                }

                Text(platform.displayName)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.green)
                }
            }
            .foregroundStyle(isSelected ? .primary : .secondary)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .background(isSelected ? DesignSystem.Neutral.containerHover(colorScheme) : DesignSystem.Neutral.container(colorScheme))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? platform.hintColor.opacity(0.3) : .clear, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .cardShadow()
        }
        .buttonStyle(.plain)
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
            if shouldUseGridLayout {
                // iPad: 2列卡片布局
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                    ],
                    spacing: DesignSystem.Spacing.lg
                ) {
                    // 交集话题卡片
                    ForEach(Array(viewModel.intersectionTopics.enumerated()), id: \.element.id) { index, topic in
                        NavigationLink(destination: TopicDetailView(topic: topic)) {
                            StandardCard(topic: topic, rank: index + 1)
                        }
                        .buttonStyle(.plain)
                    }

                    // 平台独有话题卡片
                    ForEach(Array(viewModel.uniqueTopics.keys.sorted(by: { $0.displayName < $1.displayName })), id: \.self) { platform in
                        if let topics = viewModel.uniqueTopics[platform], !topics.isEmpty {
                            ForEach(Array(topics.prefix(5).enumerated()), id: \.element.id) { index, topic in
                                NavigationLink(destination: TopicDetailView(topic: topic)) {
                                    StandardCard(topic: topic, rank: topic.rank)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
            } else {
                // iPhone: 单列布局
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
    }

    private var shouldUseGridLayout: Bool {
        horizontalSizeClass == .regular
    }

    private var intersectionSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // 标题
            HStack {
                Image(systemName: "circle.grid.cross.fill")
                    .foregroundStyle(DesignSystem.SemanticColor.info(colorScheme))

                Text("共同热点")
                    .font(DesignSystem.Typography.headline)

                Spacer()

                Text("\(viewModel.intersectionTopics.count) 个")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)

            // 卡片列表
            ForEach(Array(viewModel.intersectionTopics.enumerated()), id: \.element.id) { index, topic in
                NavigationLink(destination: TopicDetailView(topic: topic)) {
                    StandardCard(topic: topic, rank: index + 1)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .fill(DesignSystem.SemanticColor.info(colorScheme).opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .strokeBorder(DesignSystem.SemanticColor.info(colorScheme).opacity(0.1), lineWidth: 1)
        )
    }

    private var uniqueTopicsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // 标题
            HStack {
                Image(systemName: "sparkles")
                    .foregroundStyle(DesignSystem.SemanticColor.warning(colorScheme))

                Text("平台独有")
                    .font(DesignSystem.Typography.headline)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)

            // 各平台独有话题
            ForEach(Array(viewModel.uniqueTopics.keys.sorted(by: { $0.displayName < $1.displayName })), id: \.self) { platform in
                if let topics = viewModel.uniqueTopics[platform], !topics.isEmpty {
                    platformUniqueSection(platform: platform, topics: topics)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .fill(DesignSystem.SemanticColor.warning(colorScheme).opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                .strokeBorder(DesignSystem.SemanticColor.warning(colorScheme).opacity(0.1), lineWidth: 1)
        )
    }

    private func platformUniqueSection(platform: Platform, topics: [TrendTopicEntity]) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // 平台标题
            HStack(spacing: DesignSystem.Spacing.xs) {
                // 平台图标
                ZStack {
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(platform.hintColor)
                        .frame(width: 20, height: 20)

                    Image(systemName: platform.iconName)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                }

                Text(platform.displayName)
                    .font(.system(size: 16, weight: .semibold))

                Text("·")
                    .foregroundStyle(.secondary)

                Text("\(topics.count) 个独有话题")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }

            // 话题卡片
            ForEach(Array(topics.prefix(5).enumerated()), id: \.element.id) { index, topic in
                NavigationLink(destination: TopicDetailView(topic: topic)) {
                    StandardCard(topic: topic, rank: topic.rank)
                }
                .buttonStyle(.plain)
            }

            // 更多提示
            if topics.count > 5 {
                Text("还有 \(topics.count - 5) 个话题...")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, DesignSystem.Spacing.xxs)
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

