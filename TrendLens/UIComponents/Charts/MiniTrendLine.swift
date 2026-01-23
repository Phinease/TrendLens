//
//  MiniTrendLine.swift
//  TrendLens
//
//  Created by Claude on 1/23/26.
//

import SwiftUI
import Charts

/// 迷你热度趋势线
/// 用于卡片内嵌显示热度变化曲线
struct MiniTrendLine: View {

    // MARK: - Properties

    let dataPoints: [HeatDataPoint]
    let size: MiniTrendLineSize
    @Environment(\.colorScheme) private var colorScheme

    enum MiniTrendLineSize {
        /// 英雄卡片 80×32pt
        case hero
        /// 标准卡片 32×24pt
        case standard
    }

    // MARK: - Initialization

    init(
        dataPoints: [HeatDataPoint],
        size: MiniTrendLineSize = .standard
    ) {
        self.dataPoints = dataPoints.sortedByTime
        self.size = size
    }

    // MARK: - Body

    var body: some View {
        Group {
            if dataPoints.count >= 3 {
                chartView
            } else if dataPoints.count >= 2 {
                // 两个点的情况，显示简单连线
                simpleLineChart
            } else {
                // 数据不足
                placeholderView
            }
        }
    }

    // MARK: - Chart View

    @ViewBuilder
    private var chartView: some View {
        let sampledData = sampledDataPoints
        Chart(sampledData) { point in
            LineMark(
                x: .value("时间", point.timestamp),
                y: .value("热度", point.heatValue)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(lineColor)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(
            width: frameWidth,
            height: frameHeight
        )
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    @ViewBuilder
    private var simpleLineChart: some View {
        Chart(dataPoints) { point in
            LineMark(
                x: .value("时间", point.timestamp),
                y: .value("热度", point.heatValue)
            )
            .foregroundStyle(lineColor)
            .lineStyle(StrokeStyle(lineWidth: 1.5))
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .frame(
            width: frameWidth,
            height: frameHeight
        )
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 4))
    }

    private var placeholderView: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(backgroundColor)
            .frame(
                width: frameWidth,
                height: frameHeight
            )
    }

    // MARK: - Computed Properties

    private var frameWidth: CGFloat {
        switch size {
        case .hero: return 80
        case .standard: return 32
        }
    }

    private var frameHeight: CGFloat {
        switch size {
        case .hero: return 32
        case .standard: return 24
        }
    }

    private var lineColor: Color {
        guard !dataPoints.isEmpty else { return .gray }
        let currentHeat = dataPoints.last?.heatValue ?? 0
        return DesignSystem.HeatSpectrum.color(for: currentHeat)
    }

    private var backgroundColor: Color {
        colorScheme == .dark
            ? Color(hex: "1A1F2E").opacity(0.5)
            : Color(hex: "F3F4F6").opacity(0.5)
    }

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

#Preview("MiniTrendLine - Standard") {
    VStack(spacing: 24) {
        // 不同热度级别
        VStack(alignment: .leading, spacing: 12) {
            Text("低热度 (300k)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(Platform.allCases) { platform in
                    MiniTrendLine(
                        dataPoints: generateHeatHistory(baseHeat: 300_000),
                        size: .standard
                    )
                }
            }
        }

        Divider()

        VStack(alignment: .leading, spacing: 12) {
            Text("中热度 (600k)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(Platform.allCases) { platform in
                    MiniTrendLine(
                        dataPoints: generateHeatHistory(baseHeat: 600_000),
                        size: .standard
                    )
                }
            }
        }

        Divider()

        VStack(alignment: .leading, spacing: 12) {
            Text("高热度 (1.2M)")
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ForEach(Platform.allCases) { platform in
                    MiniTrendLine(
                        dataPoints: generateHeatHistory(baseHeat: 1_200_000),
                        size: .standard
                    )
                }
            }
        }
    }
    .padding()
}

#Preview("MiniTrendLine - Hero") {
    VStack(spacing: 20) {
        HStack(spacing: 20) {
            ForEach([300_000, 600_000, 1_200_000], id: \.self) { heat in
                VStack(spacing: 8) {
                    MiniTrendLine(
                        dataPoints: generateHeatHistory(baseHeat: heat),
                        size: .hero
                    )
                    Text(heat.formattedHeat)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    .padding()
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
