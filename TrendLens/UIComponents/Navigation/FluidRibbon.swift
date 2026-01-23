//
//  FluidRibbon.swift
//  TrendLens
//
//  Created by Claude on 1/23/26.
//

import SwiftUI

/// 流体化平台选择器
/// 支持横向滚动、流畅动画、平台切换
struct FluidRibbon: View {

    // MARK: - Properties

    /// 当前选中的平台（nil 表示"全部"）
    @Binding var selectedPlatform: Platform?

    /// 动画命名空间
    @Namespace private var animation

    /// 环境变量
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.lg) {
                // "全部"选项
                platformItem(platform: nil, title: "全部")

                // 各平台选项
                ForEach(Platform.allCases) { platform in
                    platformItem(platform: platform, title: platform.displayName)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .frame(height: 48)
        }
        .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
    }

    // MARK: - Platform Item

    @ViewBuilder
    private func platformItem(platform: Platform?, title: String) -> some View {
        let isSelected = selectedPlatform == platform

        Button {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                selectedPlatform = platform
            }

            // 触觉反馈
            #if os(iOS)
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            #endif
        } label: {
            VStack(spacing: 4) {
                // 文字
                Text(title)
                    .font(.system(size: 15, weight: isSelected ? .semibold : .medium))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                // 选中指示器
                if isSelected {
                    if let platform = platform {
                        // 平台渐变下划线
                        Capsule()
                            .fill(platform.selectionGradient)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "selector", in: animation)
                    } else {
                        // 全部使用纯色下划线
                        Capsule()
                            .fill(.primary)
                            .frame(height: 2)
                            .matchedGeometryEffect(id: "selector", in: animation)
                    }
                } else {
                    // 占位，保持布局稳定
                    Capsule()
                        .fill(.clear)
                        .frame(height: 2)
                }
            }
            .frame(minWidth: 44) // 确保足够的点击区域
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("FluidRibbon - Light") {
    @Previewable @State var selectedPlatform: Platform? = nil

    VStack(spacing: 0) {
        FluidRibbon(selectedPlatform: $selectedPlatform)

        Spacer()

        // 调试信息
        Text("当前选中: \(selectedPlatform?.displayName ?? "全部")")
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(.secondary)
            .padding()
    }
    .background(DesignSystem.Neutral.backgroundPrimary(.light))
}

#Preview("FluidRibbon - Dark") {
    @Previewable @State var selectedPlatform: Platform? = .weibo

    VStack(spacing: 0) {
        FluidRibbon(selectedPlatform: $selectedPlatform)

        Spacer()

        // 调试信息
        Text("当前选中: \(selectedPlatform?.displayName ?? "全部")")
            .font(DesignSystem.Typography.caption)
            .foregroundStyle(.secondary)
            .padding()
    }
    .background(DesignSystem.Neutral.backgroundPrimary(.dark))
    .environment(\.colorScheme, .dark)
}

#Preview("FluidRibbon - All Platforms") {
    @Previewable @State var selectedPlatform: Platform? = .bilibili

    VStack(spacing: 20) {
        FluidRibbon(selectedPlatform: $selectedPlatform)

        // 快速切换按钮（用于测试动画）
        HStack {
            ForEach(Platform.allCases) { platform in
                Button(platform.displayName) {
                    selectedPlatform = platform
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding()

        Spacer()
    }
    .background(DesignSystem.Neutral.backgroundPrimary(.light))
}
