//
//  LoadingView.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//

import SwiftUI

/// 加载状态视图
/// 提供全屏加载指示和骨架屏效果
struct LoadingView: View {

    // MARK: - Properties

    let style: LoadingStyle
    let message: String?

    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 1.0

    enum LoadingStyle {
        /// 简单的加载指示器
        case spinner
        /// 带消息的加载
        case withMessage
        /// 全屏覆盖
        case overlay
    }

    // MARK: - Initialization

    init(style: LoadingStyle = .spinner, message: String? = nil) {
        self.style = style
        self.message = message
    }

    // MARK: - Body

    var body: some View {
        Group {
            switch style {
            case .spinner:
                spinnerView
            case .withMessage:
                messageView
            case .overlay:
                overlayView
            }
        }
        .onAppear {
            startAnimation()
        }
    }

    // MARK: - Subviews

    private var spinnerView: some View {
        loadingIndicator
    }

    private var messageView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            loadingIndicator

            if let message = message {
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var overlayView: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: DesignSystem.Spacing.md) {
                loadingIndicator

                if let message = message {
                    Text(message)
                        .font(DesignSystem.Typography.body)
                        .foregroundStyle(.white)
                }
            }
            .padding(DesignSystem.Spacing.xl)
            .background(DesignSystem.Material.thick)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large))
        }
    }

    private var loadingIndicator: some View {
        ZStack {
            // 外圈
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [.accentColor, .accentColor.opacity(0.3), .accentColor],
                        center: .center
                    ),
                    lineWidth: 3
                )
                .frame(width: 40, height: 40)
                .rotationEffect(.degrees(rotation))

            // 内部脉冲
            Circle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: 20, height: 20)
                .scaleEffect(scale)
        }
    }

    // MARK: - Animation

    private func startAnimation() {
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        withAnimation(DesignSystem.Animation.breathe) {
            scale = 1.3
        }
    }
}

// MARK: - Skeleton Views

/// 骨架屏卡片
/// 用于加载时显示占位内容，匹配 StandardCard 布局
struct SkeletonCard: View {

    @State private var shimmerOffset: CGFloat = -200
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // 第一行：排名 + 标题 + 热度图标
            HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
                // 排名占位
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 32, height: 20)

                // 标题占位
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 20)

                Spacer(minLength: 8)

                // 热度图标占位
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 16, height: 16)
            }

            // 第二行：AI 摘要占位
            VStack(spacing: DesignSystem.Spacing.xxs) {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                    .frame(height: 16)

                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 220, height: 16)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.leading, 44) // 对齐标题

            // 第三行：元信息 + 趋势
            HStack(spacing: DesignSystem.Spacing.xs) {
                // 平台 Icon 占位
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 16, height: 16)

                // 时间占位
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 60, height: 12)

                // 热度值占位
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 40, height: 12)

                Spacer()

                // 迷你趋势线占位
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 32, height: 24)
            }
            .padding(.leading, 44) // 对齐标题
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Neutral.container(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
        .cardShadow()
        .overlay(shimmerOverlay)
        .clipped()
    }

    private var shimmerOverlay: some View {
        GeometryReader { geometry in
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            .clear,
                            Color.white.opacity(colorScheme == .dark ? 0.1 : 0.3),
                            .clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(width: 100)
                .offset(x: shimmerOffset)
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        shimmerOffset = geometry.size.width + 100
                    }
                }
        }
    }
}

/// 骨架屏列表
struct SkeletonList: View {

    let count: Int

    init(count: Int = 5) {
        self.count = count
    }

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonCard()
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

/// 内联加载指示器
struct InlineLoadingIndicator: View {

    let message: String?

    init(message: String? = nil) {
        self.message = message
    }

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ProgressView()
                .scaleEffect(0.8)

            if let message = message {
                Text(message)
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DesignSystem.Spacing.sm)
    }
}

/// 刷新加载指示器
struct RefreshLoadingView: View {

    let platform: Platform?
    @State private var glowOpacity: CGFloat = 0.3

    init(platform: Platform? = nil) {
        self.platform = platform
    }

    var body: some View {
        ZStack {
            // 光晕效果
            Circle()
                .fill(glowColor.opacity(glowOpacity))
                .frame(width: 60, height: 60)
                .blur(radius: 20)

            // 旋转渐变环
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(
                    AngularGradient(
                        colors: gradientColors,
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: 30, height: 30)
                .rotationEffect(.degrees(rotation))
        }
        .onAppear {
            startAnimation()
        }
    }

    @State private var rotation: Double = 0

    private var glowColor: Color {
        if let platform = platform {
            return DesignSystem.PlatformColor.color(for: platform)
        }
        return .accentColor
    }

    private var gradientColors: [Color] {
        if let platform = platform {
            return DesignSystem.PlatformGradient.colors(for: platform)
        }
        return [.accentColor, .accentColor.opacity(0.3)]
    }

    private func startAnimation() {
        withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
            rotation = 360
        }
        withAnimation(DesignSystem.Animation.breathe) {
            glowOpacity = 0.6
        }
    }
}

// MARK: - Preview

#Preview("Loading Views") {
    VStack(spacing: 40) {
        LoadingView(style: .spinner)

        LoadingView(style: .withMessage, message: "正在加载...")

        HStack(spacing: 20) {
            RefreshLoadingView()
            RefreshLoadingView(platform: .weibo)
            RefreshLoadingView(platform: .bilibili)
        }

        InlineLoadingIndicator(message: "加载更多...")
    }
    .padding()
}

#Preview("Skeleton Cards") {
    ScrollView {
        SkeletonList(count: 5)
            .padding(.vertical)
    }
}

#Preview("Loading Overlay") {
    ZStack {
        Color.blue
            .ignoresSafeArea()

        LoadingView(style: .overlay, message: "正在刷新数据...")
    }
}
