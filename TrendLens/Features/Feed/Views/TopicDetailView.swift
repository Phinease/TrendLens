//
//  TopicDetailView.swift
//  TrendLens
//

import SwiftUI

/// 话题详情页面 - 展示新闻内容、图片、评论等
struct TopicDetailView: View {

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.openURL) private var openURL

    // MARK: - Properties

    let topic: TrendTopicEntity

    // MARK: - State

    @State private var isFavorite: Bool
    @State private var displayTopic: TrendTopicEntity
    @State private var isLoadingDetail = false
    @State private var didAttemptDetailLoad = false
    @State private var favoriteTrigger = false

    // MARK: - Init

    init(topic: TrendTopicEntity) {
        self.topic = topic
        self._isFavorite = State(initialValue: topic.isFavorite)
        self._displayTopic = State(initialValue: topic)
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                sourceHeader
                    .padding(.bottom, DesignSystem.Spacing.md)

                Text(displayTopic.title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.primary)
                    .lineLimit(nil)
                    .padding(.bottom, DesignSystem.Spacing.lg)

                heatInfoBar
                    .padding(.bottom, DesignSystem.Spacing.lg)

                Divider()
                    .padding(.bottom, DesignSystem.Spacing.lg)

                if !displayTopic.imageURLs.isEmpty {
                    imageGallery
                        .padding(.bottom, DesignSystem.Spacing.lg)
                }

                contentSection

                if !displayTopic.tags.isEmpty {
                    tagsSection
                        .padding(.top, DesignSystem.Spacing.xl)
                }

                if !displayTopic.comments.isEmpty {
                    commentsSection
                        .padding(.top, DesignSystem.Spacing.xl)
                }

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
                Button(isFavorite ? "取消收藏" : "收藏", systemImage: isFavorite ? "star.fill" : "star") {
                    isFavorite.toggle()
                    favoriteTrigger.toggle()
                }
                .foregroundStyle(isFavorite ? .yellow : .primary)

                ShareLink(
                    item: "\(displayTopic.title)\n\n\(displayTopic.summary)\n\n来自 \(displayTopic.platform.displayName) · 热度 \(displayTopic.heatValue.formattedHeat)"
                )

                if let link = displayTopic.link, !link.isEmpty, let url = URL(string: link) {
                    Button("原文", systemImage: "safari") {
                        openURL(url)
                    }
                }
            }
        }
        .sensoryFeedback(.success, trigger: favoriteTrigger)
        .task(id: topic.id) {
            await loadTopicDetailIfNeeded()
        }
    }
}

// MARK: - Subviews

private extension TopicDetailView {

    var sourceHeader: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            PlatformIcon(platform: displayTopic.platform)

            Text(displayTopic.platform.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.primary)

            Text("·")
                .foregroundStyle(.tertiary)

            Text(displayTopic.fetchedAt, format: .relative(presentation: .named))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Spacer()
        }
    }

    var heatInfoBar: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Label("\(displayTopic.rank)", systemImage: "number")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(DesignSystem.HeatSpectrum.color(for: displayTopic.heatValue))
                Text(displayTopic.heatValue.formattedHeat)
                    .font(.subheadline.weight(.semibold).monospaced())
                    .foregroundStyle(DesignSystem.HeatSpectrum.color(for: displayTopic.heatValue))
            }

            RankChangeIndicator(rankChange: displayTopic.rankChange, style: .full)

            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
        .background(DesignSystem.Neutral.container(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    var imageGallery: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            if displayTopic.imageURLs.count == 1 {
                AsyncImage(url: URL(string: displayTopic.imageURLs[0])) { phase in
                    imagePhaseView(phase: phase)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
            } else {
                LazyVGrid(
                    columns: [
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.xs),
                        GridItem(.flexible(), spacing: DesignSystem.Spacing.xs)
                    ],
                    spacing: DesignSystem.Spacing.xs
                ) {
                    ForEach(Array(displayTopic.imageURLs.prefix(4).enumerated()), id: \.offset) { index, urlString in
                        AsyncImage(url: URL(string: urlString)) { phase in
                            imagePhaseView(phase: phase)
                        }
                        .frame(height: 140)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                        .overlay {
                            if index == 3 && displayTopic.imageURLs.count > 4 {
                                RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small)
                                    .fill(.black.opacity(0.5))
                                Text("+\(displayTopic.imageURLs.count - 4)")
                                    .font(.title3.weight(.semibold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    func imagePhaseView(phase: AsyncImagePhase) -> some View {
        switch phase {
        case .empty:
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay { ProgressView() }
        case .success(let image):
            image
                .resizable()
                .aspectRatio(contentMode: .fill)
        case .failure:
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    Image(systemName: "photo")
                        .font(.title)
                        .foregroundStyle(.secondary)
                }
        @unknown default:
            Rectangle()
                .fill(Color.gray.opacity(0.2))
        }
    }

    var contentSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // AI 摘要
            if !displayTopic.summary.isEmpty {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                    Label("AI 摘要", systemImage: "sparkles")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.purple)

                    Text(displayTopic.summary)
                        .font(.callout)
                        .foregroundStyle(.primary)
                        .lineSpacing(6)
                }
                .padding(DesignSystem.Spacing.md)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium)
                        .fill(Color.purple.opacity(0.08))
                )
            }

            // 详细内容
            if let content = displayTopic.content, !content.isEmpty {
                Text(content)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineSpacing(8)
            }

            // 回退内容
            if displayTopic.content == nil || displayTopic.content?.isEmpty == true {
                if let description = displayTopic.description, !description.isEmpty {
                    Text(description)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineSpacing(8)
                } else if isLoadingDetail {
                    LoadingView(message: "加载详情中...")
                } else {
                    placeholderContent
                }
            }
        }
    }

    var placeholderContent: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Label("暂无详细内容", systemImage: "doc.text")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text("点击右上角「Safari」按钮可在浏览器中查看完整内容。")
                .font(.footnote)
                .foregroundStyle(.tertiary)
        }
        .padding(DesignSystem.Spacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DesignSystem.Neutral.container(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    var tagsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("相关标签")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            FlowLayout(spacing: DesignSystem.Spacing.xs) {
                ForEach(displayTopic.tags, id: \.self) { tag in
                    Text("#\(tag)")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
        }
    }

    var commentsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Label("热门评论", systemImage: "bubble.left.and.bubble.right")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                Text("\(displayTopic.comments.count) 条")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Divider()

            LazyVStack(spacing: DesignSystem.Spacing.md) {
                ForEach(displayTopic.comments) { comment in
                    CommentRow(comment: comment)
                }
            }
        }
        .padding(DesignSystem.Spacing.md)
        .background(DesignSystem.Neutral.container(colorScheme))
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}

// MARK: - Actions

private extension TopicDetailView {

    func loadTopicDetailIfNeeded() async {
        guard !didAttemptDetailLoad else { return }
        didAttemptDetailLoad = true

        let needsRemoteDetail =
            displayTopic.heatHistory.isEmpty ||
            displayTopic.content == nil ||
            displayTopic.imageURLs.isEmpty
        guard needsRemoteDetail else { return }

        isLoadingDetail = true
        defer { isLoadingDetail = false }

        let repository = await MainActor.run {
            DependencyContainer.shared.makeTrendingRepository()
        }

        guard let detailedTopic = try? await repository.getTopicDetail(topicId: topic.id) else {
            return
        }

        // 合并远程数据，保留原始 topic 中已有的非空字段
        displayTopic = TrendTopicEntity(
            id: detailedTopic.id,
            platform: detailedTopic.platform,
            title: detailedTopic.title,
            description: detailedTopic.description ?? displayTopic.description,
            heatValue: detailedTopic.heatValue,
            rank: detailedTopic.rank,
            link: detailedTopic.link ?? displayTopic.link,
            tags: detailedTopic.tags.isEmpty ? displayTopic.tags : detailedTopic.tags,
            fetchedAt: detailedTopic.fetchedAt,
            rankChange: detailedTopic.rankChange,
            heatHistory: detailedTopic.heatHistory.isEmpty ? displayTopic.heatHistory : detailedTopic.heatHistory,
            summary: detailedTopic.summary.isEmpty ? displayTopic.summary : detailedTopic.summary,
            isFavorite: detailedTopic.isFavorite,
            content: detailedTopic.content ?? displayTopic.content,
            imageURLs: detailedTopic.imageURLs.isEmpty ? displayTopic.imageURLs : detailedTopic.imageURLs,
            comments: detailedTopic.comments.isEmpty ? displayTopic.comments : detailedTopic.comments
        )
        isFavorite = displayTopic.isFavorite
    }
}

// MARK: - Preview

#Preview("Topic Detail - 完整内容") {
    NavigationStack {
        TopicDetailView(topic: TrendTopicEntity(
            id: "preview-1",
            platform: .weibo,
            title: "示例热点话题标题：这是一个较长的标题用于展示多行效果",
            description: "这是一个示例话题的详细描述。",
            heatValue: 1_500_000,
            rank: 1,
            link: "https://weibo.com/example",
            tags: ["热点", "示例", "科技", "讨论"],
            fetchedAt: .now,
            rankChange: .up(3),
            summary: "AI 摘要：这是一个示例话题的核心摘要，简明扼要地说明这个话题的关键信息和背景。",
            isFavorite: false,
            content: "据最新消息，该事件已引发社会各界广泛关注。多位业内专家表示，这一现象反映了当前社会发展的某些深层趋势。",
            imageURLs: ["https://picsum.photos/seed/1/800/600", "https://picsum.photos/seed/2/800/600"],
            comments: Comment.generateMockComments(count: 5)
        ))
    }
}
