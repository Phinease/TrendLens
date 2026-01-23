//
//  HeroCard.swift
//  TrendLens
//
//  Created by Claude on 1/23/26.
//

import SwiftUI

/// 焦点热榜卡片
/// 显示 Rank 1-3 的热榜话题，包含 AI 摘要和热度趋势线
struct HeroCard: View {

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
        ZStack {
            // 背景：热度渐变氛围
            heroBackground

            // 内容：VStack
            VStack(alignment: .leading, spacing: 16) {
                // 顶部行：排名水印 + 热度图标
                topRowView

                // 标题
                titleView

                // AI 摘要
                if let summary = topic.summary {
                    summaryView(summary)
                }

                Spacer()

                // 底部行：趋势线 + 热度值 + 排名变化
                bottomRowView

                // 元信息：平台 · 时间
                metaView
            }
            .padding(DesignSystem.Spacing.lg)
        }
        .frame(minHeight: 240)
        .background(DesignSystem.Neutral.container(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large, style: .continuous))
        .elevatedShadow()
    }

    // MARK: - Background

    private var heroBackground: some View {
        let color = DesignSystem.HeatSpectrum.color(for: topic.heatValue)
        return LinearGradient(
            colors: [
                color.opacity(0.15),
                color.opacity(0.05),
                Color.clear
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Top Row

    private var topRowView: some View {
        HStack(alignment: .top, spacing: 0) {
            // 排名水印
            Text("\(rank)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(.primary.opacity(0.2))

            Spacer()

            // 仅高热度显示火焰图标
            if topic.heatValue > 500_000 {
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(DesignSystem.HeatSpectrum.color(for: topic.heatValue))
            }
        }
    }

    // MARK: - Title

    private var titleView: some View {
        Text(topic.title)
            .font(.system(size: 28, weight: .bold, design: .rounded))
            .lineLimit(2)
            .foregroundStyle(.primary)
    }

    // MARK: - Summary

    private func summaryView(_ summary: String) -> some View {
        Text(summary)
            .font(.system(size: 17, weight: .regular, design: .default))
            .lineLimit(3)
            .foregroundStyle(.secondary)
    }

    // MARK: - Bottom Row

    private var bottomRowView: some View {
        HStack(alignment: .center, spacing: 12) {
            // 趋势线
            MiniTrendLine(
                dataPoints: topic.heatHistory,
                size: .hero
            )
            .frame(width: 80, height: 32)

            Spacer()

            // 热度值
            Text(topic.heatValue.formattedHeat)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundStyle(DesignSystem.HeatSpectrum.color(for: topic.heatValue))

            // 排名变化指示器
            RankChangeIndicator(rankChange: topic.rankChange, style: .compact)
        }
    }

    // MARK: - Meta Info

    private var metaView: some View {
        HStack(spacing: 8) {
            PlatformIcon(platform: topic.platform)

            Text("·")
                .foregroundStyle(.tertiary)

            Text(formatTime(topic.fetchedAt))
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundStyle(.secondary)
        }
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

#Preview("HeroCard Showcase") {
    ScrollView {
        VStack(spacing: DesignSystem.Spacing.md) {
            // 不同平台
            ForEach(Array(Platform.allCases.enumerated()), id: \.element) { index, platform in
                let topic = TrendTopicEntity(
                    id: "\(platform.rawValue)-\(index)",
                    platform: platform,
                    title: "这是一个焦点热门话题\(index + 1)",
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

                HeroCard(topic: topic, rank: index + 1)
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
