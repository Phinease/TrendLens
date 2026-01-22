//
//  ErrorView.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//

import SwiftUI

/// 错误状态视图
/// 用于展示各种错误状态，提供重试按钮
struct ErrorView: View {

    // MARK: - Properties

    let error: AppError
    let retryAction: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme
    @State private var isPulsing: Bool = false

    // MARK: - Initialization

    init(error: AppError, retryAction: (() -> Void)? = nil) {
        self.error = error
        self.retryAction = retryAction
    }

    /// 便捷初始化 - 从任意 Error 创建
    init(error: Error, retryAction: (() -> Void)? = nil) {
        if let appError = error as? AppError {
            self.error = appError
        } else {
            self.error = .unknown(error.localizedDescription)
        }
        self.retryAction = retryAction
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // 错误图标
            errorIcon

            // 错误标题
            Text(error.title)
                .font(DesignSystem.Typography.headline)
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)

            // 错误描述
            Text(error.message)
                .font(DesignSystem.Typography.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)

            // 重试按钮
            if retryAction != nil {
                retryButton
                    .padding(.top, DesignSystem.Spacing.sm)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(DesignSystem.Animation.pulse) {
                isPulsing = true
            }
        }
    }

    // MARK: - Subviews

    private var errorIcon: some View {
        ZStack {
            // 背景渐变光晕
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            DesignSystem.SemanticColor.error(colorScheme).opacity(0.2),
                            DesignSystem.SemanticColor.warning(colorScheme).opacity(0.1),
                            .clear
                        ],
                        center: .center,
                        startRadius: 20,
                        endRadius: 50
                    )
                )
                .frame(width: 100, height: 100)
                .scaleEffect(isPulsing ? 1.1 : 1.0)

            // 图标
            Image(systemName: error.iconName)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(errorGradient)
        }
    }

    private var retryButton: some View {
        Button {
            retryAction?()
        } label: {
            HStack(spacing: DesignSystem.Spacing.xs) {
                Image(systemName: "arrow.clockwise")
                Text("重试")
            }
        }
        .primaryButtonStyle()
        .pulseAnimation(isActive: isPulsing)
    }

    // MARK: - Styling

    private var errorGradient: LinearGradient {
        LinearGradient(
            colors: [
                DesignSystem.SemanticColor.error(colorScheme),
                DesignSystem.SemanticColor.warning(colorScheme)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - App Error Types

/// 应用错误类型
enum AppError: Error, LocalizedError {
    /// 网络错误
    case network(underlying: Error?)
    /// 服务器错误
    case server(statusCode: Int)
    /// 数据解析错误
    case parsing
    /// 未找到数据
    case notFound
    /// 请求超时
    case timeout
    /// 未知错误
    case unknown(String?)

    var iconName: String {
        switch self {
        case .network:
            return "wifi.exclamationmark"
        case .server:
            return "server.rack"
        case .parsing:
            return "doc.questionmark"
        case .notFound:
            return "magnifyingglass"
        case .timeout:
            return "clock.badge.exclamationmark"
        case .unknown:
            return "exclamationmark.triangle"
        }
    }

    var title: String {
        switch self {
        case .network:
            return "网络连接失败"
        case .server(let code):
            return "服务器错误 (\(code))"
        case .parsing:
            return "数据解析失败"
        case .notFound:
            return "内容不存在"
        case .timeout:
            return "请求超时"
        case .unknown:
            return "出现错误"
        }
    }

    var message: String {
        switch self {
        case .network:
            return "请检查网络连接后重试"
        case .server(let code):
            if code >= 500 {
                return "服务器暂时不可用，请稍后重试"
            } else {
                return "请求被服务器拒绝，请稍后重试"
            }
        case .parsing:
            return "数据格式异常，请尝试更新应用"
        case .notFound:
            return "您访问的内容已被删除或不存在"
        case .timeout:
            return "服务器响应超时，请稍后重试"
        case .unknown(let message):
            return message ?? "发生了未知错误，请稍后重试"
        }
    }

    var errorDescription: String? {
        message
    }
}

// MARK: - Inline Error Banner

/// 内联错误横幅
/// 用于在页面顶部或底部显示错误提示
struct ErrorBanner: View {

    let message: String
    let onDismiss: (() -> Void)?
    let onRetry: (() -> Void)?

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(DesignSystem.SemanticColor.error(colorScheme))

            Text(message)
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.primary)
                .lineLimit(2)

            Spacer()

            if let onRetry = onRetry {
                Button("重试") {
                    onRetry()
                }
                .font(DesignSystem.Typography.footnote)
                .fontWeight(.medium)
            }

            if let onDismiss = onDismiss {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                .fill(DesignSystem.SemanticColor.error(colorScheme).opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                        .strokeBorder(
                            DesignSystem.SemanticColor.error(colorScheme).opacity(0.3),
                            lineWidth: 1
                        )
                )
        )
    }
}

// MARK: - Preview

#Preview("Error Views") {
    ScrollView {
        VStack(spacing: 40) {
            ErrorView(error: .network(underlying: nil)) {
                print("Retry network")
            }
            .frame(height: 300)

            Divider()

            ErrorView(error: .server(statusCode: 500)) {
                print("Retry server")
            }
            .frame(height: 300)

            Divider()

            ErrorView(error: .timeout) {
                print("Retry timeout")
            }
            .frame(height: 300)

            Divider()

            ErrorView(error: .unknown("自定义错误信息"))
                .frame(height: 300)
        }
        .padding()
    }
}

#Preview("Error Banner") {
    VStack(spacing: 20) {
        ErrorBanner(
            message: "网络连接失败，部分数据可能不是最新",
            onDismiss: { print("Dismiss") },
            onRetry: { print("Retry") }
        )

        ErrorBanner(
            message: "刷新失败",
            onDismiss: nil,
            onRetry: { print("Retry") }
        )

        ErrorBanner(
            message: "数据同步出现问题",
            onDismiss: { print("Dismiss") },
            onRetry: nil
        )
    }
    .padding()
}
