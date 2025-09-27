//
//  HomeView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeView<ViewModel: HomeViewModelProtocol>: View {
    @StateObject private var viewModel: ViewModel
    @State private var selectedStory: Story?
    @State private var navHidden: Bool = false
    @State private var lastOffset: CGFloat = 0

    var body: some View {
        ZStack(alignment: .top) {
            NavigationBarView(title: "DK's Insta")
                .offset(y: navHidden ? -48 : 0)
                .animation(.easeInOut(duration: 0.2), value: navHidden)
                .zIndex(1)
            VStack(spacing: 0) {
                ScrollView(.vertical) {
                    Color.clear.frame(height: 48)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: ScrollOffsetKey.self,
                                    value: proxy.frame(in: .named("feedScroll")).minY
                                )
                            }
                        )
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
            }
        }
        .onPreferenceChange(ScrollOffsetKey.self) { newOffset in
            let delta = newOffset - lastOffset
            if delta < -1 { navHidden = true }
            else if delta > 1 { navHidden = false }
            lastOffset = newOffset
        }
        .task { await viewModel.loadInitial() }
        .fullScreenCover(item: $selectedStory) { story in
            StoryPlayerView(
                story: story,
                startAt: 0,
                onPrevUser: {
                    let stories = viewModel.stories.map { $0.story }
                    guard let idx = stories.firstIndex(where: { $0.id == story.id }) else { return nil }
                    return idx > 0 ? stories[idx - 1] : nil
                },
                onNextUser: {
                    let stories = viewModel.stories.map { $0.story }
                    guard let idx = stories.firstIndex(where: { $0.id == story.id }) else { return nil }
                    return idx < stories.count - 1 ? stories[idx + 1] : nil
                }
            )
        }
    }

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
}
