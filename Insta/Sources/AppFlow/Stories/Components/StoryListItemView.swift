//
//  StoryListItemView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct StoryListItemView: View {
    @ObservedObject var viewModel: StoryItemViewModel
    let layout: StoriesLayout
    let onSelect: (StoryItemViewModel) -> Void
    let onLoadMore: (StoryItemViewModel) -> Void

    var body: some View {
        Group {
            switch layout {
            case .vertical:
                StoryRowView(story: viewModel.story)
                    .onTapGesture { onSelect(viewModel) }
                    .onAppear {
                        viewModel.markDisplayed()
                        onLoadMore(viewModel)
                    }
            case .horizontal:
                StoryAvatarView(
                    url: viewModel.story.user.avatarURL,
                    seen: viewModel.isSeen,
                    displayedPlace: .storyFeed
                )
                .onTapGesture { onSelect(viewModel) }
                .onAppear { onLoadMore(viewModel) }
            }
        }
    }

    init(
        viewModel: StoryItemViewModel,
        layout: StoriesLayout,
        onSelect: @escaping (StoryItemViewModel) -> Void,
        onLoadMore: @escaping (StoryItemViewModel) -> Void
    ) {
        self.viewModel = viewModel
        self.layout = layout
        self.onSelect = onSelect
        self.onLoadMore = onLoadMore
    }
}

