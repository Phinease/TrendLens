//
//  HeatCurveView.swift
//  TrendLens
//
//  Created by Claude on 1/22/26.
//

import SwiftUI
import Charts

/// 热度曲线视图
/// 使用 Swift Charts 绘制热度变化趋势
struct HeatCurveView: View {

    // MARK: - Properties

    let dataPoints: [HeatDataPoint]
    let platform: Platform
    let style: CurveStyle

    @State private var selectedPoint: HeatDataPoint?
    @State private var animationProgress: CGFloat = 0

    enum CurveStyle {
        /// 迷你版 - 卡片内嵌 (80 × 36pt)
        case mini
        /// 完整版 - 详情页 (全宽 × 200pt)
        case full
    }

    // MARK: - Initialization

    init(
        dataPoints: [HeatDataPoint],
        platform: Platform,
        style: CurveStyle = .full
    ) {
        self.dataPoints = dataPoints
        self.platform = platform
        self.style = style
    }

    // MARK: - Body

    var body: some View {
        Group {
            if dataPoints.count < 2 {
                insufficientDataView
            } else {
                chartView
            }
        }
        .onAppear {
            withAnimation(DesignSystem.Animation.curveDrawing) {
                animationProgress = 1.0
            }
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    private var chartView: some View {
        switch style {
        case .mini:
            miniChart
        case .full:
            fullChart
        }
    }

    private var miniChart: some View {
        Chart(sortedDataPoints) { point in
            LineMark(
                x: .value("时间", point.timestamp),
                y: .value("热度", point.heatValue)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(platformGradient)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(width: 80, height: 36)
        .shadow(
            color: platformColor.opacity(0.5),
            radius: 3
        )
    }

    private var fullChart: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            // 标题和选中信息
            headerView

            // 图表
            Chart(sortedDataPoints) { point in
                // 面积填充
                AreaMark(
                    x: .value("时间", point.timestamp),
                    y: .value("热度", point.heatValue)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(areaGradient)

                // 曲线
                LineMark(
                    x: .value("时间", point.timestamp),
                    y: .value("热度", point.heatValue)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(platformGradient)
                .lineStyle(StrokeStyle(lineWidth: 2))

                // 数据点
                if let selected = selectedPoint, selected.id == point.id {
                    PointMark(
                        x: .value("时间", point.timestamp),
                        y: .value("热度", point.heatValue)
                    )
                    .foregroundStyle(platformColor)
                    .symbolSize(80)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(.secondary.opacity(0.3))
                    AxisValueLabel(format: .dateTime.hour().minute())
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                    AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                        .foregroundStyle(.secondary.opacity(0.3))
                    AxisValueLabel {
                        if let intValue = value.as(Int.self) {
                            Text(intValue.formattedHeat)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    handleDrag(at: value.location, proxy: proxy, geometry: geometry)
                                }
                                .onEnded { _ in
                                    selectedPoint = nil
                                }
                        )
                }
            }
            .frame(height: 200)
            .padding(.horizontal, DesignSystem.Spacing.xs)

            // 趋势信息
            trendInfoView
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            Text("热度趋势")
                .font(DesignSystem.Typography.headline)

            Spacer()

            if let point = selectedPoint {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(point.heatValue.formattedHeat)
                        .font(DesignSystem.Typography.monoLarge)
                        .foregroundStyle(platformColor)

                    Text(point.timestamp, style: .time)
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var trendInfoView: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            if let maxPoint = sortedDataPoints.max(by: { $0.heatValue < $1.heatValue }) {
                trendStat(
                    title: "峰值",
                    value: maxPoint.heatValue.formattedHeat,
                    subtitle: maxPoint.timestamp.formatted(date: .omitted, time: .shortened)
                )
            }

            Divider().frame(height: 30)

            if let trend = sortedDataPoints.trend {
                trendStat(
                    title: "变化",
                    value: (trend >= 0 ? "+" : "") + trend.formattedHeat,
                    subtitle: trend >= 0 ? "上升" : "下降",
                    color: trend >= 0 ? .green : .red
                )
            }

            Divider().frame(height: 30)

            trendStat(
                title: "数据点",
                value: "\(sortedDataPoints.count)",
                subtitle: "采样"
            )
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
    }

    private func trendStat(
        title: String,
        value: String,
        subtitle: String,
        color: Color = .primary
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(DesignSystem.Typography.footnote)
                .foregroundStyle(.secondary)

            Text(value)
                .font(DesignSystem.Typography.mono)
                .foregroundStyle(color)

            Text(subtitle)
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
    }

    private var insufficientDataView: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("数据收集中...")
                .font(DesignSystem.Typography.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .frame(height: style == .mini ? 36 : 200)
    }

    // MARK: - Helpers

    private var sortedDataPoints: [HeatDataPoint] {
        dataPoints.sortedByTime
    }

    private var platformColor: Color {
        DesignSystem.PlatformColor.color(for: platform)
    }

    private var platformGradient: LinearGradient {
        DesignSystem.PlatformGradient.gradient(for: platform)
    }

    private var areaGradient: LinearGradient {
        LinearGradient(
            colors: [
                platformColor.opacity(0.3),
                platformColor.opacity(0.05)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private func handleDrag(
        at location: CGPoint,
        proxy: ChartProxy,
        geometry: GeometryProxy
    ) {
        guard let timestamp: Date = proxy.value(atX: location.x) else { return }

        // 找到最近的数据点
        let closest = sortedDataPoints.min { point1, point2 in
            abs(point1.timestamp.timeIntervalSince(timestamp)) <
            abs(point2.timestamp.timeIntervalSince(timestamp))
        }

        selectedPoint = closest
    }
}

// MARK: - Preview

#Preview("Heat Curve - Full") {
    VStack {
        HeatCurveView(
            dataPoints: previewHeatHistory(),
            platform: .weibo,
            style: .full
        )
        .padding()
    }
}

#Preview("Heat Curve - Mini") {
    HStack(spacing: 20) {
        ForEach(Platform.allCases) { platform in
            VStack {
                HeatCurveView(
                    dataPoints: previewHeatHistory(),
                    platform: platform,
                    style: .mini
                )
                Text(platform.displayName)
                    .font(.caption)
            }
        }
    }
    .padding()
}

#Preview("Heat Curve - Insufficient Data") {
    HeatCurveView(
        dataPoints: [HeatDataPoint(timestamp: Date(), heatValue: 50000)],
        platform: .bilibili,
        style: .full
    )
    .padding()
}

// Preview helper
private func previewHeatHistory() -> [HeatDataPoint] {
    let now = Date()
    let baseHeat = 100_000

    return (0..<12).map { i in
        let variation = Int.random(in: -30_000...50_000)
        let trend = i * 5_000 // 整体上升趋势
        return HeatDataPoint(
            timestamp: now.addingTimeInterval(TimeInterval(-i * 1800)), // 30分钟间隔
            heatValue: baseHeat + variation + trend,
            rank: max(1, 10 - i / 2)
        )
    }.reversed()
}
