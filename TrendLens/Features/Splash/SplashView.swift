//
//  SplashView.swift
//  TrendLens
//

import SwiftUI

/// 品牌启动页 — 与 App Icon（玻璃蜂鸟）风格统一
struct SplashView: View {

    // MARK: - Properties

    var onFinished: (() -> Void)? = nil

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // MARK: - State

    @State private var phase = 0  // 0=idle, 1=logoIn, 2=textIn, 3=complete

    // MARK: - Body

    var body: some View {
        ZStack {
            background

            VStack(spacing: 24) {
                // 玻璃蜂鸟 Icon
                Image(.splashLogo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 130, height: 130)
                    .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                    .shadow(
                        color: colorScheme == .dark
                            ? .white.opacity(0.06)
                            : .black.opacity(0.1),
                        radius: 24, y: 10
                    )
                    .scaleEffect(phase >= 1 ? 1.0 : 0.7)
                    .opacity(phase >= 1 ? 1 : 0)
                    .offset(y: phase >= 1 ? 0 : 20)

                // 品牌文字
                VStack(spacing: 6) {
                    Text("TrendLens")
                        .font(.system(size: 30, weight: .semibold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("打破信息茧房")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
                .opacity(phase >= 2 ? 1 : 0)
                .offset(y: phase >= 2 ? 0 : 12)
            }
        }
        .ignoresSafeArea()
        .task {
            await runAnimation()
        }
    }
}

// MARK: - Subviews

private extension SplashView {

    var background: some View {
        Rectangle()
            .fill(colorScheme == .dark
                ? Color(red: 0.06, green: 0.07, blue: 0.09)
                : Color(red: 0.96, green: 0.965, blue: 0.97))
    }
}

// MARK: - Animation

private extension SplashView {

    func runAnimation() async {
        // Reduce Motion：直接显示完整画面，短暂停留后退出
        if reduceMotion {
            phase = 3
            try? await Task.sleep(for: .seconds(1.0))
            onFinished?()
            return
        }

        // Phase 1: Icon 弹入（带位移 + 缩放 + 淡入）
        withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
            phase = 1
        }

        // Phase 2: 品牌文字滑入
        try? await Task.sleep(for: .milliseconds(400))
        withAnimation(.easeOut(duration: 0.45)) {
            phase = 2
        }

        // Phase 3: 完整画面停留
        try? await Task.sleep(for: .milliseconds(350))
        phase = 3

        // 停留让用户看到完整品牌
        try? await Task.sleep(for: .milliseconds(700))

        // 通知可以切换
        onFinished?()
    }
}

// MARK: - Preview

#Preview("Light") {
    SplashView()
        .preferredColorScheme(.light)
}

#Preview("Dark") {
    SplashView()
        .preferredColorScheme(.dark)
}
