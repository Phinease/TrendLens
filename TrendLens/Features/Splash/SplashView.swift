//
//  SplashView.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// 炫酷的启动页 - Liquid Glass 风格
struct SplashView: View {
    @State private var isAnimating = false
    @State private var glowOpacity = 0.0
    @State private var rotation: Double = 0
    @State private var scale: CGFloat = 0.5

    var body: some View {
        ZStack {
            // 背景渐变
            LinearGradient(
                colors: [
                    Color.blue.opacity(0.3),
                    Color.purple.opacity(0.3),
                    Color.pink.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // 动态光球背景
            GeometryReader { geometry in
                ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        glowColor(for: index).opacity(0.4),
                                        glowColor(for: index).opacity(0.0)
                                    ],
                                    center: .center,
                                    startRadius: 0,
                                    endRadius: 200
                                )
                            )
                            .frame(width: 300, height: 300)
                            .position(
                                x: geometry.size.width * positionX(for: index),
                                y: geometry.size.height * positionY(for: index)
                            )
                            .blur(radius: 40)
                            .opacity(glowOpacity)
                    }
                }
            }

            // 中心内容
            VStack(spacing: DesignSystem.Spacing.lg) {
                // Logo/Icon 区域
                ZStack {
                    // 外圈光环
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.blue,
                                    Color.purple,
                                    Color.pink
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 4
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(rotation))
                        .opacity(glowOpacity)

                    // 内圈图标容器
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.large)
                        .fill(DesignSystem.Material.ultraThick)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 50, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: Color.blue.opacity(0.3), radius: 20, y: 10)
                }
                .scaleEffect(scale)

                // 应用名称
                Text("TrendLens")
                    .font(DesignSystem.Typography.largeTitle)
                    .fontWeight(.bold)
                    .fontDesign(.rounded)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(glowOpacity)

                // 副标题
                Text("打破信息茧房")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)
                    .opacity(glowOpacity)
            }
        }
        .onAppear {
            startAnimations()
        }
    }

    // MARK: - Animation Logic

    private func startAnimations() {
        // 缩放动画
        withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
            scale = 1.0
        }

        // 淡入动画
        withAnimation(.easeOut(duration: 1.0)) {
            glowOpacity = 1.0
        }

        // 持续旋转动画
        withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
            rotation = 360
        }
    }

    // MARK: - Helper Methods

    private func glowColor(for index: Int) -> Color {
        switch index {
        case 0: return .blue
        case 1: return .purple
        case 2: return .pink
        default: return .blue
        }
    }

    private func positionX(for index: Int) -> CGFloat {
        switch index {
        case 0: return 0.2
        case 1: return 0.8
        case 2: return 0.5
        default: return 0.5
        }
    }

    private func positionY(for index: Int) -> CGFloat {
        switch index {
        case 0: return 0.3
        case 1: return 0.3
        case 2: return 0.7
        default: return 0.5
        }
    }
}

// MARK: - Preview

#Preview {
    SplashView()
}
