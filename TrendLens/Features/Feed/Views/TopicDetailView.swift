//
//  TopicDetailView.swift
//  TrendLens
//
//  Created by Claude on 1/24/26.
//

import SwiftUI

/// 话题详情页面 - 独立导航页面
struct TopicDetailView: View {

    // MARK: - Properties

    let topic: TrendTopicEntity
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                // 标题区域
                headerSection

                Divider()

                // 热度曲线
                if !topic.heatHistory.isEmpty {
                    curveSection
                    Divider()
                }

                // 话题信息
                infoSection

                // 底部留白
                Spacer()
                    .frame(height: DesignSystem.Spacing.xxl)
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
        .navigationTitle("话题详情")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                shareButton
            }
        }
    }

    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // 排名和标题
            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                RankBadge(rank: topic.rank, platform: topic.platform)

                Text(topic.title)
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(nil) // 详情页显示完整标题
            }

            // AI 摘要
            if !topic.summary.isEmpty {
                Text(topic.summary)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil) // 详情页显示完整摘要
                    .padding(.vertical, DesignSystem.Spacing.xs)
            }

            // 描述
            if let description = topic.description, !description.isEmpty {
                Text(description)
                    .font(DesignSystem.Typography.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(nil)
            }

            // 平台、热度、排名变化徽章
            HStack(spacing: DesignSystem.Spacing.sm) {
                PlatformBadge(platform: topic.platform, style: .full)

                HeatLevelBadge(heatValue: topic.heatValue)

                RankChangeIndicator(rankChange: topic.rankChange, style: .full)
            }
            .padding(.top, DesignSystem.Spacing.xs)
        }
    }

    private var curveSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("热度趋势")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(.primary)

            HeatCurveView(
                dataPoints: topic.heatHistory,
                platform: topic.platform,
                style: .full
            )
            .frame(height: 200)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("话题信息")
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(.primary)

            infoRow(title: "当前热度", value: topic.heatValue.formattedHeat)
            infoRow(title: "当前排名", value: "#\(topic.rank)")
            infoRow(title: "数据来源", value: topic.platform.displayName)
            infoRow(title: "数据更新", value: topic.fetchedAt.formatted(date: .abbreviated, time: .shortened))

            // 标签
            if !topic.tags.isEmpty {
                tagsSection
            }

            // 链接（如果有）
            if let link = topic.link, !link.isEmpty, let url = URL(string: link) {
                linkSection(url: url)
            }
        }
    }

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("标签")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

            FlowLayout(spacing: DesignSystem.Spacing.xs) {
                ForEach(topic.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xxs)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.top, DesignSystem.Spacing.xs)
    }

    private func linkSection(url: URL) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text("原始链接")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)

            Link(destination: url) {
                HStack {
                    Image(systemName: "link")
                        .font(.system(size: 14))

                    Text("查看原文")
                        .font(DesignSystem.Typography.body)

                    Spacer()

                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 12))
                }
                .foregroundStyle(.blue)
                .padding(DesignSystem.Spacing.sm)
                .background(Color.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small, style: .continuous))
            }
        }
        .padding(.top, DesignSystem.Spacing.xs)
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

    // MARK: - Actions

    private func shareTopic() {
#if os(iOS)
        let shareText = """
        \(topic.title)

        \(topic.summary)

        来自 \(topic.platform.displayName) · 热度 \(topic.heatValue.formattedHeat)
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
}

// MARK: - FlowLayout Helper

/// 简单的流式布局（用于标签显示）
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: result.frames[index].origin, proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    // 换行
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview("Topic Detail - 微博") {
    NavigationStack {
        TopicDetailView(topic: PreviewData.sampleTopic)
    }
}

#Preview("Topic Detail - Bilibili") {
    NavigationStack {
        TopicDetailView(topic: PreviewData.sampleTopicBilibili)
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
        platform: .bilibili,
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
