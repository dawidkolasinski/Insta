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

    var body: some View {
        let axis: Axis.Set = layout == .vertical ? .vertical : .horizontal
        return ScrollView(axis, showsIndicators: false) {
            stack(spacing: spacing) {
                ForEach(items) { viewModel in
                    StoryListItemView(
                        viewModel: viewModel,
                        layout: layout,
                        onSelect: onSelect,
                        onLoadMore: onLoadMore
                    )
                    .contentShape(Rectangle())
                }
            }
        }
        .frame(height: layout == .horizontal ? 110 : nil)
    }

    init(
        layout: StoriesLayout = .horizontal,
        items: [StoryItemViewModel],
        spacing: CGFloat = 8,
        onSelect: @escaping (StoryItemViewModel) -> Void,
        onLoadMore: @escaping (StoryItemViewModel) -> Void
    ) {
        self.layout = layout
        self.items = items
        self.spacing = spacing
        self.onSelect = onSelect
        self.onLoadMore = onLoadMore
    }

    @ViewBuilder
    private func stack<Content: View>(spacing: CGFloat, @ViewBuilder content: () -> Content) -> some View {
        if layout == .vertical {
            LazyVStack(spacing: spacing) { content() }
        } else {
            LazyHStack(spacing: spacing) { content() }
                .padding(.horizontal)
        }
    }
}
