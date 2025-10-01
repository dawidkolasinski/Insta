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

    private let storyRepository: StoryRepository
    private var currentPage: Int = 0

    init(storyRepository: StoryRepository = StoryRepository()) {
        self.storyRepository = storyRepository
    }

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
        if let pageStories = try? await storyRepository.loadPage(currentPage) {
            stories.append(contentsOf: pageStories)
            currentPage += 1
        }
    }
}
