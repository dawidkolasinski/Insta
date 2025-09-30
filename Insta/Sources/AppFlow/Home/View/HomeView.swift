//
//  HomeView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct StoriesFeedAdapter: StoriesFeedProtocol {
    let stories: [any StoryProtocol]
    let startIndex: Int
}

extension StoriesFeedAdapter {
    init(viewModels: [StoryItemViewModel], startIndex: Int = 0) {
        let mapped: [any StoryProtocol] = viewModels.map { vm in
            AnyStory(
                id: vm.story.id,
                user: AnyStoryUser(name: vm.story.user.name, avatarURL: vm.story.user.avatarURL),
                items: vm.story.items.map { AnyStoryItem(id: $0.id, imageURL: $0.imageURL) }
            )
        }
        let safeIndex = min(max(0, startIndex), max(0, mapped.count - 1))
        self.init(stories: mapped, startIndex: safeIndex)
    }
}

struct HomeView<ViewModel: HomeViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel
    @State private var selectedIndex: Int? = nil
    @State private var showStories: Bool = false
    @State private var dismissProgress: CGFloat = 0
    @State private var navHidden: Bool = false
    @State private var lastOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            NavigationBarView(title: "DK's Insta")
                .offset(y: navHidden ? -48 : 0)
                .animation(.easeInOut(duration: 0.2), value: navHidden)
                .zIndex(1)

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
                .transition(.opacity)
                .zIndex(2)
            }

            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    Color.clear.frame(height: 48)
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
                    FeedListView()
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
