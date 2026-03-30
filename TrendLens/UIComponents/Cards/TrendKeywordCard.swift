//
//  TrendKeywordCard.swift
//  TrendLens
//

import SwiftUI

/// 趋势关键词卡片
struct TrendKeywordCard: View {

    let keyword: TrendKeywordEntity

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 左侧：关键词 + 元信息
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(keyword.keyword)
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                HStack(spacing: DesignSystem.Spacing.sm) {
                    // 关联话题
                    if keyword.linkedTopicCount > 0 {
                        Label("\(keyword.linkedTopicCount) 个话题", systemImage: "newspaper")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // 查询时间
                    if let queried = keyword.lastQueriedAt {
                        Text(queried, format: .relative(presentation: .named))
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            // 右侧：曲线 + 趋势值
            VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                // 迷你趋势曲线
                if keyword.trendPoints.count >= 2 {
                    MiniTrendLine(dataPoints: keyword.trendPoints)
                        .frame(width: 80, height: 28)
                }

                // 趋势值 + 方向
                HStack(spacing: 4) {
                    Image(systemName: keyword.trendDirection.icon)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(trendDirectionColor)

                    Text("\(keyword.latestTrendValue)")
                        .font(.subheadline.weight(.semibold).monospaced())
                        .foregroundStyle(trendValueColor)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    // MARK: - Styling

    private var trendValueColor: Color {
        // Google Trends 值 0-100，映射到热度色谱
        DesignSystem.HeatSpectrum.color(for: keyword.latestTrendValue * 10_000)
    }

    private var trendDirectionColor: Color {
        switch keyword.trendDirection {
        case .rising: .green
        case .falling: .red
        case .stable: .secondary
        }
    }
}
