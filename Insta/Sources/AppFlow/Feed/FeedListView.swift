import SwiftUI

struct FeedListView: View {
    let items: [StoryItemViewModel]
    let layout: FeedLayout
    let onSelect: (StoryItemViewModel) -> Void
    let onLoadMore: (StoryItemViewModel) -> Void

    var body: some View {
        switch layout {
        case .vertical:
            LazyVStack(spacing: 8) {
                if items.isEmpty {
                    ForEach(0..<5, id: \.self) { number in
                        ListFeedPlaceholderView(number: number)
                    }
                } else {
                    ForEach(items) { viewModel in
                        StoryListItemView(
                            viewModel: viewModel,
                            layout: .vertical,
                            onSelect: onSelect,
                            onLoadMore: onLoadMore
                        )
                    }
                }
            }
        case .horizontal:
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    if items.isEmpty {
                        ForEach(0..<5, id: \.self) { number in
                            ListFeedPlaceholderView(number: number)
                                .frame(width: 300)
                        }
                    } else {
                        ForEach(items) { viewModel in
                            StoryListItemView(
                                viewModel: viewModel,
                                layout: .horizontal,
                                onSelect: onSelect,
                                onLoadMore: onLoadMore
                            )
                            .frame(width: 300)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    init(
        items: [StoryItemViewModel],
        layout: FeedLayout = .vertical,
        onSelect: @escaping (StoryItemViewModel) -> Void,
        onLoadMore: @escaping (StoryItemViewModel) -> Void
    ) {
        self.items = items
        self.layout = layout
        self.onSelect = onSelect
        self.onLoadMore = onLoadMore
    }
}
