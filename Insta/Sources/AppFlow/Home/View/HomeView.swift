//
//  HomeView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct HomeView<ViewModel: HomeViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel
    @State private var selectedIndex: Int? = nil
    @State private var showStories: Bool = false
    @State private var dismissProgress: CGFloat = 0

    private let headerHeight: CGFloat = 48
    private let fadeAmount: CGFloat = 0.10
    private let smoothingDown: CGFloat = 0.28
    private let smoothingUp: CGFloat = 0.38

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {
                StoriesListView(
                    layout: .horizontal,
                    items: viewModel.stories,
                    onSelect: { storyVM in
                        guard viewModel.isOnline else { return }
                        if let index = viewModel.stories.firstIndex(where: { $0.story.id == storyVM.story.id }) {
                            selectedIndex = index
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                showStories = true
                            }
                        }
                    },
                    onLoadMore: { current in
                        Task { await viewModel.loadMoreIfNeeded(current: current) }
                    }
                )
                .padding(.vertical, 8)

                FeedListView(
                    items: viewModel.stories,
                    layout: .vertical,
                    onSelect: { storyVM in
                        guard viewModel.isOnline else { return }
                        if let index = viewModel.stories.firstIndex(where: { $0.story.id == storyVM.story.id }) {
                            selectedIndex = index
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.9)) {
                                showStories = true
                            }
                        }
                    },
                    onLoadMore: { current in
                        Task { await viewModel.loadMoreIfNeeded(current: current) }
                    }
                )
            }
        }
        .collapsibleHeader(
            height: headerHeight,
            fadeAmount: fadeAmount,
            smoothingDown: smoothingDown,
            smoothingUp: smoothingUp
        ) { progress in
            ZStack(alignment: .top) {
                NavigationBarView(title: "DK's Insta", progress: progress)
                if !viewModel.isOnline {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi.exclamationmark")
                        Text("No internet connection - showing loaded data")
                    }
                    .font(.subheadline)
                    .padding(10)
                    .background(Color.red.opacity(0.9), in: Capsule())
                    .foregroundColor(.white)
                    .padding(.top, 56)
                }
            }
        }
        .task { await viewModel.loadInitial() }
        .storiesPresenter(
            isPresented: $showStories,
            feed: StoriesFeedAdapter(viewModels: viewModel.stories, startIndex: selectedIndex ?? 0),
            dismissProgress: $dismissProgress,
            config: .init()
        )
    }

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
}
