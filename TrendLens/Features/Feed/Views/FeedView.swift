//
//  FeedView.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// Feed 页面 - 全平台热榜聚合
struct FeedView: View {
    @State private var viewModel = DependencyContainer.shared.makeFeedViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("全平台热榜")
                        .font(DesignSystem.Typography.title)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, DesignSystem.Spacing.md)

                    // Placeholder content
                    ForEach(0..<5) { index in
                        placeholderCard(index: index)
                    }
                }
                .padding(.vertical, DesignSystem.Spacing.md)
            }
            .navigationTitle("热榜")
#if os(iOS)
            .background(Color(uiColor: .systemGroupedBackground))
#else
            .background(Color(nsColor: .windowBackgroundColor))
#endif
        }
    }

    @ViewBuilder
    private func placeholderCard(index: Int) -> some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            HStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 40, height: 40)

                VStack(alignment: .leading, spacing: 4) {
                    Text("热点话题 \(index + 1)")
                        .font(DesignSystem.Typography.body)
                        .fontWeight(.semibold)

                    Text("微博 · 1小时前")
                        .font(DesignSystem.Typography.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DesignSystem.Spacing.md)
        .cardStyle()
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

#Preview {
    FeedView()
}
