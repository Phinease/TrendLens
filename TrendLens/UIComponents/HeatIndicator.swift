//
//  HeatIndicator.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//

import SwiftUI

/// 热度指示器组件
/// 显示热度能量条和热度数值
struct HeatIndicator: View {

    // MARK: - Properties

    let heatValue: Int
    let maxHeatValue: Int
    let style: IndicatorStyle

    @State private var animatedProgress: CGFloat = 0
    @State private var isPulsing: Bool = false

    enum IndicatorStyle {
        /// 紧凑模式 - 仅数字
        case compact
        /// 能量条模式
        case bar
        /// 完整模式 - 能量条 + 数字
        case full
    }

    // MARK: - Initialization

    init(
        heatValue: Int,
        maxHeatValue: Int = 1_000_000,
        style: IndicatorStyle = .full
    ) {
        self.heatValue = heatValue
        self.maxHeatValue = maxHeatValue
        self.style = style
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .compact:
                compactView
            case .bar:
                barView
            case .full:
                fullView
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animatedProgress = progress
            }
            isPulsing = DesignSystem.HeatSpectrum.needsPulse(for: heatValue)
        }
    }

    // MARK: - Subviews

    private var compactView: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            if DesignSystem.HeatSpectrum.isPhenomenal(for: heatValue) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(heatColor)
            }

            Text(heatValue.formattedHeat)
                .font(DesignSystem.Typography.mono)
                .foregroundStyle(heatColor)
        }
        .pulseAnimation(isActive: isPulsing)
    }

    private var barView: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // 背景
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.1))

                // 填充
                RoundedRectangle(cornerRadius: 2)
                    .fill(heatGradient)
                    .frame(width: geometry.size.width * animatedProgress)
                    .glowEffect(
                        color: heatColor,
                        radius: DesignSystem.HeatSpectrum.needsGlow(for: heatValue) ? 4 : 0
                    )
            }
        }
        .frame(height: 4)
        .pulseAnimation(isActive: isPulsing)
    }

    private var fullView: some View {
        HStack(spacing: DesignSystem.Spacing.xs) {
            barView
                .frame(maxWidth: .infinity)

            compactView
                .frame(minWidth: 50, alignment: .trailing)
        }
    }

    // MARK: - Computed Properties

    private var progress: CGFloat {
        min(CGFloat(heatValue) / CGFloat(maxHeatValue), 1.0)
    }

    private var heatColor: Color {
        DesignSystem.HeatSpectrum.color(for: heatValue)
    }

    private var heatGradient: LinearGradient {
        let color = heatColor
        return LinearGradient(
            colors: [color.opacity(0.8), color],
            startPoint: .leading,
            endPoint: .trailing
        )
    }
}

// MARK: - Heat Level Badge

/// 热度等级徽章
/// 显示热度的文字描述等级
struct HeatLevelBadge: View {

    let heatValue: Int

    var body: some View {
        Text(DesignSystem.HeatSpectrum.level(for: heatValue))
            .font(DesignSystem.Typography.footnote)
            .foregroundStyle(heatColor)
            .padding(.horizontal, DesignSystem.Spacing.xs)
            .padding(.vertical, DesignSystem.Spacing.xxs)
            .background(heatColor.opacity(0.1))
            .clipShape(Capsule())
    }

    private var heatColor: Color {
        DesignSystem.HeatSpectrum.color(for: heatValue)
    }
}

// MARK: - Preview

#Preview("Heat Indicators") {
    VStack(spacing: 24) {
        Group {
            Text("Compact Style").font(.headline)
            HStack(spacing: 20) {
                HeatIndicator(heatValue: 5_000, style: .compact)
                HeatIndicator(heatValue: 150_000, style: .compact)
                HeatIndicator(heatValue: 1_500_000, style: .compact)
            }
        }

        Divider()

        Group {
            Text("Bar Style").font(.headline)
            VStack(spacing: 12) {
                HeatIndicator(heatValue: 5_000, style: .bar)
                HeatIndicator(heatValue: 50_000, style: .bar)
                HeatIndicator(heatValue: 150_000, style: .bar)
                HeatIndicator(heatValue: 500_000, style: .bar)
                HeatIndicator(heatValue: 1_500_000, style: .bar)
            }
        }

        Divider()

        Group {
            Text("Full Style").font(.headline)
            VStack(spacing: 12) {
                HeatIndicator(heatValue: 8_500, style: .full)
                HeatIndicator(heatValue: 85_000, style: .full)
                HeatIndicator(heatValue: 350_000, style: .full)
                HeatIndicator(heatValue: 2_500_000, style: .full)
            }
        }

        Divider()

        Group {
            Text("Heat Level Badges").font(.headline)
            HStack(spacing: 8) {
                HeatLevelBadge(heatValue: 5_000)
                HeatLevelBadge(heatValue: 150_000)
                HeatLevelBadge(heatValue: 1_500_000)
            }
        }
    }
    .padding()
}
