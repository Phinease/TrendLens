//
//  PlatformBadge.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//

import SwiftUI

/// 平台徽章组件
/// 显示平台图标和名称，支持渐变色带风格
struct PlatformBadge: View {

    // MARK: - Properties

    let platform: Platform
    let style: BadgeStyle

    enum BadgeStyle {
        /// 仅图标
        case iconOnly
        /// 仅文字
        case textOnly
        /// 图标 + 文字
        case full
        /// 紧凑模式（小图标）
        case compact
    }

    // MARK: - Initialization

    init(platform: Platform, style: BadgeStyle = .full) {
        self.platform = platform
        self.style = style
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.xxs) {
            if style != .textOnly {
                platformIcon
            }

            if style == .full || style == .textOnly {
                Text(platform.displayName)
                    .font(DesignSystem.Typography.footnote)
                    .foregroundStyle(platformColor)
            }
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.vertical, DesignSystem.Spacing.xxs)
        .background(backgroundView)
        .clipShape(Capsule())
    }

    // MARK: - Subviews

    @ViewBuilder
    private var platformIcon: some View {
        Image(systemName: platform.iconName)
            .font(.system(size: iconSize, weight: .medium))
            .foregroundStyle(platformGradient)
    }

    @ViewBuilder
    private var backgroundView: some View {
        Capsule()
            .fill(platformColor.opacity(0.1))
    }

    // MARK: - Computed Properties

    private var platformColor: Color {
        DesignSystem.PlatformColor.color(for: platform)
    }

    private var platformGradient: LinearGradient {
        DesignSystem.PlatformGradient.gradient(for: platform)
    }

    private var iconSize: CGFloat {
        switch style {
        case .compact: return 10
        case .iconOnly, .textOnly, .full: return 12
        }
    }

    private var horizontalPadding: CGFloat {
        switch style {
        case .compact, .iconOnly: return DesignSystem.Spacing.xs
        case .textOnly, .full: return DesignSystem.Spacing.sm
        }
    }
}

// MARK: - Platform Gradient Band

/// 平台渐变光带
/// 用于卡片左侧的彩色指示条
struct PlatformGradientBand: View {

    let platform: Platform
    let width: CGFloat

    init(platform: Platform, width: CGFloat = 4) {
        self.platform = platform
        self.width = width
    }

    var body: some View {
        Rectangle()
            .fill(DesignSystem.PlatformGradient.gradient(for: platform))
            .frame(width: width)
    }
}

// MARK: - Preview

#Preview("Platform Badges") {
    VStack(spacing: 20) {
        ForEach(Platform.allCases) { platform in
            HStack(spacing: 16) {
                PlatformBadge(platform: platform, style: .full)
                PlatformBadge(platform: platform, style: .iconOnly)
                PlatformBadge(platform: platform, style: .textOnly)
                PlatformBadge(platform: platform, style: .compact)
            }
        }
    }
    .padding()
}

#Preview("Gradient Bands") {
    HStack(spacing: 20) {
        ForEach(Platform.allCases) { platform in
            PlatformGradientBand(platform: platform)
                .frame(height: 80)
        }
    }
    .padding()
}
