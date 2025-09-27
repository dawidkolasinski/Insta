//
//  HomeView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct HomeView<ViewModel: HomeViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel
    @State private var selectedStory: Story?

    var body: some View {
        VStack (spacing: 0) {
            NavigationBarView(title: "Home")
            StoriesListView(
                layout: .horizontal,
                items: viewModel.stories,
                onSelect: { storyVM in
                    selectedStory = storyVM.story
                },
                onLoadMore: { vm in
                    Task { await viewModel.loadMoreIfNeeded(current: vm) }
                }
            )
            .padding(.vertical, 8)

            FeedListView()
        }
        .task { await viewModel.loadInitial() }
        .fullScreenCover(item: $selectedStory) { story in
            StoryPlayerView(story: story)
        }
    }

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
}
