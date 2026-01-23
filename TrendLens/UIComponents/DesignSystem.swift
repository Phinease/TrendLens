//
//  DesignSystem.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// Prismatic Flow Design System
/// 基于 iOS 26 Liquid Glass 的增强设计系统
/// 定义应用的字体、间距、圆角、颜色、渐变等设计规范
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

        /// 数字专用 - 用于热度值、排名
        static let mono = Font.system(size: 15, weight: .medium, design: .monospaced)

        /// 大数字 - 用于突出显示的热度值
        static let monoLarge = Font.system(size: 17, weight: .semibold, design: .monospaced)
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

    // MARK: - Corner Radius

    enum CornerRadius {
        /// 小圆角 - 按钮、标签
        static let small: CGFloat = 8

        /// 中圆角 - 卡片
        static let medium: CGFloat = 16

        /// 大圆角 - 面板、模态框
        static let large: CGFloat = 24

        /// 超大圆角 - 特殊组件
        static let extraLarge: CGFloat = 32

        /// Morphic Card 非对称圆角
        enum Asymmetric {
            static let topLeading: CGFloat = 20
            static let topTrailing: CGFloat = 12
            static let bottomTrailing: CGFloat = 20
            static let bottomLeading: CGFloat = 12
        }
    }

    // MARK: - Material Effects (Liquid Glass)

    enum Material {
        /// 超薄材质 - 悬浮 TabBar
        static let ultraThin = SwiftUI.Material.ultraThinMaterial

        /// 薄材质 - 轻微透明
        static let thin = SwiftUI.Material.thin

        /// 常规材质 - 中等透明
        static let regular = SwiftUI.Material.regular

        /// 厚材质 - 较强透明
        static let thick = SwiftUI.Material.thick

        /// 超厚材质 - 最强透明
        static let ultraThick = SwiftUI.Material.ultraThick
    }

    // MARK: - Opacity

    enum Opacity {
        static let subtle: CGFloat = 0.05
        static let light: CGFloat = 0.1
        static let medium: CGFloat = 0.3
        static let strong: CGFloat = 0.6
        static let heavy: CGFloat = 0.8
    }

    // MARK: - Shadow (3D Depth System)

    enum Shadow {
        /// 轻微悬浮
        static func subtle(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, y: CGFloat) {
            let baseColor: Color = colorScheme == .dark ? .white : .black
            return (baseColor.opacity(0.05), 2, 1)
        }

        /// 卡片默认
        static func light(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, y: CGFloat) {
            let baseColor: Color = colorScheme == .dark ? .white : .black
            return (baseColor.opacity(0.08), 4, 2)
        }

        /// 悬浮态
        static func medium(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, y: CGFloat) {
            let baseColor: Color = colorScheme == .dark ? .white : .black
            return (baseColor.opacity(0.12), 8, 4)
        }

        /// 模态框
        static func heavy(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, y: CGFloat) {
            let baseColor: Color = colorScheme == .dark ? .white : .black
            return (baseColor.opacity(0.16), 16, 8)
        }

        /// 高热度发光（使用平台色）
        static func glow(color: Color) -> (color: Color, radius: CGFloat, y: CGFloat) {
            (color.opacity(0.3), 12, 0)
        }
    }

    // MARK: - Animation

    enum Animation {
        static let instant = SwiftUI.Animation.linear(duration: 0.1)
        static let quick = SwiftUI.Animation.easeOut(duration: 0.2)
        static let standard = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.5, dampingFraction: 0.7)

        /// 曲线绘制动画
        static let curveDrawing = SwiftUI.Animation.easeOut(duration: 0.8)

        /// 脉冲动画周期
        static let pulse = SwiftUI.Animation.easeInOut(duration: 1.5).repeatForever(autoreverses: true)

        /// 呼吸动画（微弱持续）
        static let breathe = SwiftUI.Animation.easeInOut(duration: 3).repeatForever(autoreverses: true)
    }

    // MARK: - Neutral Color Palette

    enum Neutral {
        /// 浅色模式背景 - 主背景
        static let backgroundPrimaryLight = Color(hex: "FAFBFC")

        /// 深色模式背景 - 主背景
        static let backgroundPrimaryDark = Color(hex: "0A0E14")

        /// 浅色模式背景 - 次要背景
        static let backgroundSecondaryLight = Color(hex: "F3F4F6")

        /// 深色模式背景 - 次要背景
        static let backgroundSecondaryDark = Color(hex: "13171F")

        /// 浅色模式容器 - 卡片背景
        static let containerLight = Color(hex: "FFFFFF")

        /// 深色模式容器 - 卡片背景
        static let containerDark = Color(hex: "1A1F2E")

        /// 浅色模式容器悬停
        static let containerHoverLight = Color(hex: "F9FAFB")

        /// 深色模式容器悬停
        static let containerHoverDark = Color(hex: "252B3A")

        /// 浅色模式边框 - 微弱
        static let borderSubtleLight = Color(hex: "000000").opacity(0.06)

        /// 深色模式边框 - 微弱
        static let borderSubtleDark = Color(hex: "FFFFFF").opacity(0.08)

        static func backgroundPrimary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? backgroundPrimaryDark : backgroundPrimaryLight
        }

        static func backgroundSecondary(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? backgroundSecondaryDark : backgroundSecondaryLight
        }

        static func container(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? containerDark : containerLight
        }

        static func containerHover(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? containerHoverDark : containerHoverLight
        }

        static func borderSubtle(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? borderSubtleDark : borderSubtleLight
        }
    }

    // MARK: - Platform Gradient Colors (Prismatic Flow)

    enum PlatformGradient {
        /// 微博：珊瑚红 → 琥珀橙 → 金黄
        static let weibo: [Color] = [
            Color(hex: "FF6B6B"),
            Color(hex: "F59E0B"),
            Color(hex: "FBBF24")
        ]

        /// 小红书：樱花粉 → 玫瑰红 → 珊瑚
        static let xiaohongshu: [Color] = [
            Color(hex: "FDA4AF"),
            Color(hex: "F43F5E"),
            Color(hex: "FF6B6B")
        ]

        /// Bilibili：天青蓝 → 青色 → 薄荷绿
        static let bilibili: [Color] = [
            Color(hex: "38BDF8"),
            Color(hex: "22D3D8"),
            Color(hex: "34D399")
        ]

        /// 抖音：霓虹粉 → 电紫 → 深黑
        static let douyin: [Color] = [
            Color(hex: "F472B6"),
            Color(hex: "A855F7"),
            Color(hex: "1E1B4B")
        ]

        /// X：天蓝 → 靛蓝 → 深蓝
        static let x: [Color] = [
            Color(hex: "38BDF8"),
            Color(hex: "6366F1"),
            Color(hex: "1E3A8A")
        ]

        /// 知乎：宝石蓝 → 紫罗兰 → 薰衣草
        static let zhihu: [Color] = [
            Color(hex: "3B82F6"),
            Color(hex: "8B5CF6"),
            Color(hex: "C4B5FD")
        ]

        /// 获取平台渐变色
        static func colors(for platform: Platform) -> [Color] {
            switch platform {
            case .weibo: return weibo
            case .xiaohongshu: return xiaohongshu
            case .bilibili: return bilibili
            case .douyin: return douyin
            case .x: return x
            case .zhihu: return zhihu
            }
        }

        /// 创建平台渐变
        static func gradient(for platform: Platform) -> LinearGradient {
            LinearGradient(
                colors: colors(for: platform),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    // MARK: - Heat Spectrum Colors (热度光谱)

    enum HeatSpectrum {
        /// 冷寂 (0 - 10k)
        static let cold = Color(hex: "9CA3AF")

        /// 微温 (10k - 30k)
        static let cool = Color(hex: "93C5FD")

        /// 温热 (30k - 50k)
        static let warm = Color(hex: "6EE7B7")

        /// 升温 (50k - 100k)
        static let warming = Color(hex: "FCD34D")

        /// 火热 (100k - 200k)
        static let hot = Color(hex: "FB923C")

        /// 炽热 (200k - 500k)
        static let burning = Color(hex: "F87171")

        /// 爆发 (500k - 1M)
        static let explosive = Color(hex: "DC2626")

        /// 现象级 (1M+)
        static let phenomenal = Color(hex: "FBBF24")

        /// 根据热度值获取颜色
        static func color(for heatValue: Int) -> Color {
            switch heatValue {
            case ..<10_000: return cold
            case 10_000..<30_000: return cool
            case 30_000..<50_000: return warm
            case 50_000..<100_000: return warming
            case 100_000..<200_000: return hot
            case 200_000..<500_000: return burning
            case 500_000..<1_000_000: return explosive
            default: return phenomenal
            }
        }

        /// 获取热度等级描述
        static func level(for heatValue: Int) -> String {
            switch heatValue {
            case ..<10_000: return "冷寂"
            case 10_000..<30_000: return "微温"
            case 30_000..<50_000: return "温热"
            case 50_000..<100_000: return "升温"
            case 100_000..<200_000: return "火热"
            case 200_000..<500_000: return "炽热"
            case 500_000..<1_000_000: return "爆发"
            default: return "现象级"
            }
        }

        /// 是否需要发光效果
        static func needsGlow(for heatValue: Int) -> Bool {
            heatValue >= 100_000
        }

        /// 是否需要脉冲动画
        static func needsPulse(for heatValue: Int) -> Bool {
            heatValue >= 200_000
        }

        /// 是否为现象级（需要特殊效果）
        static func isPhenomenal(for heatValue: Int) -> Bool {
            heatValue >= 1_000_000
        }

        /// 根据热度值获取特效等级
        static func effectLevel(for heatValue: Int) -> HeatEffect {
            switch heatValue {
            case ..<100_000: return .none
            case 100_000..<200_000: return .glow(radius: 4)
            case 200_000..<500_000: return .glow(radius: 6)
            case 500_000..<1_000_000: return .pulse
            case 1_000_000...: return .burst
            default: return .none
            }
        }
    }

    /// 热度特效类型
    enum HeatEffect {
        case none
        case glow(radius: CGFloat)
        case pulse
        case burst
    }

    // MARK: - Semantic Colors

    enum SemanticColor {
        static func success(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "34D399") : Color(hex: "10B981")
        }

        static func warning(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "FBBF24") : Color(hex: "F59E0B")
        }

        static func error(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "F87171") : Color(hex: "EF4444")
        }

        static func info(_ colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? Color(hex: "60A5FA") : Color(hex: "3B82F6")
        }
    }

    // MARK: - Legacy Platform Colors (兼容旧代码)

    enum PlatformColor {
        static let weibo = Color(hex: "FF6B6B")
        static let xiaohongshu = Color(hex: "F43F5E")
        static let bilibili = Color(hex: "22D3D8")
        static let douyin = Color(hex: "A855F7")
        static let x = Color(hex: "6366F1")
        static let zhihu = Color(hex: "8B5CF6")

        static func color(for platform: Platform) -> Color {
            switch platform {
            case .weibo: return weibo
            case .xiaohongshu: return xiaohongshu
            case .bilibili: return bilibili
            case .douyin: return douyin
            case .x: return x
            case .zhihu: return zhihu
            }
        }
    }
}

// MARK: - Color Extension

extension Color {
    /// 从十六进制字符串创建颜色
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
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

    /// 应用 Morphic Card 样式（非对称圆角 + 渐变光带）
    func morphicCardStyle(platform: Platform? = nil) -> some View {
        self
            .background(DesignSystem.Material.regular)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: DesignSystem.CornerRadius.Asymmetric.topLeading,
                    bottomLeadingRadius: DesignSystem.CornerRadius.Asymmetric.bottomLeading,
                    bottomTrailingRadius: DesignSystem.CornerRadius.Asymmetric.bottomTrailing,
                    topTrailingRadius: DesignSystem.CornerRadius.Asymmetric.topTrailing
                )
            )
            .shadow(color: Color.black.opacity(0.08), radius: 4, y: 2)
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

    /// 发光效果
    func glowEffect(color: Color, radius: CGFloat = 8) -> some View {
        self
            .shadow(color: color.opacity(0.5), radius: radius / 2, y: 0)
            .shadow(color: color.opacity(0.3), radius: radius, y: 0)
    }

    /// 脉冲动画修饰符
    func pulseAnimation(isActive: Bool) -> some View {
        self.modifier(PulseAnimationModifier(isActive: isActive))
    }

    /// 骨架屏闪烁效果
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }

    /// 标准卡片阴影
    func cardShadow() -> some View {
        self.modifier(CardShadowModifier())
    }

    /// 聚焦卡片阴影（更强）
    func elevatedShadow() -> some View {
        self.modifier(ElevatedShadowModifier())
    }
}

// MARK: - Animation Modifiers

/// 脉冲动画修饰符
struct PulseAnimationModifier: ViewModifier {
    let isActive: Bool
    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(isActive ? scale : 1.0)
            .onAppear {
                if isActive {
                    withAnimation(DesignSystem.Animation.pulse) {
                        scale = 1.03
                    }
                }
            }
    }
}

/// 骨架屏闪烁修饰符
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        Color.white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
            )
            .onAppear {
                withAnimation(
                    .linear(duration: 1.5)
                    .repeatForever(autoreverses: false)
                ) {
                    phase = 300
                }
            }
            .clipped()
    }
}

/// 卡片阴影修饰符
struct CardShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shadowColor: Color = colorScheme == .dark ? .white : .black
        return content
            .shadow(color: shadowColor.opacity(0.08), radius: 4, y: 2)
    }
}

/// 聚焦卡片阴影修饰符
struct ElevatedShadowModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        let shadowColor: Color = colorScheme == .dark ? .white : .black
        return content
            .shadow(color: shadowColor.opacity(0.12), radius: 8, y: 4)
    }
}

// MARK: - Heat Value Formatting

extension Int {
    /// 格式化热度值为易读字符串
    var formattedHeat: String {
        switch self {
        case ..<1_000:
            return "\(self)"
        case 1_000..<10_000:
            let value = Double(self) / 1_000
            return String(format: "%.1fK", value)
        case 10_000..<1_000_000:
            let value = Double(self) / 10_000
            return String(format: "%.1f万", value)
        default:
            let value = Double(self) / 1_000_000
            return String(format: "%.1fM", value)
        }
    }
}
