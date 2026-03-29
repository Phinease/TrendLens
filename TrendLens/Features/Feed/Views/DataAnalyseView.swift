//
//  DataAnalyseView.swift
//  TrendLens
//
//  Created by Claude on 1/24/26.
//

import SwiftUI

/// 数据分析页面 - 展示话题热度数据、趋势曲线、AI 摘要等
struct DataAnalyseView: View {

    // MARK: - Properties

    let topic: TrendTopicEntity
    @Environment(\.colorScheme) private var colorScheme
    @State private var displayTopic: TrendTopicEntity
    @State private var isLoadingDetail = false
    @State private var isLoadingTrendData = false
    @State private var didAttemptDetailLoad = false
    @State private var didAttemptTrendLoad = false
    @State private var trendSeries: TopicTrendSeries?

    init(topic: TrendTopicEntity) {
        self.topic = topic
        self._displayTopic = State(initialValue: topic)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 标题区域
                headerSection

                Divider()
                .padding(.vertical, DesignSystem.Spacing.xl)

                // 热度曲线
                if let chartPoints = chartDataPoints {
                    if let trendSeries {
                        trendSourceView(series: trendSeries)
                            .padding(.bottom, DesignSystem.Spacing.md)
                    }

                    HeatCurveView(
                        dataPoints: chartPoints,
                        platform: displayTopic.platform,
                        style: .full
                    )
                    .frame(height: 300)
                    .padding(.vertical, DesignSystem.Spacing.xl)

                    Divider()
                    .padding(.vertical, DesignSystem.Spacing.xl)
                }

                if isLoadingTrendData && chartDataPoints == nil {
                    LoadingView(message: "加载 Google Trends 中...")
                        .padding(.bottom, DesignSystem.Spacing.xl)
                } else if isLoadingDetail && chartDataPoints == nil {
                    LoadingView(message: "加载热度历史中...")
                        .padding(.bottom, DesignSystem.Spacing.xl)
                }

                // 话题信息
                infoSection

                // 底部留白
                Spacer()
                .frame(height: DesignSystem.Spacing.xl)
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
        .navigationTitle("数据分析")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                shareButton
            }
        }
        .task(id: topic.id) {
            await loadTopicDetailIfNeeded()
            await loadTrendDataIfNeeded()
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // 排名和标题
            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                RankBadge(rank: displayTopic.rank, platform: displayTopic.platform)

                Text(displayTopic.title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(nil) // 详情页显示完整标题
            }

            // AI 摘要
            if !displayTopic.summary.isEmpty {
                Text(displayTopic.summary)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil) // 详情页显示完整摘要
                    .padding(.vertical, DesignSystem.Spacing.xs)
            }

            // 描述
            if let description = displayTopic.description, !description.isEmpty {
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            }

            // 平台、热度、排名变化徽章
            HStack(spacing: DesignSystem.Spacing.sm) {
                PlatformBadge(platform: displayTopic.platform, style: .full)

                HeatLevelBadge(heatValue: displayTopic.heatValue)

                RankChangeIndicator(rankChange: displayTopic.rankChange, style: .full)
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text("话题信息")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(.primary)

            infoRow(title: "当前热度", value: displayTopic.heatValue.formattedHeat)
            infoRow(title: "当前排名", value: "#\(displayTopic.rank)")
            infoRow(title: "数据来源", value: displayTopic.platform.displayName)
            infoRow(title: "数据更新", value: displayTopic.fetchedAt.formatted(date: .abbreviated, time: .shortened))
            if let trendSeries {
                infoRow(title: "趋势来源", value: "Google Trends · \(trendSeries.keyword)")
            }

            // 标签
            if !displayTopic.tags.isEmpty {
                tagsSection
            }

            // 链接（如果有）
            if let link = displayTopic.link, !link.isEmpty, let url = URL(string: link) {
                linkSection(url: url)
            }
        }
    }

    private var tagsSection: some View {
        HStack() {
            Text("标签")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer()

            ForEach(displayTopic.tags, id: \.self) { tag in
                Text("#\(tag)")
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, DesignSystem.Spacing.sm)
                    .padding(.vertical, DesignSystem.Spacing.xxs)
                    .background(Color.gray.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
    }

    private func linkSection(url: URL) -> some View {
        HStack() {
            Text("原始链接")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Link(destination: url) {
                HStack {
                    Image(systemName: "link")
                        .font(.system(size: 14))
                    Text("查看原文")
                        .font(DesignSystem.Typography.body)
                }
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small, style: .continuous))
            }
        }
    }

    private var shareButton: some View {
        Button {
            shareTopic()
        } label: {
            Image(systemName: "square.and.arrow.up")
        }
    }

    // MARK: - Helper Views

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

    private func trendSourceView(series: TopicTrendSeries) -> some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.blue)

            Text("Google Trends")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

            Text(series.keyword)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()
        }
    }

    // MARK: - Actions

    private func shareTopic() {
#if os(iOS)
        let shareText = """
        \(displayTopic.title)

        \(displayTopic.summary)

        来自 \(displayTopic.platform.displayName) · 热度 \(displayTopic.heatValue.formattedHeat)
        """

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

    private func loadTopicDetailIfNeeded() async {
        guard !didAttemptDetailLoad else { return }
        didAttemptDetailLoad = true

        guard displayTopic.heatHistory.isEmpty || displayTopic.content == nil else {
            return
        }

        isLoadingDetail = true
        defer { isLoadingDetail = false }

        let repository = await MainActor.run {
            DependencyContainer.shared.makeTrendingRepository()
        }

        guard let detailedTopic = try? await repository.getTopicDetail(topicId: topic.id) else {
            return
        }

        displayTopic = detailedTopic
    }

    private func loadTrendDataIfNeeded() async {
        guard !didAttemptTrendLoad else { return }
        didAttemptTrendLoad = true

        isLoadingTrendData = true
        defer { isLoadingTrendData = false }

        let remoteDataSource = RemoteTrendingDataSource()
        trendSeries = try? await remoteDataSource.fetchTopicTrendSeries(for: topic.id)
    }

    private var chartDataPoints: [HeatDataPoint]? {
        if let trendSeries, trendSeries.points.count >= 2 {
            return trendSeries.points
        }
        if displayTopic.heatHistory.count >= 2 {
            return displayTopic.heatHistory
        }
        return nil
    }
}

// MARK: - Preview

#Preview("Data Analyse - 微博") {
    NavigationStack {
        DataAnalyseView(topic: PreviewData.sampleTopic)
    }
}

#Preview("Data Analyse - Bilibili") {
    NavigationStack {
        DataAnalyseView(topic: PreviewData.sampleTopicBilibili)
    }
}

// MARK: - Preview Data

private struct PreviewData {
    static let sampleTopic = TrendTopicEntity(
        id: "preview-1",
        platform: .weibo,
        title: "示例热点话题标题",
        description: "这是一个示例话题的详细描述，展示话题的背景信息和相关内容。",
        heatValue: 1_500_000,
        rank: 1,
        link: "https://weibo.com/example",
        tags: ["热点", "示例", "科技"],
        fetchedAt: Date(),
        rankChange: .up(3),
        heatHistory: (0..<12).map { i in
            HeatDataPoint(
                timestamp: Date().addingTimeInterval(TimeInterval(-i * 7200)),
                heatValue: 1_500_000 + Int.random(in: -200_000...200_000),
                rank: max(1, 5 - i / 2)
            )
        },
        summary: "AI 摘要：这是一个示例话题的核心摘要，简明扼要地说明这个话题的关键信息和背景。展示详情页面的完整布局和样式。",
        isFavorite: false
    )

    static let sampleTopicBilibili = TrendTopicEntity(
        id: "preview-2",
        platform: .bilibiliHotSearch,
        title: "Bilibili 示例话题",
        description: nil,
        heatValue: 850_000,
        rank: 5,
        link: nil,
        tags: ["动画", "番剧"],
        fetchedAt: Date(),
        rankChange: .down(2),
        heatHistory: (0..<8).map { i in
            HeatDataPoint(
                timestamp: Date().addingTimeInterval(TimeInterval(-i * 3600)),
                heatValue: 850_000 - (i * 50_000),
                rank: 5 + i
            )
        },
        summary: "这是一个 Bilibili 平台的示例话题摘要。",
        isFavorite: true
    )
}
