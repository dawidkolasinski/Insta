//
//  StoriesListViewModel.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Combine
import Foundation

final class StoriesListViewModel: ObservableObject {
    @Published private(set) var stories: [Story] = []
    private var page: Int = 0
    private let repo = StoryRepository()

    func loadInitial() async {
        guard stories.isEmpty else { return }
        await loadMore()
    }

    func loadMoreIfNeeded(current story: Story?) async {
        guard let story else { return }
        let thresholdIndex = stories.index(stories.endIndex, offsetBy: -3)
        if stories.firstIndex(where: { $0.id == story.id }) == thresholdIndex {
            await loadMore()
        }
    }

    private func loadMore() async {
        if let pageStories = try? await repo.loadPage(page) {
            stories.append(contentsOf: pageStories)
            page += 1
        }
    }
}
