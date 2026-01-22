//
//  RankChangeIndicator.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//

import SwiftUI

/// 排名变化指示器
/// 显示排名上升、下降、新上榜或持平状态
struct RankChangeIndicator: View {

    // MARK: - Properties

    let rankChange: RankChange
    let style: IndicatorStyle
    @Environment(\.colorScheme) private var colorScheme

    @State private var offset: CGFloat = 0

    enum IndicatorStyle {
        /// 紧凑模式 - 仅图标
        case compact
        /// 完整模式 - 图标 + 数字
        case full
    }

    // MARK: - Initialization

    init(rankChange: RankChange, style: IndicatorStyle = .full) {
        self.rankChange = rankChange
        self.style = style
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch rankChange {
            case .new:
                newBadge
            case .up(let count):
                upIndicator(count: count)
            case .down(let count):
                downIndicator(count: count)
            case .unchanged:
                unchangedIndicator
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Subviews

    private var newBadge: some View {
        Text("NEW")
            .font(.system(size: 10, weight: .bold, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(DesignSystem.SemanticColor.info(colorScheme))
            )
            .pulseAnimation(isActive: true)
    }

    private func upIndicator(count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "arrow.up")
                .font(.system(size: style == .compact ? 10 : 12, weight: .bold))
                .offset(y: offset)

            if style == .full {
                Text("\(count)")
                    .font(DesignSystem.Typography.footnote)
                    .fontWeight(.medium)
            }
        }
        .foregroundStyle(DesignSystem.SemanticColor.success(colorScheme))
    }

    private func downIndicator(count: Int) -> some View {
        HStack(spacing: 2) {
            Image(systemName: "arrow.down")
                .font(.system(size: style == .compact ? 10 : 12, weight: .bold))
                .offset(y: -offset)

            if style == .full {
                Text("\(count)")
                    .font(DesignSystem.Typography.footnote)
                    .fontWeight(.medium)
            }
        }
        .foregroundStyle(DesignSystem.SemanticColor.error(colorScheme))
    }

    private var unchangedIndicator: some View {
        Text("—")
            .font(.system(size: style == .compact ? 10 : 12, weight: .medium))
            .foregroundStyle(.secondary)
    }

    // MARK: - Animation

    private func startAnimation() {
        switch rankChange {
        case .up, .down:
            withAnimation(
                .easeInOut(duration: 0.5)
                .repeatForever(autoreverses: true)
            ) {
                offset = rankChange.isPositive ? -2 : 2
            }
        default:
            break
        }
    }
}

// MARK: - Rank Badge

/// 排名徽章
/// 显示当前排名数字
struct RankBadge: View {

    let rank: Int
    let platform: Platform?

    init(rank: Int, platform: Platform? = nil) {
        self.rank = rank
        self.platform = platform
    }

    var body: some View {
        Text("\(rank)")
            .font(.system(size: rank < 10 ? 16 : 14, weight: .bold, design: .rounded))
            .foregroundStyle(foregroundColor)
            .frame(width: 28, height: 28)
            .background(backgroundView)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var backgroundView: some View {
        if rank <= 3, let platform = platform {
            // TOP 3 使用平台渐变
            DesignSystem.PlatformGradient.gradient(for: platform)
        } else if rank <= 3 {
            // TOP 3 无平台时使用金色渐变
            LinearGradient(
                colors: [Color(hex: "FBBF24"), Color(hex: "F59E0B")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            // 其他排名使用灰色背景
            Color.gray.opacity(0.15)
        }
    }

    private var foregroundColor: Color {
        rank <= 3 ? .white : .primary
    }
}

// MARK: - Preview

#Preview("Rank Change Indicators") {
    VStack(spacing: 24) {
        Group {
            Text("Compact Style").font(.headline)
            HStack(spacing: 20) {
                RankChangeIndicator(rankChange: .new, style: .compact)
                RankChangeIndicator(rankChange: .up(5), style: .compact)
                RankChangeIndicator(rankChange: .down(3), style: .compact)
                RankChangeIndicator(rankChange: .unchanged, style: .compact)
            }
        }

        Divider()

        Group {
            Text("Full Style").font(.headline)
            HStack(spacing: 20) {
                RankChangeIndicator(rankChange: .new, style: .full)
                RankChangeIndicator(rankChange: .up(12), style: .full)
                RankChangeIndicator(rankChange: .down(8), style: .full)
                RankChangeIndicator(rankChange: .unchanged, style: .full)
            }
        }

        Divider()

        Group {
            Text("Rank Badges").font(.headline)
            HStack(spacing: 12) {
                RankBadge(rank: 1, platform: .weibo)
                RankBadge(rank: 2, platform: .bilibili)
                RankBadge(rank: 3, platform: .xiaohongshu)
                RankBadge(rank: 4)
                RankBadge(rank: 10)
                RankBadge(rank: 25)
            }
        }
    }
    .padding()
}
