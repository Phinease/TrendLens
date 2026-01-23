//
//  TrendCard.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//

import SwiftUI

/// 热点卡片组件（Morphic Card）
/// 基于 Prismatic Flow 设计系统的变形卡片
struct TrendCard: View {

    // MARK: - Properties

    let topic: TrendTopicEntity
    let showCurve: Bool
    let onTap: (() -> Void)?
    let onFavorite: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPressed: Bool = false
    @State private var breathScale: CGFloat = 1.0

    // MARK: - Initialization

    init(
        topic: TrendTopicEntity,
        showCurve: Bool = true,
        onTap: (() -> Void)? = nil,
        onFavorite: (() -> Void)? = nil
    ) {
        self.topic = topic
        self.showCurve = showCurve
        self.onTap = onTap
        self.onFavorite = onFavorite
    }

    // MARK: - Body

    var body: some View {
        Button {
            onTap?()
        } label: {
            cardContent
        }
        .buttonStyle(MorphicCardButtonStyle())
    }

    // MARK: - Card Content

    private var cardContent: some View {
        HStack(spacing: 0) {
            // 左侧渐变光带
            PlatformGradientBand(platform: topic.platform)

            // 主内容区域
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // 顶部行：排名 + 标题 + 收藏
                topRow

                // 热度条
                HeatIndicator(heatValue: topic.heatValue, style: .full)

                // 底部行：平台 + 时间 + 排名变化
                bottomRow
            }
            .padding(DesignSystem.Spacing.md)

            // 右侧迷你曲线（如果有数据）
            if showCurve && !topic.heatHistory.isEmpty {
                miniCurve
                    .padding(.trailing, DesignSystem.Spacing.md)
            }
        }
        .frame(minHeight: 88)
        .background(cardBackground)
        .clipShape(morphicShape)
        .shadow(
            color: shadowColor,
            radius: shadowRadius,
            y: shadowY
        )
    }

    // MARK: - Subviews

    private var topRow: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            RankBadge(rank: topic.rank, platform: topic.platform)

            Text(topic.title)
                .font(DesignSystem.Typography.body)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)

            Spacer(minLength: DesignSystem.Spacing.xs)

            favoriteButton
        }
    }

    private var bottomRow: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            PlatformBadge(platform: topic.platform, style: .compact)

            Text(timeAgo)
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(.secondary)

            Spacer()

            RankChangeIndicator(rankChange: topic.rankChange, style: .full)
        }
    }

    private var favoriteButton: some View {
        Button {
            onFavorite?()
        } label: {
            Image(systemName: topic.isFavorite ? "heart.fill" : "heart")
                .font(.system(size: 18))
                .foregroundStyle(topic.isFavorite ? .red : .secondary)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var miniCurve: some View {
        if topic.heatHistory.count >= 2 {
            HeatCurveMini(
                dataPoints: topic.heatHistory,
                platform: topic.platform
            )
            .frame(width: 60, height: 36)
        }
    }

    // MARK: - Styling

    private var cardBackground: some View {
        ZStack {
            // 材质背景
            Rectangle()
                .fill(DesignSystem.Material.regular)

            // 平台色氛围
            DesignSystem.PlatformGradient.gradient(for: topic.platform)
                .opacity(0.03)
        }
    }

    private var morphicShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: DesignSystem.CornerRadius.Asymmetric.topLeading,
            bottomLeadingRadius: DesignSystem.CornerRadius.Asymmetric.bottomLeading,
            bottomTrailingRadius: DesignSystem.CornerRadius.Asymmetric.bottomTrailing,
            topTrailingRadius: DesignSystem.CornerRadius.Asymmetric.topTrailing
        )
    }

    private var shadowColor: Color {
        if DesignSystem.HeatSpectrum.needsGlow(for: topic.heatValue) {
            return DesignSystem.HeatSpectrum.color(for: topic.heatValue).opacity(0.3)
        }
        let shadow = DesignSystem.Shadow.light(colorScheme)
        return shadow.color
    }

    private var shadowRadius: CGFloat {
        DesignSystem.HeatSpectrum.needsGlow(for: topic.heatValue) ? 8 : 4
    }

    private var shadowY: CGFloat {
        2
    }

    // MARK: - Computed Properties

    private var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: topic.fetchedAt, relativeTo: Date())
    }
}

// MARK: - Morphic Card Button Style

struct MorphicCardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(DesignSystem.Animation.quick, value: configuration.isPressed)
    }
}

// MARK: - Mini Heat Curve (Placeholder - will be replaced)

struct HeatCurveMini: View {
    let dataPoints: [HeatDataPoint]
    let platform: Platform

    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard dataPoints.count >= 2 else { return }

                let sortedPoints = dataPoints.sortedByTime
                let maxHeat = sortedPoints.maxHeat ?? 1
                let minHeat = sortedPoints.minHeat ?? 0
                let heatRange = max(maxHeat - minHeat, 1)

                let stepX = geometry.size.width / CGFloat(sortedPoints.count - 1)

                for (index, point) in sortedPoints.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedY = CGFloat(point.heatValue - minHeat) / CGFloat(heatRange)
                    let y = geometry.size.height * (1 - normalizedY)

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(
                DesignSystem.PlatformGradient.gradient(for: platform),
                style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
            )
            .shadow(
                color: DesignSystem.PlatformColor.color(for: platform).opacity(0.5),
                radius: 3
            )
        }
    }
}

// MARK: - Preview

#Preview("Trend Cards") {
    ScrollView {
        VStack(spacing: 16) {
            // 高热度卡片
            TrendCard(
                topic: TrendTopicEntity(
                    id: "1",
                    platform: .weibo,
                    title: "某明星官宣结婚消息引发热议",
                    heatValue: 1_500_000,
                    rank: 1,
                    rankChange: .new,
                    heatHistory: mockHeatHistory(),
                    summary: "该事件曝光后迅速登上热搜榜单，成为网友热议的焦点。网民积极参与讨论，评论和转发数量持续增加。"
                )
            )

            // 中等热度卡片
            TrendCard(
                topic: TrendTopicEntity(
                    id: "2",
                    platform: .bilibili,
                    title: "年度游戏大作正式发售",
                    heatValue: 350_000,
                    rank: 2,
                    rankChange: .up(5),
                    heatHistory: mockHeatHistory(),
                    summary: "该游戏大作首日销售量创新高，众多 UP 主制作相关内容，视频播放量持续上升。"
                )
            )

            // 普通热度卡片
            TrendCard(
                topic: TrendTopicEntity(
                    id: "3",
                    platform: .xiaohongshu,
                    title: "春季穿搭灵感分享",
                    heatValue: 85_000,
                    rank: 8,
                    rankChange: .down(2),
                    heatHistory: mockHeatHistory(),
                    summary: "小红书平台上用户积极分享春季穿搭建议，优质笔记频繁出现，内容质量不断提升。"
                )
            )

            // 低热度卡片
            TrendCard(
                topic: TrendTopicEntity(
                    id: "4",
                    platform: .zhihu,
                    title: "如何评价最新发布的 AI 技术",
                    heatValue: 25_000,
                    rank: 15,
                    rankChange: .unchanged,
                    heatHistory: [],
                    summary: "知乎用户围绕此话题展开多层次讨论，专家答主提供了深入细致的分析和见解。"
                ),
                showCurve: false
            )
        }
        .padding()
    }
}

// Mock data for preview
private func mockHeatHistory() -> [HeatDataPoint] {
    let now = Date()
    return (0..<8).map { i in
        HeatDataPoint(
            timestamp: now.addingTimeInterval(TimeInterval(-i * 3600)),
            heatValue: Int.random(in: 50_000...200_000),
            rank: Int.random(in: 1...10)
        )
    }.reversed()
}
