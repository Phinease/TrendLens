//
//  CardGalleryView.swift
//  TrendLens
//
//  Created by Claude on 1/23/26.
//
//  临时可视化视图，用于验证 StandardCard 在不同状态下的显示效果
//  Phase 2 时将删除此文件
//

import SwiftUI

/// 卡片库视图
/// 展示 StandardCard 在各种组合状态下的显示效果
struct CardGalleryView: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                    // 标题
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("StandardCard Gallery")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .padding(.horizontal, DesignSystem.Spacing.md)

                        Text("Verification of card design and component integration")
                            .font(.system(size: 15, weight: .regular, design: .default))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    .padding(.vertical, DesignSystem.Spacing.md)

                    // Section 1: 不同平台示例
                    section(title: "Platforms (6 variations)") {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(Array(Platform.allCases.enumerated()), id: \.element) { index, platform in
                                StandardCard(
                                    topic: generateTopic(
                                        platform: platform,
                                        rank: index + 1,
                                        rankChange: .unchanged,
                                        hasSummary: true,
                                        heatValue: 600_000
                                    ),
                                    rank: index + 1
                                )
                            }
                        }
                    }

                    Divider()
                        .padding(.horizontal, DesignSystem.Spacing.md)

                    // Section 2: 排名变化示例
                    section(title: "Rank Changes (4 states)") {
                        let rankChanges: [RankChange] = [.new, .up(5), .down(3), .unchanged]

                        VStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(Array(rankChanges.enumerated()), id: \.offset) { index, rankChange in
                                StandardCard(
                                    topic: generateTopic(
                                        platform: Platform.allCases[index % Platform.allCases.count],
                                        rank: index + 1,
                                        rankChange: rankChange,
                                        hasSummary: true,
                                        heatValue: 500_000
                                    ),
                                    rank: index + 1
                                )
                            }
                        }
                    }

                    Divider()
                        .padding(.horizontal, DesignSystem.Spacing.md)

                    // Section 3: 热度等级示例
                    section(title: "Heat Levels (3 variations)") {
                        let heatValues = [300_000, 600_000, 1_200_000]

                        VStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(Array(heatValues.enumerated()), id: \.offset) { index, heat in
                                StandardCard(
                                    topic: generateTopic(
                                        platform: .weibo,
                                        rank: index + 1,
                                        rankChange: .up(index),
                                        hasSummary: true,
                                        heatValue: heat
                                    ),
                                    rank: index + 1
                                )
                            }
                        }
                    }

                    Divider()
                        .padding(.horizontal, DesignSystem.Spacing.md)

                    // Section 4: 有/无摘要对比
                    section(title: "With & Without Summary") {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            StandardCard(
                                topic: generateTopic(
                                    platform: .bilibili,
                                    rank: 1,
                                    rankChange: .new,
                                    hasSummary: true,
                                    heatValue: 750_000
                                ),
                                rank: 1
                            )

                            StandardCard(
                                topic: generateTopic(
                                    platform: .xiaohongshu,
                                    rank: 2,
                                    rankChange: .up(3),
                                    hasSummary: false,
                                    heatValue: 450_000
                                ),
                                rank: 2
                            )
                        }
                    }

                    Divider()
                        .padding(.horizontal, DesignSystem.Spacing.md)

                    // Section 5: 各种排名示例
                    section(title: "Various Ranks") {
                        VStack(spacing: DesignSystem.Spacing.md) {
                            ForEach([1, 3, 5, 10, 15, 20], id: \.self) { rank in
                                StandardCard(
                                    topic: generateTopic(
                                        platform: Platform.allCases[rank % Platform.allCases.count],
                                        rank: rank,
                                        rankChange: .up(Int.random(in: 1...5)),
                                        hasSummary: Bool.random(),
                                        heatValue: max(50_000, 1_200_000 - rank * 50_000)
                                    ),
                                    rank: rank
                                )
                            }
                        }
                    }

                    // 底部间距
                    Spacer()
                        .frame(height: DesignSystem.Spacing.lg)
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .navigationTitle("Card Gallery")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func section<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(title)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .padding(.horizontal, DesignSystem.Spacing.md)

            VStack(spacing: DesignSystem.Spacing.md) {
                content()
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }

    private func generateTopic(
        platform: Platform,
        rank: Int,
        rankChange: RankChange,
        hasSummary: Bool,
        heatValue: Int
    ) -> TrendTopicEntity {
        TrendTopicEntity(
            id: "\(platform.rawValue)-\(rank)-\(UUID().uuidString)",
            platform: platform,
            title: "这是排名第 \(rank) 的热门话题",
            description: "话题描述文本",
            heatValue: heatValue,
            rank: rank,
            link: nil,
            tags: ["热点", "讨论", platform.displayName],
            fetchedAt: Date().addingTimeInterval(TimeInterval(-Int.random(in: 0...7200))),
            rankChange: rankChange,
            heatHistory: generateHeatHistory(baseHeat: heatValue),
            summary: hasSummary
                ? "该话题在平台上引起广泛讨论。用户参与度高，相关内容不断更新。话题热度保持高位。"
                : nil,
            isFavorite: false
        )
    }

    private func generateHeatHistory(baseHeat: Int) -> [HeatDataPoint] {
        let now = Date()
        let pointCount = 12

        return (0..<pointCount).map { i in
            let hoursAgo = (pointCount - 1 - i) * 1
            let timestamp = now.addingTimeInterval(TimeInterval(-hoursAgo * 3600))

            let variation = Int.random(in: -baseHeat/10...baseHeat/10)
            let trendOffset = i * (baseHeat / pointCount / 3)

            let heatValue = max(1000, baseHeat + variation + trendOffset)

            return HeatDataPoint(
                timestamp: timestamp,
                heatValue: heatValue,
                rank: max(1, 12 - i / 2)
            )
        }
    }
}

// MARK: - Preview

#Preview {
    CardGalleryView()
}
