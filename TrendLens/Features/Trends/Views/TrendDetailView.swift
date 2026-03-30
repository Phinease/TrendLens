//
//  TrendDetailView.swift
//  TrendLens
//

import SwiftUI
import Charts

/// 趋势详情页 - 完整曲线 + 关联话题
struct TrendDetailView: View {

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Properties

    let keyword: TrendKeywordEntity
    let viewModel: TrendsViewModel
    @Binding var navigationPath: NavigationPath

    // MARK: - State

    @State private var linkedTopics: [TrendTopicEntity] = []
    @State private var isLoadingTopics = false

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                headerSection
                statsSection

                if keyword.trendPoints.count >= 2 {
                    curveSection
                }

                linkedTopicsSection

                Spacer().frame(height: 40)
            }
            .padding(DesignSystem.Spacing.md)
        }
        .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
        .navigationTitle("趋势详情")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .task {
            await loadLinkedTopics()
        }
    }
}

// MARK: - Subviews

private extension TrendDetailView {

    var headerSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(keyword.keyword)
                .font(.title2.weight(.bold))
                .foregroundStyle(.primary)

            HStack(spacing: DesignSystem.Spacing.md) {
                HStack(spacing: 4) {
                    Image(systemName: keyword.trendDirection.icon)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(directionColor)

                    Text("\(keyword.latestTrendValue)")
                        .font(.title3.weight(.semibold).monospaced())
                        .foregroundStyle(directionColor)
                }

                Label("Google Trends", systemImage: "waveform.path.ecg")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let queried = keyword.lastQueriedAt {
                    Text(queried, format: .relative(presentation: .named))
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
        }
    }

    var statsSection: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            statItem(title: "数据点", value: "\(keyword.trendPoints.count)")
            statItem(title: "关联话题", value: "\(linkedTopics.isEmpty ? keyword.linkedTopicCount : linkedTopics.count)")
            statItem(title: "命中率", value: String(format: "%.0f%%", keyword.queryHitRate * 100))
        }
        .padding(DesignSystem.Spacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: DesignSystem.CornerRadius.medium))
    }

    func statItem(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.headline.monospaced())
                .foregroundStyle(.primary)
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    var curveSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text("7 天趋势")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Chart(keyword.trendPoints.sorted { $0.timestamp < $1.timestamp }) { point in
                AreaMark(
                    x: .value("时间", point.timestamp),
                    y: .value("趋势", point.heatValue)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.3), Color.orange.opacity(0.05)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("时间", point.timestamp),
                    y: .value("趋势", point.heatValue)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(Color.orange)
                .lineStyle(StrokeStyle(lineWidth: 2))
            }
            .chartYScale(domain: 0...100)
            .chartYAxis {
                AxisMarks(values: [0, 25, 50, 75, 100]) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(.secondary.opacity(0.3))
                    AxisValueLabel {
                        if let v = value.as(Int.self) {
                            Text("\(v)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(.secondary.opacity(0.3))
                    AxisValueLabel(format: .dateTime.month(.abbreviated).day().hour())
                        .foregroundStyle(.secondary)
                        .font(.caption2)
                }
            }
            .frame(height: 220)
        }
    }

    var linkedTopicsSection: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Label("关联话题", systemImage: "newspaper")
                    .font(.callout.weight(.semibold))
                    .foregroundStyle(.primary)

                Spacer()

                if !linkedTopics.isEmpty {
                    Text("\(linkedTopics.count) 个")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if isLoadingTopics {
                LoadingView(message: "加载关联话题...")
            } else if linkedTopics.isEmpty {
                ContentUnavailableView {
                    Label("暂无关联话题", systemImage: "tray")
                } description: {
                    Text("该关键词暂未关联到话题")
                }
                .frame(height: 150)
            } else {
                LazyVStack(spacing: DesignSystem.Spacing.sm) {
                    ForEach(linkedTopics) { topic in
                        Button {
                            navigationPath.append(TrendsNavigationDestination.topicDetail(topic))
                        } label: {
                            LinkedTopicRow(topic: topic)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var directionColor: Color {
        switch keyword.trendDirection {
        case .rising: .green
        case .falling: .red
        case .stable: .secondary
        }
    }
}

// MARK: - Actions

private extension TrendDetailView {
    func loadLinkedTopics() async {
        isLoadingTopics = true
        linkedTopics = await viewModel.fetchLinkedTopics(for: keyword.id)
        isLoadingTopics = false
    }
}

// MARK: - Linked Topic Row

struct LinkedTopicRow: View {

    let topic: TrendTopicEntity

    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            HStack(alignment: .top) {
                Text(topic.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(2)

                Spacer()

                Text(topic.heatValue.formattedHeat)
                    .font(.caption.weight(.semibold).monospaced())
                    .foregroundStyle(DesignSystem.HeatSpectrum.color(for: topic.heatValue))
            }

            HStack(spacing: DesignSystem.Spacing.sm) {
                PlatformIcon(platform: topic.platform)

                Text(topic.platform.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("·")
                    .foregroundStyle(.tertiary)

                Text("排名 #\(topic.rank)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .glassEffect(.regular, in: .rect(cornerRadius: DesignSystem.CornerRadius.medium))
    }
}
