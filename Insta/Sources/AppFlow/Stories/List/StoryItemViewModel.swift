//
//  StoryItemViewModel.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Combine
import Foundation

final class StoryItemViewModel: ObservableObject {
    @Published private(set) var isSeen: Bool
    let story: Story
    private let persistence: PersistenceStore

    init(story: Story, persistence: PersistenceStore) {
        self.story = story
        self.persistence = persistence
        // A story is considered seen when all its items are marked seen in persistence
        self.isSeen = story.items.allSatisfy { persistence.isSeen($0.id) }
    }

    func markDisplayed() {
        for item in story.items {
            persistence.markSeen(item.id)
        }
        isSeen = true
    }

    func refreshSeen() {
        isSeen = story.items.allSatisfy { persistence.isSeen($0.id) }
    }
}

extension StoryItemViewModel: Identifiable {

}
