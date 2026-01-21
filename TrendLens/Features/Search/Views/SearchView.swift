//
//  SearchView.swift
//  TrendLens
//
//  Created by Claude on 1/21/26.
//

import SwiftUI

/// Search 页面 - 搜索热点话题
struct SearchView: View {
    @State private var viewModel = DependencyContainer.shared.makeSearchViewModel()
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: DesignSystem.Spacing.lg) {
                // 搜索框
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)

                    TextField("搜索热点话题", text: $searchText)
                        .textFieldStyle(.plain)
                }
                .padding(DesignSystem.Spacing.sm)
                .background(DesignSystem.Material.regular)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.CornerRadius.small))
                .padding(.horizontal, DesignSystem.Spacing.md)

                if searchText.isEmpty {
                    Spacer()

                    Image(systemName: "text.magnifyingglass")
                        .font(.system(size: 80))
                        .foregroundStyle(.secondary.opacity(0.3))

                    Text("搜索全平台热点")
                        .font(DesignSystem.Typography.headline)
                        .foregroundStyle(.secondary)

                    Spacer()
                } else {
                    ScrollView {
                        Text("搜索结果即将推出")
                            .font(DesignSystem.Typography.body)
                            .foregroundStyle(.secondary)
                            .padding()
                    }
                }
            }
            .navigationTitle("搜索")
            .padding(.top, DesignSystem.Spacing.sm)
        }
    }
}

#Preview {
    SearchView()
}
