//
//  MiniTrendLine.swift
//  TrendLens
//
//  Created by Claude on 1/23/26.
//  Redesigned for Ethereal Insight v3.0 - 自适应、优美的热度趋势曲线
//

import SwiftUI

/// 迷你热度趋势线
/// 用于卡片内嵌显示热度变化曲线
///
/// **设计原则：**
/// - 自适应父容器大小（通过 GeometryReader）
/// - 平滑贝塞尔曲线渲染
/// - 颜色基于热度光谱（Ethereal Insight v3.0）
/// - 轻量级背景（可选）
///
/// **使用示例：**
/// ```swift
/// MiniTrendLine(dataPoints: topic.heatHistory)
///     .frame(width: 80, height: 32) // 在使用处指定大小
/// ```
struct MiniTrendLine: View {

    // MARK: - Properties

    let dataPoints: [HeatDataPoint]

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Initialization

    init(dataPoints: [HeatDataPoint]) {
        self.dataPoints = dataPoints.sortedByTime
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            // 趋势曲线
            if sampledDataPoints.count >= 2 {
                curvePath(in: geometry.size)
                    .stroke(
                        lineGradient,
                        style: StrokeStyle(
                            lineWidth: 1.5,
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                    .shadow(
                        color: glowColor,
                        radius: glowRadius
                    )
            } else {
                // 数据不足时显示占位符
                placeholderView
            }
        }
    }

    // MARK: - Curve Path

    /// 生成平滑贝塞尔曲线路径
    private func curvePath(in size: CGSize) -> Path {
        Path { path in
            let points = sampledDataPoints
            guard points.count >= 2 else { return }

            // 数据归一化
            let maxHeat = points.maxHeat ?? 1
            let minHeat = points.minHeat ?? 0
            let heatRange = max(maxHeat - minHeat, 1)
            let stepX = size.width / CGFloat(points.count - 1)

            // 转换为屏幕坐标
            func screenPoint(for index: Int) -> CGPoint {
                let point = points[index]
                let x = CGFloat(index) * stepX
                let normalizedY = CGFloat(point.heatValue - minHeat) / CGFloat(heatRange)
                let y = size.height * (1 - normalizedY)
                return CGPoint(x: x, y: y)
            }

            // 起点
            let startPoint = screenPoint(for: 0)
            path.move(to: startPoint)

            // 如果只有两个点，直接连线
            if points.count == 2 {
                path.addLine(to: screenPoint(for: 1))
                return
            }

            // 使用平滑曲线（简化的 Catmull-Rom）
            for i in 0..<(points.count - 1) {
                let current = screenPoint(for: i)
                let next = screenPoint(for: i + 1)

                // 计算控制点（简化算法，平滑但不过度弯曲）
                let controlPointX = (current.x + next.x) / 2
                let controlPoint1 = CGPoint(x: controlPointX, y: current.y)
                let controlPoint2 = CGPoint(x: controlPointX, y: next.y)

                // 使用三次贝塞尔曲线
                path.addCurve(to: next, control1: controlPoint1, control2: controlPoint2)
            }
        }
    }

    // MARK: - Styling

    private var lineGradient: LinearGradient {
        let startColor = lineColor.opacity(0.6)
        let endColor = lineColor

        return LinearGradient(
            colors: [startColor, endColor],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var lineColor: Color {
        guard !dataPoints.isEmpty else { return .gray }
        let currentHeat = dataPoints.last?.heatValue ?? 0
        return DesignSystem.HeatSpectrum.color(for: currentHeat)
    }

    private var glowColor: Color {
        guard !dataPoints.isEmpty else { return .clear }
        let currentHeat = dataPoints.last?.heatValue ?? 0

        // 仅高热度时发光
        if DesignSystem.HeatSpectrum.needsGlow(for: currentHeat) {
            return lineColor.opacity(0.4)
        }
        return .clear
    }

    private var glowRadius: CGFloat {
        guard !dataPoints.isEmpty else { return 0 }
        let currentHeat = dataPoints.last?.heatValue ?? 0

        // 根据热度级别调整发光强度
        switch currentHeat {
        case 200_000..<500_000:
            return 2
        case 500_000..<1_000_000:
            return 3
        case 1_000_000...:
            return 4
        default:
            return 0
        }
    }

    private var placeholderView: some View {
        Rectangle()
            .fill(.tertiary.opacity(0.1))
    }

    // MARK: - Data Processing

    /// 均匀抽样数据点
    /// 如果数据点超过 12 个，均匀抽样至 12 个
    private var sampledDataPoints: [HeatDataPoint] {
        let maxPoints = 12
        guard dataPoints.count > maxPoints else { return dataPoints }

        let step = CGFloat(dataPoints.count - 1) / CGFloat(maxPoints - 1)
        return (0..<maxPoints).compactMap { i in
            let index = Int(CGFloat(i) * step)
            return index < dataPoints.count ? dataPoints[index] : nil
        }
    }
}

// MARK: - Preview

#Preview("MiniTrendLine - 自适应大小") {
    ScrollView {
        VStack(spacing: 32) {
            // 不同热度级别 - 标准卡片尺寸
            VStack(alignment: .leading, spacing: 16) {
                Text("标准卡片尺寸 (32×24pt)")
                    .font(.headline)

                HStack(spacing: 16) {
                    VStack(spacing: 8) {
                        MiniTrendLine(
                            dataPoints: generateHeatHistory(baseHeat: 300_000)
                        )
                        .frame(width: 32, height: 24)

                        Text("300k")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 8) {
                        MiniTrendLine(
                            dataPoints: generateHeatHistory(baseHeat: 600_000)
                        )
                        .frame(width: 32, height: 24)

                        Text("600k")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }

                    VStack(spacing: 8) {
                        MiniTrendLine(
                            dataPoints: generateHeatHistory(baseHeat: 1_200_000)
                        )
                        .frame(width: 32, height: 24)

                        Text("1.2M")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Divider()

            // Hero 卡片尺寸
            VStack(alignment: .leading, spacing: 16) {
                Text("Hero 卡片尺寸 (80×32pt)")
                    .font(.headline)

                HStack(spacing: 20) {
                    ForEach([300_000, 600_000, 1_200_000], id: \.self) { heat in
                        VStack(spacing: 8) {
                            MiniTrendLine(
                                dataPoints: generateHeatHistory(baseHeat: heat),
                                                            )
                            .frame(width: 80, height: 32)

                            Text(heat.formattedHeat)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Divider()

            // 自定义尺寸展示
            VStack(alignment: .leading, spacing: 16) {
                Text("自定义尺寸 - 灵活适配")
                    .font(.headline)

                VStack(spacing: 12) {
                    // 宽而扁
                    HStack {
                        Text("120×20pt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)

                        MiniTrendLine(
                            dataPoints: generateHeatHistory(baseHeat: 800_000)
                        )
                        .frame(width: 120, height: 20)
                    }

                    // 窄而高
                    HStack {
                        Text("40×40pt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)

                        MiniTrendLine(
                            dataPoints: generateHeatHistory(baseHeat: 500_000),
                                                    )
                        .frame(width: 40, height: 40)
                    }

                    // 超大
                    HStack {
                        Text("200×80pt")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .leading)

                        MiniTrendLine(
                            dataPoints: generateHeatHistory(baseHeat: 1_500_000),
                                                    )
                        .frame(width: 200, height: 80)
                    }
                }
            }

            Divider()

            // 数据点数量测试
            VStack(alignment: .leading, spacing: 16) {
                Text("不同数据点数量")
                    .font(.headline)

                VStack(spacing: 12) {
                    ForEach([2, 5, 12, 24], id: \.self) { count in
                        HStack {
                            Text("\(count) 个点")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .leading)

                            MiniTrendLine(
                                dataPoints: Array(generateHeatHistory(baseHeat: 700_000).prefix(count))
                            )
                            .frame(width: 120, height: 30)
                        }
                    }
                }
            }
        }
        .padding()
    }
}

#Preview("MiniTrendLine - 深色模式") {
    VStack(spacing: 24) {
        HStack(spacing: 20) {
            ForEach([300_000, 600_000, 1_200_000], id: \.self) { heat in
                VStack(spacing: 8) {
                    MiniTrendLine(
                        dataPoints: generateHeatHistory(baseHeat: heat),
                                            )
                    .frame(width: 80, height: 32)

                    Text(heat.formattedHeat)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    .padding()
    .preferredColorScheme(.dark)
}

// MARK: - Preview Helper

private func generateHeatHistory(baseHeat: Int) -> [HeatDataPoint] {
    let now = Date()
    let pointCount = 12

    return (0..<pointCount).map { i in
        let hoursAgo = (pointCount - 1 - i) * 1
        let timestamp = now.addingTimeInterval(TimeInterval(-hoursAgo * 3600))

        let variation = Int.random(in: -baseHeat/10...baseHeat/10)
        // 整体上升趋势
        let trendOffset = i * (baseHeat / pointCount / 3)

        let heatValue = max(1000, baseHeat + variation + trendOffset)

        return HeatDataPoint(
            timestamp: timestamp,
            heatValue: heatValue,
            rank: max(1, 10 - i / 2)
        )
    }
}
