//
//  CardPressEffect.swift
//  TrendLens
//
//  Created by Claude on 1/24/26.
//

import SwiftUI

/// 卡片点击反馈效果修饰器
/// 提供缩放动画和触觉反馈
struct CardPressEffect: ViewModifier {

    // MARK: - State

    @State private var isPressed = false

    // MARK: - Configuration

    /// 按压时的缩放比例
    let pressedScale: CGFloat

    /// 动画时长
    let animationDuration: Double

    /// 是否启用触觉反馈
    let hapticEnabled: Bool

    // MARK: - Initialization

    init(
        pressedScale: CGFloat = 0.98,
        animationDuration: Double = 0.1,
        hapticEnabled: Bool = true
    ) {
        self.pressedScale = pressedScale
        self.animationDuration = animationDuration
        self.hapticEnabled = hapticEnabled
    }

    // MARK: - Body

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? pressedScale : 1.0)
            .animation(.easeOut(duration: animationDuration), value: isPressed)
            .simultaneousGesture(
                // 检测按压状态，但不拦截点击事件
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true

                            // 触觉反馈
                            if hapticEnabled {
                                #if os(iOS)
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                                #endif
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
            )
    }
}

// MARK: - View Extension

extension View {
    /// 应用卡片点击反馈效果
    func cardPressEffect(
        pressedScale: CGFloat = 0.98,
        animationDuration: Double = 0.1,
        hapticEnabled: Bool = true
    ) -> some View {
        self.modifier(
            CardPressEffect(
                pressedScale: pressedScale,
                animationDuration: animationDuration,
                hapticEnabled: hapticEnabled
            )
        )
    }
}
