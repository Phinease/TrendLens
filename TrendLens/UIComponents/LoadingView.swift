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
/// 用于加载时显示占位内容
struct SkeletonCard: View {

    @State private var shimmerOffset: CGFloat = -200

    var body: some View {
        HStack(spacing: 0) {
            // 左侧光带占位
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 4)

            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                // 顶部行
                HStack(spacing: DesignSystem.Spacing.xs) {
                    // 排名占位
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 28, height: 28)

                    // 标题占位
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 18)

                    Spacer()

                    // 收藏按钮占位
                    Circle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 20, height: 20)
                }

                // 热度条占位
                RoundedRectangle(cornerRadius: 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: 4)

                // 底部行
                HStack(spacing: DesignSystem.Spacing.sm) {
                    // 平台徽章占位
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 50, height: 20)

                    // 时间占位
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 14)

                    Spacer()

                    // 排名变化占位
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 30, height: 14)
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .frame(minHeight: 88)
        .background(DesignSystem.Material.regular)
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: DesignSystem.CornerRadius.Asymmetric.topLeading,
                bottomLeadingRadius: DesignSystem.CornerRadius.Asymmetric.bottomLeading,
                bottomTrailingRadius: DesignSystem.CornerRadius.Asymmetric.bottomTrailing,
                topTrailingRadius: DesignSystem.CornerRadius.Asymmetric.topTrailing
            )
        )
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
                            Color.white.opacity(0.3),
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
