//
//  StandardCard.swift
//  TrendLens
//
//  Created by Claude on 1/23/26.
//

import SwiftUI

/// 标准热榜卡片
/// 显示话题排名、标题、AI 摘要、热度指标和趋势线
struct StandardCard: View {

    // MARK: - Properties

    let topic: TrendTopicEntity
    let rank: Int
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(topic: TrendTopicEntity, rank: Int) {
        self.topic = topic
        self.rank = rank
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 第一行：排名 | 标题 | 热度图标
            firstRowView

            // 第二行：AI 摘要（可选）
            if let summary = topic.summary {
                summaryRowView(summary)
            }

            // 第三行：平台信息 · 时间 · 热度值 · 排名变化 | MiniTrendLine
            thirdRowView
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Neutral.container(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
        .cardShadow()
    }

    // MARK: - Row Views

    private var firstRowView: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            // 排名徽章 - 20pt
            Text("\(rank)")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .frame(width: 28, alignment: .center)

            // 标题 - 17pt Semibold
            VStack(alignment: .leading, spacing: 0) {
                Text(topic.title)
                    .font(.system(size: 17, weight: .semibold, design: .default))
                    .lineLimit(2)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 热度图标
            Image(systemName: "flame.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(DesignSystem.HeatSpectrum.color(for: topic.heatValue))
        }
        .padding(.bottom, DesignSystem.Spacing.sm)
    }

    private func summaryRowView(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(summary)
                .font(.system(size: 15, weight: .regular, design: .default))
                .lineLimit(2)
                .foregroundStyle(.secondary)
                .padding(.leading, 44) // 缩进对齐标题
        }
        .padding(.bottom, DesignSystem.Spacing.sm)
    }

    private var thirdRowView: some View {
        HStack(alignment: .center, spacing: DesignSystem.Spacing.sm) {
            // 左侧：平台图标 · 时间 · 热度值 · 排名变化
            leftMetricsView

            Spacer()

            // 右侧：MiniTrendLine (32×24)
            if !topic.heatHistory.isEmpty {
                MiniTrendLine(
                    dataPoints: topic.heatHistory,
                    size: .standard
                )
                .frame(width: 32, height: 24)
            }
        }
    }

    @ViewBuilder
    private var leftMetricsView: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // 平台图标
            PlatformIcon(platform: topic.platform)

            // 分隔符
            Text("·")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)

            // 时间戳
            Text(formatTime(topic.fetchedAt))
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundStyle(.secondary)

            // 分隔符
            Text("·")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)

            // 热度值
            Text(topic.heatValue.formattedHeat)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(DesignSystem.HeatSpectrum.color(for: topic.heatValue))

            // 排名变化指示器
            RankChangeIndicator(rankChange: topic.rankChange, style: .compact)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Helpers

    private func formatTime(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents(
            [.minute, .hour, .day],
            from: date,
            to: now
        )

        if let hour = components.hour, hour > 0 {
            return "\(hour)h"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)m"
        } else if let day = components.day, day > 0 {
            return "\(day)d"
        } else {
            return "now"
        }
    }
}

// MARK: - Preview

#Preview("StandardCard Showcase") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 不同平台
            ForEach(Array(Platform.allCases.enumerated()), id: \.element) { index, platform in
                let topic = TrendTopicEntity(
                    id: "\(platform.rawValue)-\(index)",
                    platform: platform,
                    title: "这是一个热门话题\(index + 1)",
                    description: "相关话题描述",
                    heatValue: [300_000, 600_000, 1_200_000].randomElement() ?? 500_000,
                    rank: index + 1,
                    link: nil,
                    tags: ["热点", "讨论"],
                    fetchedAt: Date().addingTimeInterval(TimeInterval(-Int.random(in: 0...3600))),
                    rankChange: [.new, .up(5), .down(3), .unchanged].randomElement() ?? .unchanged,
                    heatHistory: generatePreviewHeatHistory(),
                    summary: Bool.random()
                        ? "这是一个 AI 生成的话题摘要。该话题在平台上引起广泛讨论，用户参与度高。"
                        : nil,
                    isFavorite: false
                )

                StandardCard(topic: topic, rank: index + 1)
            }
        }
        .padding(DesignSystem.Spacing.md)
    }
}

// MARK: - Preview Helper

private func generatePreviewHeatHistory() -> [HeatDataPoint] {
    let now = Date()
    let baseHeat = Int.random(in: 200_000...1_200_000)

    return (0..<12).map { i in
        let hoursAgo = (12 - 1 - i) * 1
        let timestamp = now.addingTimeInterval(TimeInterval(-hoursAgo * 3600))

        let variation = Int.random(in: -baseHeat/10...baseHeat/10)
        let trendOffset = i * (baseHeat / 12 / 3)

        let heatValue = max(1000, baseHeat + variation + trendOffset)

        return HeatDataPoint(
            timestamp: timestamp,
            heatValue: heatValue,
            rank: max(1, 12 - i / 2)
        )
    }
}
