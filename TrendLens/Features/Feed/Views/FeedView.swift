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
    @Environment(\.colorScheme) private var colorScheme

    // 滑动手势相关
    @State private var dragOffset: CGFloat = 0

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

                    NavigationLink(destination: TopicDetailView(topic: topic)) {
                        Group {
                            if isHeroCard {
                                HeroCard(topic: topic, rank: topic.rank)
                            } else {
                                StandardCard(topic: topic, rank: topic.rank)
                            }
                        }
                    }
                    .buttonStyle(.plain) // 保持卡片原始样式
                    .contextMenu {
                        // 收藏/取消收藏
                        Button {
                            toggleFavorite(topic)
                        } label: {
                            if topic.isFavorite {
                                Label("取消收藏", systemImage: "star.slash")
                            } else {
                                Label("收藏", systemImage: "star.fill")
                            }
                        }

                        // 复制标题
                        Button {
                            copyTitle(topic.title)
                        } label: {
                            Label("复制标题", systemImage: "doc.on.doc")
                        }

                        // 分享
                        Button {
                            shareTopic(topic)
                        } label: {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        // 屏蔽
                        Button(role: .destructive) {
                            blockTopic(topic)
                        } label: {
                            Label("屏蔽", systemImage: "eye.slash")
                        }
                    }
#if os(iOS)
                    // iPhone 滑动操作（仅在 compact 尺寸下启用）
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            blockTopic(topic)
                        } label: {
                            Label("屏蔽", systemImage: "eye.slash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            toggleFavorite(topic)
                        } label: {
                            Label(topic.isFavorite ? "取消收藏" : "收藏", systemImage: topic.isFavorite ? "star.slash" : "star.fill")
                        }
                        .tint(.blue)
                    }
#endif
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, spacing / 2)
                }

                // 底部留白
                Spacer()
                    .frame(height: 80)
            }
        }
        .simultaneousGesture(
            // 横向滑动切换平台（仅在明显横向滑动时触发）
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    // 只在横向滑动时记录偏移
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)

                    // 横向滑动占主导时才记录偏移
                    if horizontal > vertical * 1.5 {
                        dragOffset = value.translation.width
                    }
                }
                .onEnded { value in
                    let horizontal = abs(value.translation.width)
                    let vertical = abs(value.translation.height)
                    let threshold: CGFloat = 80 // 切换阈值

                    // 只有在明显横向滑动时才切换平台
                    if horizontal > vertical * 1.5 && horizontal > threshold {
                        if value.translation.width < 0 {
                            // 左滑 - 切换到下一个平台
                            switchToNextPlatform()
                        } else {
                            // 右滑 - 切换到上一个平台
                            switchToPreviousPlatform()
                        }
                    }

                    // 重置偏移
                    dragOffset = 0
                }
        )
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

        // 触觉反馈
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    private func blockTopic(_ topic: TrendTopicEntity) {
        Task {
            // TODO: 实现屏蔽功能 - 添加关键词到屏蔽列表
            // 临时显示提示
            print("屏蔽话题: \(topic.title)")

            // 刷新数据
            await viewModel.fetchTopics()
        }

        // 触觉反馈
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
        #endif
    }

    private func copyTitle(_ title: String) {
        #if os(iOS)
        UIPasteboard.general.string = title
        #elseif os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(title, forType: .string)
        #endif

        // 触觉反馈
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }

    private func shareTopic(_ topic: TrendTopicEntity) {
        #if os(iOS)
        let shareText = "\(topic.title)\n\n来自 \(topic.platform.displayName) · 热度 \(topic.heatValue.formattedHeat)"
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        // 获取当前窗口场景
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
        #endif
    }

    /// 切换到下一个平台
    private func switchToNextPlatform() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if selectedPlatform == nil {
                // 从"全部"切换到第一个平台
                selectedPlatform = Platform.allCases.first
            } else if let current = selectedPlatform,
                      let currentIndex = Platform.allCases.firstIndex(of: current),
                      currentIndex < Platform.allCases.count - 1 {
                // 切换到下一个平台
                selectedPlatform = Platform.allCases[currentIndex + 1]
            }
        }

        // 触觉反馈
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }

    /// 切换到上一个平台
    private func switchToPreviousPlatform() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            if selectedPlatform == nil {
                // 从"全部"无法向前切换
                return
            } else if let current = selectedPlatform,
                      let currentIndex = Platform.allCases.firstIndex(of: current) {
                if currentIndex > 0 {
                    // 切换到上一个平台
                    selectedPlatform = Platform.allCases[currentIndex - 1]
                } else {
                    // 切换回"全部"
                    selectedPlatform = nil
                }
            }
        }

        // 触觉反馈
        #if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
    }
}

// MARK: - Preview

#Preview("Feed View") {
    FeedViewPreview()
}

// Preview 专用视图，使用 Mock 数据
private struct FeedViewPreview: View {
    @State private var selectedPlatform: Platform? = nil
    @Environment(\.colorScheme) private var colorScheme

    // Preview 辅助函数
    private func toggleFavorite(_ topic: TrendTopicEntity) {
        print("Toggle favorite: \(topic.title)")
    }

    private func blockTopic(_ topic: TrendTopicEntity) {
        print("Block topic: \(topic.title)")
    }

    private func copyTitle(_ title: String) {
        #if os(iOS)
        UIPasteboard.general.string = title
        #endif
    }

    private func shareTopic(_ topic: TrendTopicEntity) {
        print("Share topic: \(topic.title)")
    }

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
                    summary: "AI 摘要: \(platform.displayName) 的热点话题摘要。这是一段随机文字，用于展示话题详情页面的布局和样式。你可以根据需要调整这段文字的长度和内容。",
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
        }
    }

    private var topicList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(displayedTopics.enumerated()), id: \.element.id) { index, topic in
                    let isHeroCard = topic.rank <= 3
                    let spacing = isHeroCard ? DesignSystem.Spacing.md : DesignSystem.Spacing.sm

                    NavigationLink(destination: TopicDetailView(topic: topic)) {
                        Group {
                            if isHeroCard {
                                HeroCard(topic: topic, rank: topic.rank)
                            } else {
                                StandardCard(topic: topic, rank: topic.rank)
                            }
                        }
                    }
                    .buttonStyle(.plain) // 保持卡片原始样式
                    .contextMenu {
                        Divider()

                        // 收藏/取消收藏
                        Button {
                            toggleFavorite(topic)
                        } label: {
                            if topic.isFavorite {
                                Label("取消收藏", systemImage: "star.slash")
                            } else {
                                Label("收藏", systemImage: "star.fill")
                            }
                        }

                        // 复制标题
                        Button {
                            copyTitle(topic.title)
                        } label: {
                            Label("复制标题", systemImage: "doc.on.doc")
                        }

                        // 分享
                        Button {
                            shareTopic(topic)
                        } label: {
                            Label("分享", systemImage: "square.and.arrow.up")
                        }

                        Divider()

                        // 屏蔽
                        Button(role: .destructive) {
                            blockTopic(topic)
                        } label: {
                            Label("屏蔽", systemImage: "eye.slash")
                        }
                    }
#if os(iOS)
                    // iPhone 滑动操作（仅在 compact 尺寸下启用）
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            blockTopic(topic)
                        } label: {
                            Label("屏蔽", systemImage: "eye.slash")
                        }
                    }
                    .swipeActions(edge: .leading, allowsFullSwipe: false) {
                        Button {
                            toggleFavorite(topic)
                        } label: {
                            Label(topic.isFavorite ? "取消收藏" : "收藏", systemImage: topic.isFavorite ? "star.slash" : "star.fill")
                        }
                        .tint(.blue)
                    }
#endif
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
