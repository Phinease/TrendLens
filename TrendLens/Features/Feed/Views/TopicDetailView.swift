//
//  TopicDetailView.swift
//  TrendLens
//
//  Created by Claude on 2/18/26.
//

import SwiftUI

/// 话题详情页面 - 展示新闻内容、图片、评论等
struct TopicDetailView: View {

    // MARK: - Properties

    let topic: TrendTopicEntity
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL
    @State private var isFavorite: Bool

    // MARK: - Initialization

    init(topic: TrendTopicEntity) {
        self.topic = topic
        self._isFavorite = State(initialValue: topic.isFavorite)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // 头部：平台 + 时间
                sourceHeader
                    .padding(.bottom, DesignSystem.Spacing.md)

                // 标题
                Text(topic.title)
                    .font(.system(size: 24, weight: .bold, design: .default))
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .padding(.bottom, DesignSystem.Spacing.lg)

                // 热度信息栏
                heatInfoBar
                    .padding(.bottom, DesignSystem.Spacing.lg)

                Divider()
                    .padding(.bottom, DesignSystem.Spacing.lg)

                // 图片区域
                if !topic.imageURLs.isEmpty {
                    imageGallery
                        .padding(.bottom, DesignSystem.Spacing.lg)
                }

                // 正文内容
                contentSection

                // 标签
                if !topic.tags.isEmpty {
                    tagsSection
                        .padding(.top, DesignSystem.Spacing.xl)
                }

                // 评论区
                if !topic.comments.isEmpty {
                    commentsSection
                        .padding(.top, DesignSystem.Spacing.xl)
                }

                // 底部留白
                Spacer()
                    .frame(height: 40)
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
        .navigationTitle("详情")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // 收藏按钮
                Button {
                    toggleFavorite()
                } label: {
                    Image(systemName: isFavorite ? "star.fill" : "star")
                        .foregroundStyle(isFavorite ? .yellow : .primary)
                }

                // 分享按钮
                Button {
                    shareTopic()
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }

                // 打开原文
                if let link = topic.link, !link.isEmpty, let url = URL(string: link) {
                    Button {
                        openURL(url)
                    } label: {
                        Image(systemName: "safari")
                    }
                }
            }
        }
    }

    // MARK: - Source Header

    private var sourceHeader: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            // 平台图标
            PlatformIcon(platform: topic.platform)

            // 平台名称
            Text(topic.platform.displayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.primary)

            Text("·")
                .foregroundStyle(.tertiary)

            // 时间
            Text(formatDate(topic.fetchedAt))
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    // MARK: - Heat Info Bar

    private var heatInfoBar: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            // 排名
            HStack(spacing: 4) {
                Image(systemName: "number")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("\(topic.rank)")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
            }

            // 热度
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(DesignSystem.HeatSpectrum.color(for: topic.heatValue))
                Text(topic.heatValue.formattedHeat)
                    .font(.system(size: 15, weight: .semibold, design: .monospaced))
                    .foregroundStyle(DesignSystem.HeatSpectrum.color(for: topic.heatValue))
            }

            // 排名变化
            RankChangeIndicator(rankChange: topic.rankChange, style: .full)

            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Neutral.container(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
    }

    // MARK: - Image Gallery

    private var imageGallery: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            if topic.imageURLs.count == 1 {
                // 单图：大图展示
                AsyncImage(url: URL(string: topic.imageURLs[0])) { phase in
                    imagePhaseView(phase: phase)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
            } else {
                // 多图：网格展示
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.xs),
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.xs)
                    ],
                    spacing: DesignSystem.Spacing.xs
                ) {
                    ForEach(Array(topic.imageURLs.prefix(4).enumerated()), id: \.offset) { index, urlString in
                        AsyncImage(url: URL(string: urlString)) { phase in
                            imagePhaseView(phase: phase)
                        }
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small, style: .continuous))
                        .overlay {
                            // 显示更多图片数量
                            if index == 3 && topic.imageURLs.count > 4 {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small, style: .continuous)
                                    .fill(.black.opacity(0.5))
                                Text("+\(topic.imageURLs.count - 4)")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func imagePhaseView(phase: AsyncImagePhase) -> some View {
        switch phase {
        case .empty:
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    ProgressView()
                }
        case .success(let image):
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        case .failure:
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    Image(systemName: "photo")
                        .font(.system(size: 30))
                        .foregroundStyle(.secondary)
                }
        @unknown default:
            Rectangle()
                .fill(Color.gray.opacity(0.2))
        }
    }

    // MARK: - Content Section

    private var contentSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // AI 摘要（核心内容）
            if !topic.summary.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.purple)
                        Text("AI 摘要")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(.purple)
                    }

                    Text(topic.summary)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineSpacing(6)
                }
                .padding(DesignSystem.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous)
                        .fill(Color.purple.opacity(0.08))
                )
            }

            // 详细内容
            if let content = topic.content, !content.isEmpty {
                Text(content)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineSpacing(8)
            }

            // 占位内容（当没有详细内容时）
            if topic.content == nil || topic.content?.isEmpty == true {
                if let description = topic.description, !description.isEmpty {
                    Text(description)
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.primary)
                        .lineSpacing(8)
                } else {
                    placeholderContent
                }
            }
        }
    }

    // MARK: - Placeholder Content

    private var placeholderContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "doc.text")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)

                Text("暂无详细内容")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text("点击右上角「Safari」按钮可在浏览器中查看完整内容。")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(.tertiary)
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Neutral.container(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("相关标签")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.secondary)

            FlowLayout(spacing: DesignSystem.Spacing.xs) {
                ForEach(topic.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Comments Section

    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            // 标题
            HStack {
                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)

                Text("热门评论")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(topic.comments.count) 条")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.secondary)
            }

            Divider()

            // 评论列表
            LazyVStack(spacing: DesignSystem.Spacing.md) {
                ForEach(topic.comments) { comment in
                    CommentRow(comment: comment)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Neutral.container(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium, style: .continuous))
    }

    // MARK: - Helpers

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            formatter.dateFormat = "今天 HH:mm"
        } else if calendar.isDateInYesterday(date) {
            formatter.dateFormat = "昨天 HH:mm"
        } else {
            formatter.dateFormat = "MM月dd日 HH:mm"
        }

        return formatter.string(from: date)
    }

    private func toggleFavorite() {
        isFavorite.toggle()

#if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
#endif
    }

    private func shareTopic() {
#if os(iOS)
        let shareText = """
        \(topic.title)

        \(topic.summary)

        来自 \(topic.platform.displayName) · 热度 \(topic.heatValue.formattedHeat)
        """

        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
#endif
    }
}

// MARK: - Comment Row

private struct CommentRow: View {
    let comment: Comment
    @Environment(\.colorScheme) private var colorScheme
    @State private var isLiked: Bool

    init(comment: Comment) {
        self.comment = comment
        self._isLiked = State(initialValue: comment.isLiked)
    }

    var body: some View {
        HStack(alignment: .top, spacing: DesignSystem.Spacing.sm) {
            // 头像
            avatarView

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                // 用户名 + 时间
                HStack {
                    Text(comment.username)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(formatCommentTime(comment.createdAt))
                        .font(.system(size: 12, weight: .regular))
                        .foregroundStyle(.tertiary)
                }

                // 评论内容
                Text(comment.content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(.primary)
                    .lineLimit(nil)

                // 互动区
                HStack(spacing: DesignSystem.Spacing.md) {
                    // 点赞
                    Button {
                        isLiked.toggle()
                        hapticFeedback()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: isLiked ? "heart.fill" : "heart")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(isLiked ? .red : .secondary)

                            Text("\(comment.likeCount + (isLiked && !comment.isLiked ? 1 : 0))")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }
                    .buttonStyle(.plain)

                    // 回复
                    if comment.replyCount > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "bubble.right")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(.secondary)

                            Text("\(comment.replyCount)")
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(.secondary)
                        }
                    }

                    Spacer()
                }
                .padding(.top, 4)
            }
        }
    }

    private var avatarView: some View {
        ZStack {
            Circle()
                .fill(Color(hex: comment.avatarColorHex))
                .frame(width: 36, height: 36)

            Image(systemName: comment.avatarSymbol)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.white)
        }
    }

    private func formatCommentTime(_ date: Date) -> String {
        let now = Date()
        let components = Calendar.current.dateComponents([.minute, .hour, .day], from: date, to: now)

        if let day = components.day, day > 0 {
            return "\(day)天前"
        } else if let hour = components.hour, hour > 0 {
            return "\(hour)小时前"
        } else if let minute = components.minute, minute > 0 {
            return "\(minute)分钟前"
        } else {
            return "刚刚"
        }
    }

    private func hapticFeedback() {
#if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
#endif
    }
}

// MARK: - FlowLayout

/// 流式布局（用于标签显示）
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].origin.x,
                                      y: bounds.minY + result.frames[index].origin.y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
                lineHeight = max(lineHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + lineHeight)
        }
    }
}

// MARK: - Preview

#Preview("Topic Detail - 完整内容") {
    NavigationStack {
        TopicDetailView(topic: PreviewData.sampleTopicFull)
    }
}

#Preview("Topic Detail - 无图片") {
    NavigationStack {
        TopicDetailView(topic: PreviewData.sampleTopicNoImages)
    }
}

// MARK: - Preview Data

private struct PreviewData {
    static let sampleTopicFull = TrendTopicEntity(
        id: "preview-1",
        platform: .weibo,
        title: "示例热点话题标题：这是一个较长的标题用于展示多行效果",
        description: "这是一个示例话题的详细描述。",
        heatValue: 1_500_000,
        rank: 1,
        link: "https://weibo.com/example",
        tags: ["热点", "示例", "科技", "讨论"],
        fetchedAt: Date(),
        rankChange: .up(3),
        heatHistory: [],
        summary: "AI 摘要：这是一个示例话题的核心摘要，简明扼要地说明这个话题的关键信息和背景。展示详情页面的完整布局和样式。",
        isFavorite: false,
        content: """
        据最新消息，该事件已引发社会各界广泛关注。多位业内专家表示，这一现象反映了当前社会发展的某些深层趋势。

        从事件发生至今，相关话题在微博上的讨论热度持续攀升。网友们纷纷发表自己的看法，其中不乏深入的分析和独到的见解。

        有评论指出，这一事件的影响可能会持续较长时间。相关部门已经开始关注此事，预计将在近期给出官方回应。

        值得注意的是，此次事件也引发了人们对相关问题的深入思考。许多网友表示，希望看到更多理性的讨论和专业的分析。
        """,
        imageURLs: [
            "https://picsum.photos/seed/1/800/600",
            "https://picsum.photos/seed/2/800/600",
            "https://picsum.photos/seed/3/800/600"
        ],
        comments: Comment.generateMockComments(count: 8)
    )

    static let sampleTopicNoImages = TrendTopicEntity(
        id: "preview-2",
        platform: .zhihu,
        title: "如何评价这个热门话题？",
        description: nil,
        heatValue: 850_000,
        rank: 5,
        link: "https://zhihu.com/question/123",
        tags: ["讨论", "知乎"],
        fetchedAt: Date().addingTimeInterval(-3600 * 2),
        rankChange: .down(2),
        heatHistory: [],
        summary: "这是一个知乎平台的示例话题摘要，展示无图片时的布局效果。",
        isFavorite: true,
        content: nil,
        imageURLs: [],
        comments: Comment.generateMockComments(count: 5)
    )
}
