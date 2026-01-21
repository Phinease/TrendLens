//
//  DesignSystem.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// Liquid Glass Design System
/// 定义应用的字体、间距、圆角、颜色等设计规范
enum DesignSystem {

    // MARK: - Typography

    enum Typography {
        /// 大标题 - 用于页面主标题
        static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)

        /// 标题 - 用于卡片标题
        static let title = Font.system(size: 28, weight: .semibold, design: .rounded)

        /// 副标题 - 用于段落标题
        static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)

        /// 正文 - 用于主要内容
        static let body = Font.system(size: 17, weight: .regular, design: .default)

        /// 辅助文字 - 用于次要信息
        static let caption = Font.system(size: 15, weight: .regular, design: .default)

        /// 小号辅助 - 用于时间戳、标签
        static let footnote = Font.system(size: 13, weight: .regular, design: .default)
    }

    // MARK: - Spacing

    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat = 8
        static let sm: CGFloat = 12
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius (Liquid Glass)

    enum CornerRadius {
        /// 小圆角 - 按钮、标签
        static let small: CGFloat = 8

        /// 中圆角 - 卡片
        static let medium: CGFloat = 16

        /// 大圆角 - 面板、模态框
        static let large: CGFloat = 24

        /// 超大圆角 - 特殊组件
        static let extraLarge: CGFloat = 32
    }

    // MARK: - Material Effects (Liquid Glass)

    enum Material {
        /// 薄材质 - 轻微透明
        static let thin = SwiftUI.Material.thin

        /// 常规材质 - 中等透明
        static let regular = SwiftUI.Material.regular

        /// 厚材质 - 较强透明
        static let thick = SwiftUI.Material.thick

        /// 超厚材质 - 最强透明
        static let ultraThick = SwiftUI.Material.ultraThick
    }

    // MARK: - Opacity (Liquid Glass)

    enum Opacity {
        static let subtle: CGFloat = 0.05
        static let light: CGFloat = 0.1
        static let medium: CGFloat = 0.3
        static let strong: CGFloat = 0.6
    }

    // MARK: - Animation

    enum Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.4, dampingFraction: 0.8)
    }

    // MARK: - Platform Colors

    enum PlatformColor {
        static let weibo = Color(red: 0.85, green: 0.24, blue: 0.22) // #D93A38
        static let xiaohongshu = Color(red: 0.93, green: 0.20, blue: 0.31) // #ED334F
        static let bilibili = Color(red: 0.00, green: 0.67, blue: 0.82) // #00A8D1
        static let douyin = Color(red: 0.09, green: 0.09, blue: 0.11) // #161823
        static let x = Color(red: 0.11, green: 0.63, blue: 0.95) // #1DA1F2
        static let zhihu = Color(red: 0.04, green: 0.49, blue: 0.98) // #0A7DFA
    }
}

// MARK: - View Extensions

extension View {
    /// 应用标准卡片样式（Liquid Glass）
    func cardStyle() -> some View {
        self
            .background(DesignSystem.Material.thin)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            .shadow(color: Color.black.opacity(DesignSystem.Opacity.subtle), radius: 8, y: 4)
    }

    /// 应用主按钮样式
    func primaryButtonStyle() -> some View {
        self
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
            .font(DesignSystem.Typography.body)
    }

    /// 应用次按钮样式
    func secondaryButtonStyle() -> some View {
        self
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(DesignSystem.Material.regular)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
            .font(DesignSystem.Typography.body)
    }
}
