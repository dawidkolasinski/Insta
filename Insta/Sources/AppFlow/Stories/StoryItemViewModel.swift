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
        isSeen = false // TODO: add logic to handle correct state on init
    }

    func markDisplayed() {
        for item in story.items {
            persistence.markSeen(item.id)
        }
        isSeen = true
    }
}

extension StoryItemViewModel: Identifiable {

}
