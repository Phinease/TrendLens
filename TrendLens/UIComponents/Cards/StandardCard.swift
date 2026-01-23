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
            // 前两行 + 右侧热度图
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                // 左侧：排名、标题、摘要
                VStack(alignment: .leading, spacing: 0) {
                    // 第一行：排名 | 标题
                    firstRowView

                    // 第二行：AI 摘要（可选）
                    if let summary = topic.summary {
                        summaryRowView(summary)
                    }
                }

                Spacer()

                // 右侧：MiniTrendLine（仅当有摘要时显示，自适应宽高）
                if let _ = topic.summary, !topic.heatHistory.isEmpty {
                    MiniTrendLine(
                        dataPoints: topic.heatHistory,
                        size: .standard
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            // 第三行：平台信息 · 时间 · 热度值 · 热度等级 · 排名变化
            leftMetricsView
                .padding(.top, DesignSystem.Spacing.xs)
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
            Text(topic.title)
                .font(.system(size: 17, weight: .semibold, design: .default))
                .lineLimit(2)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.bottom, DesignSystem.Spacing.sm)
    }

    private func summaryRowView(_ summary: String) -> some View {
        Text(summary)
            .font(.system(size: 15, weight: .regular, design: .default))
            .lineLimit(3)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.bottom, DesignSystem.Spacing.sm)
    }

    @ViewBuilder
    private var leftMetricsView: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            // 平台图标（左侧添加margin以对齐排名数字）
            PlatformIcon(platform: topic.platform)
                .padding(.leading, 5)

            // 分隔符
            Text("·")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 12, alignment: .center)

            // 时间戳
            Text(formatTime(topic.fetchedAt))
                .font(.system(size: 13, weight: .regular, design: .default))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .center)

            // 分隔符
            Text("·")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 12, alignment: .center)

            // 热度值
            Text(topic.heatValue.formattedHeat)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundStyle(DesignSystem.HeatSpectrum.color(for: topic.heatValue))
                .frame(width: 48, alignment: .center)

            // 分隔符
            Text("·")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 12, alignment: .center)

            // 热度图标
            Image(systemName: "flame.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DesignSystem.HeatSpectrum.color(for: topic.heatValue))

            // 热度等级指示
            Text(heatLevelLabel)
                .font(.system(size: 13, weight: .semibold, design: .default))
                .foregroundStyle(DesignSystem.HeatSpectrum.color(for: topic.heatValue))
                .frame(width: 16, alignment: .center)

            // 分隔符
            Text("·")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.tertiary)
                .frame(width: 12, alignment: .center)

            // 排名变化指示器
            RankChangeIndicator(rankChange: topic.rankChange, style: .compact)
        }
    }

    // MARK: - Helpers

    private var heatLevelLabel: String {
        switch topic.heatValue {
        case ..<50_000: return "低"
        case 50_000..<500_000: return "中"
        default: return "高"
        }
    }

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
