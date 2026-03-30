//
//  CommentRow.swift
//  TrendLens
//

import SwiftUI

/// 评论行组件
struct CommentRow: View {

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Properties

    let comment: Comment

    // MARK: - State

    @State private var isLiked: Bool

    // MARK: - Init

    init(comment: Comment) {
        self.comment = comment
        self._isLiked = State(initialValue: comment.isLiked)
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            avatarView

            VStack(alignment: .leading, spacing: 4) {
                // 用户名 + 时间
                HStack {
                    Text(comment.username)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(comment.createdAt, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // 评论内容
                Text(comment.content)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                    .lineLimit(nil)

                // 互动区
                HStack(spacing: DesignSystem.Spacing.md) {
                    Button {
                        isLiked.toggle()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(isLiked ? .red : .secondary)

                            Text("\(comment.likeCount + (isLiked && !comment.isLiked ? 1 : 0))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    if comment.replyCount > 0 {
                        Label("\(comment.replyCount)", systemImage: "bubble.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
                .padding(.top, 4)
                .sensoryFeedback(.impact(flexibility: .soft), trigger: isLiked)
            }
        }
    }
}

// MARK: - Subviews

private extension CommentRow {
    var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color(hex: comment.avatarColorHex))
                .frame(width: 36, height: 36)

            Image(systemName: comment.avatarSymbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
        }
    }
}
