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
                VStack(spacing: 6) {
                    StoryAvatarView(
                        url: viewModel.story.user.avatarURL,
                        seen: viewModel.isSeen,
                        displayedPlace: .storyFeed
                    )
                    Text(viewModel.story.user.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.isSeen ? .secondary : .primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
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
