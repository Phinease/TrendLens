//
//  EmptyStateView.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//

import SwiftUI

/// 空状态视图
/// 用于展示无数据、无搜索结果等空状态
struct EmptyStateView: View {

    // MARK: - Properties

    let state: EmptyState
    let action: (() -> Void)?

    @State private var isAnimating: Bool = false

    // MARK: - Initialization

    init(state: EmptyState, action: (() -> Void)? = nil) {
        self.state = state
        self.action = action
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // 动态图标
            iconView
                .frame(width: 80, height: 80)

            // 标题
            Text(state.title)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            // 描述
            Text(state.description)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)

            // 操作按钮（如果有）
            if let buttonTitle = state.buttonTitle, action != nil {
                Button(action: { action?() }) {
                    Text(buttonTitle)
                }
                .primaryButtonStyle()
                .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(DesignSystem.Animation.breathe) {
                isAnimating = true
            }
        }
    }

    // MARK: - Icon View

    @ViewBuilder
    private var iconView: some View {
        ZStack {
            // 背景光晕
            Circle()
                .fill(state.iconColor.opacity(0.1))
                .scaleEffect(isAnimating ? 1.1 : 1.0)

            // 图标
            Image(systemName: state.iconName)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(state.iconGradient)
                .scaleEffect(isAnimating ? 1.05 : 1.0)
        }
    }
}

// MARK: - Empty State Types

enum EmptyState {
    /// 无热榜数据
    case noTrends
    /// 无搜索结果
    case noSearchResults(query: String)
    /// 无收藏
    case noFavorites
    /// 网络问题
    case noConnection
    /// 平台无数据
    case noPlatformData(platform: Platform)
    /// 自定义
    case custom(icon: String, title: String, description: String, buttonTitle: String?)

    var iconName: String {
        switch self {
        case .noTrends:
            return "flame.fill"
        case .noSearchResults:
            return "magnifyingglass"
        case .noFavorites:
            return "heart"
        case .noConnection:
            return "wifi.slash"
        case .noPlatformData:
            return "tray"
        case .custom(let icon, _, _, _):
            return icon
        }
    }

    var iconColor: Color {
        switch self {
        case .noTrends:
            return .orange
        case .noSearchResults:
            return .blue
        case .noFavorites:
            return .pink
        case .noConnection:
            return .red
        case .noPlatformData(let platform):
            return DesignSystem.PlatformColor.color(for: platform)
        case .custom:
            return .gray
        }
    }

    var iconGradient: LinearGradient {
        switch self {
        case .noPlatformData(let platform):
            return DesignSystem.PlatformGradient.gradient(for: platform)
        default:
            return LinearGradient(
                colors: [iconColor, iconColor.opacity(0.7)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var title: String {
        switch self {
        case .noTrends:
            return "暂无热榜数据"
        case .noSearchResults:
            return "未找到相关内容"
        case .noFavorites:
            return "暂无收藏"
        case .noConnection:
            return "网络连接问题"
        case .noPlatformData(let platform):
            return "\(platform.displayName)暂无数据"
        case .custom(_, let title, _, _):
            return title
        }
    }

    var description: String {
        switch self {
        case .noTrends:
            return "热榜数据正在加载中，请稍后再试"
        case .noSearchResults(let query):
            return "没有找到与「\(query)」相关的热点话题"
        case .noFavorites:
            return "点击话题卡片上的心形图标即可收藏"
        case .noConnection:
            return "请检查网络连接后重试"
        case .noPlatformData(let platform):
            return "暂时无法获取\(platform.displayName)的热榜数据"
        case .custom(_, _, let description, _):
            return description
        }
    }

    var buttonTitle: String? {
        switch self {
        case .noTrends, .noPlatformData:
            return "刷新"
        case .noConnection:
            return "重试"
        case .noSearchResults:
            return "清除搜索"
        case .noFavorites:
            return nil
        case .custom(_, _, _, let buttonTitle):
            return buttonTitle
        }
    }
}

// MARK: - Preview

#Preview("Empty States") {
    ScrollView {
        VStack(spacing: 40) {
            EmptyStateView(state: .noTrends) {
                print("Refresh tapped")
            }
            .frame(height: 300)

            Divider()

            EmptyStateView(state: .noSearchResults(query: "测试")) {
                print("Clear search tapped")
            }
            .frame(height: 300)

            Divider()

            EmptyStateView(state: .noFavorites)
                .frame(height: 300)

            Divider()

            EmptyStateView(state: .noConnection) {
                print("Retry tapped")
            }
            .frame(height: 300)

            Divider()

            EmptyStateView(state: .noPlatformData(platform: .weibo)) {
                print("Refresh weibo tapped")
            }
            .frame(height: 300)
        }
        .padding()
    }
}
