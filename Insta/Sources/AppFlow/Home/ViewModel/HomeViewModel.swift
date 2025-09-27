//
//  HomeViewModel.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Combine
import Foundation

final class HomeViewModel: HomeViewModelProtocol {

    @Published private(set) var stories: [StoryItemViewModel] = []
    private var page: Int = 0

    private let repo: StoryRepository
    let persistenceObj: PersistenceStore

    init(
        repo: StoryRepository = StoryRepository(),
        persistence: PersistenceStore = PersistenceStore()
    ) {
        self.repo = repo
        self.persistenceObj = persistence
    }

    func loadInitial() async {
        guard stories.isEmpty else { return }
        await loadMore()
    }

    func loadMoreIfNeeded(current storyVM: StoryItemViewModel?) async {
        guard let storyVM = storyVM, !stories.isEmpty else { return }
        let threshold = 3
        let limitIndex = stories.index(stories.endIndex, offsetBy: -threshold, limitedBy: stories.startIndex) ?? stories.startIndex
        if let currentIndex = stories.firstIndex(where: { $0.id == storyVM.id }), currentIndex >= limitIndex {
            await loadMore()
        }
    }

    private func loadMore() async {
        if let pageStories = try? await repo.loadPage(page) {
            let newVMs = pageStories.map { StoryItemViewModel(story: $0, persistence: persistenceObj) }
            stories.append(contentsOf: newVMs)
            page += 1
        }
    }
}
