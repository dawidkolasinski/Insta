//
//  StoriesListView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct StoriesListView: View {
    let layout: StoriesLayout
    let items: [StoryItemViewModel]
    let spacing: CGFloat
    let onSelect: (StoryItemViewModel) -> Void
    let onLoadMore: (StoryItemViewModel) -> Void

    init(
        layout: StoriesLayout = .horizontal,
        items: [StoryItemViewModel],
        spacing: CGFloat = 12,
        onSelect: @escaping (StoryItemViewModel) -> Void,
        onLoadMore: @escaping (StoryItemViewModel) -> Void
    ) {
        self.layout = layout
        self.items = items
        self.spacing = spacing
        self.onSelect = onSelect
        self.onLoadMore = onLoadMore
    }

    var body: some View {
        let axis: Axis.Set = (layout == .vertical) ? .vertical : .horizontal
        return ScrollView(axis, showsIndicators: false) {
            if layout == .vertical {
                LazyVStack(spacing: spacing) {
                    ForEach(items) { viewModel in
                        StoryListItemView(
                            viewModel: viewModel,
                            layout: .vertical,
                            spacing: spacing,
                            onSelect: onSelect,
                            onLoadMore: onLoadMore
                        )
                        .contentShape(Rectangle())
                    }
                }
            } else {
                LazyHStack(spacing: spacing) {
                    ForEach(items) { viewModel in
                        StoryListItemView(
                            viewModel: viewModel,
                            layout: .horizontal,
                            spacing: spacing,
                            onSelect: onSelect,
                            onLoadMore: onLoadMore
                        )
                        .contentShape(Rectangle())
                    }
                }
                .padding(.horizontal)
            }
        }
        .frame(height: layout == .horizontal ? 110 : nil)
    }
}

struct StoryListItemView: View {
    @ObservedObject var viewModel: StoryItemViewModel
    let layout: StoriesLayout
    let spacing: CGFloat
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
                    seen: viewModel.isSeen
                )
                .onTapGesture { onSelect(viewModel) }
                .onAppear { onLoadMore(viewModel) }
            }
        }
    }

    init(
        viewModel: StoryItemViewModel,
        layout: StoriesLayout,
        spacing: CGFloat = 12,
        onSelect: @escaping (StoryItemViewModel) -> Void,
        onLoadMore: @escaping (StoryItemViewModel) -> Void
    ) {
        self.viewModel = viewModel
        self.layout = layout
        self.spacing = spacing
        self.onSelect = onSelect
        self.onLoadMore = onLoadMore
    }
}
