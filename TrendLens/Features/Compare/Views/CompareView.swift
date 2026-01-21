//
//  CompareView.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// Compare 页面 - 平台对比分析
struct CompareView: View {
    @State private var viewModel = DependencyContainer.shared.makeCompareViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                Text("平台对比")
                    .font(DesignSystem.Typography.largeTitle)

                Text("发现不同平台的热点差异")
                    .font(DesignSystem.Typography.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 80))
                    .foregroundStyle(.secondary.opacity(0.3))

                Text("即将推出")
                    .font(DesignSystem.Typography.headline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .navigationTitle("对比")
            .padding()
        }
    }
}

#Preview {
    CompareView()
}
