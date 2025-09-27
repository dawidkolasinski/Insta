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
        .task { await viewModel.loadInitial() }
        .fullScreenCover(item: $selectedStory, onDismiss: { viewModel.refreshSeen() }) { story in
            StoryPlayerView(
                story: story,
                startAt: 0,
                onPrevUser: { current in
                    let stories = viewModel.stories.map { $0.story }
                    guard let idx = stories.firstIndex(where: { $0.id == current.id }) else { return nil }
                    return idx > 0 ? stories[idx - 1] : nil
                },
                onNextUser: { current in
                    let stories = viewModel.stories.map { $0.story }
                    guard let idx = stories.firstIndex(where: { $0.id == current.id }) else { return nil }
                    return idx < stories.count - 1 ? stories[idx + 1] : nil
                }
            )
        }
        .onChange(of: selectedStory == nil) { becameNil in
            if becameNil { viewModel.refreshSeen() }
        }
    }

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
}
