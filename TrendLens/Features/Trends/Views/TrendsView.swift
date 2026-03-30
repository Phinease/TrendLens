//
//  TrendsView.swift
//  TrendLens
//

import SwiftUI

/// 导航目的地类型
enum TrendsNavigationDestination: Hashable {
    case trendDetail(TrendKeywordEntity)
    case topicDetail(TrendTopicEntity)
}

/// 趋势页面 - Google Trends 时序数据展示
struct TrendsView: View {

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - State

    @State private var viewModel = DependencyContainer.shared.makeTrendsViewModel()
    @State private var navigationPath = NavigationPath()

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack(spacing: 0) {
                sortPicker
                contentView
            }
            .navigationTitle("趋势")
#if os(iOS)
            .navigationBarTitleDisplayMode(.large)
#endif
            .background(DesignSystem.Neutral.backgroundPrimary(colorScheme))
            .navigationDestination(for: TrendsNavigationDestination.self) { destination in
                switch destination {
                case .trendDetail(let keyword):
                    TrendDetailView(keyword: keyword, viewModel: viewModel, navigationPath: $navigationPath)
                case .topicDetail(let topic):
                    TopicDetailView(topic: topic)
                }
            }
            .task {
                if viewModel.keywords.isEmpty {
                    await viewModel.fetchKeywords()
                }
            }
        }
    }
}

// MARK: - Subviews

private extension TrendsView {

    var sortPicker: some View {
        HStack {
            Spacer()
            Picker("排序", selection: $viewModel.sortOrder) {
                ForEach(TrendSortOrder.allCases) { order in
                    Text(order.displayName).tag(order)
                }
            }
            .pickerStyle(.menu)
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
        .padding(.vertical, DesignSystem.Spacing.xs)
        .onChange(of: viewModel.sortOrder) { _, _ in
            Task { await viewModel.fetchKeywords() }
        }
    }

    @ViewBuilder
    var contentView: some View {
        if viewModel.isLoading && viewModel.keywords.isEmpty {
            SkeletonList(count: 8)
                .padding(.top, DesignSystem.Spacing.sm)
        } else if let error = viewModel.error, viewModel.keywords.isEmpty {
            ErrorView(
                error: error,
                retryAction: { Task { await viewModel.fetchKeywords() } }
            )
        } else if viewModel.keywords.isEmpty {
            ContentUnavailableView {
                Label("暂无趋势数据", systemImage: "chart.line.uptrend.xyaxis")
            } description: {
                Text("趋势数据采集中，请稍后再试")
            }
        } else {
            keywordList
        }
    }

    var keywordList: some View {
        ScrollView {
            LazyVStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(viewModel.keywords) { keyword in
                    Button {
                        navigationPath.append(TrendsNavigationDestination.trendDetail(keyword))
                    } label: {
                        TrendKeywordCard(keyword: keyword)
                    }
                    .buttonStyle(.plain)
                }

                Spacer().frame(height: 80)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.top, DesignSystem.Spacing.sm)
        }
        .refreshable {
            await viewModel.fetchKeywords()
        }
    }
}

// MARK: - Preview

#Preview("Trends View") {
    TrendsView()
}
