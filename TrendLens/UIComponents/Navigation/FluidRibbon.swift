//
//  FluidRibbon.swift
//  TrendLens
//
//  Created by Claude on 1/23/26.
//

import SwiftUI

/// 流体化平台选择器
/// 支持横向滚动、Liquid Glass 选中态、平台切换
struct FluidRibbon: View {

    // MARK: - Properties

    /// 当前选中的平台（nil 表示"全部"）
    @Binding var selectedPlatform: Platform?

    /// 动画命名空间
    @Namespace private var animation

    /// 触觉反馈触发器
    @State private var selectionTrigger = false

    // MARK: - Body

    var body: some View {
        ScrollView(.horizontal) {
            GlassEffectContainer(spacing: DesignSystem.Spacing.xs) {
                HStack(spacing: DesignSystem.Spacing.xs) {
                    // "全部"选项
                    platformChip(platform: nil, title: "全部", icon: "globe")

                    // 各平台选项
                    ForEach(Platform.allCases) { platform in
                        platformChip(platform: platform, title: platform.displayName, icon: platform.iconName)
                    }
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            .frame(height: 48)
        }
        .scrollIndicators(.hidden)
        .sensoryFeedback(.selection, trigger: selectionTrigger)
    }

    // MARK: - Platform Chip

    @ViewBuilder
    private func platformChip(platform: Platform?, title: String, icon: String) -> some View {
        let isSelected = selectedPlatform == platform

        Button {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                selectedPlatform = platform
            }
            selectionTrigger.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(chipForeground(platform: platform, isSelected: isSelected))

                Text(title)
                    .font(.subheadline.weight(isSelected ? .semibold : .medium))
                    .foregroundStyle(chipForeground(platform: platform, isSelected: isSelected))
            }
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .padding(.vertical, DesignSystem.Spacing.xs)
            .glassEffect(
                isSelected
                    ? .regular.tint(chipTint(for: platform)).interactive()
                    : .regular.interactive(),
                in: .capsule
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Styling

    private func chipForeground(platform: Platform?, isSelected: Bool) -> some ShapeStyle {
        isSelected ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary)
    }

    private func chipTint(for platform: Platform?) -> Color {
        guard let platform else { return .primary.opacity(0.15) }
        return platform.hintColor.opacity(0.3)
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
    @Previewable @State var selectedPlatform: Platform? = .bilibiliHotSearch

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
