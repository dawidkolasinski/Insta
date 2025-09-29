//
//  HomeView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

private struct StoriesFeedAdapter: StoriesFeedProtocol {
    let stories: [any StoryProtocol]
    let startIndex: Int
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
        .overlay(
            ZStack {
                if showStories {
                    // Solid black base behind everything (fixes missing backdrop)
                    Color.black.opacity(dismissProgress == 0 ? 1 : 0)
                        .ignoresSafeArea()
                        .zIndex(0)

                    // Dimmer reacting to interactive dismiss, with darker-at-rest and faster-clearing curve
                    Color.black.opacity(max(0, min(1, 0.75 * (1 - sqrt(Double(dismissProgress))))))
                        .ignoresSafeArea()
                        .zIndex(1)

                    let index = selectedIndex ?? 0
                    let mapped: [any StoryProtocol] = viewModel.stories.map { s in
                        AnyStory(
                            id: s.story.id,
                            user: AnyStoryUser(name: s.story.user.name, avatarURL: s.story.user.avatarURL),
                            items: s.story.items.map { AnyStoryItem(id: $0.id, imageURL: $0.imageURL) }
                        )
                    }
                    let safeIndex = min(max(0, index), max(0, mapped.count - 1))
                    let feed = StoriesFeedAdapter(stories: mapped, startIndex: safeIndex)

                    StoriesContainerView(
                        feed: feed,
                        onDismiss: {
                            // zamknij bez dodatkowej animacji usuwania (już dokończona pod palcem)
                            withTransaction(Transaction(animation: nil)) { showStories = false }
                            viewModel.refreshSeen()
                        },
                        dismissProgress: $dismissProgress
                    )
                    .transition(.storiesDeck) // only on show
                    .zIndex(2)
                }
            }
        )
    }

    init(viewModel: ViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
}
