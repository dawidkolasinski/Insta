//
//  StoriesFeedAdapter.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Foundation

struct StoriesFeedAdapter: StoriesFeedProtocol {
    let stories: [StoryProtocol]
    let startIndex: Int
}

extension StoriesFeedAdapter {
    init(viewModels: [StoryItemViewModel], startIndex: Int = 0) {
        let mapped: [StoryProtocol] = viewModels.map { vm in
            AnyStory(
                id: vm.story.id,
                user: AnyStoryUser(name: vm.story.user.name, avatarURL: vm.story.user.avatarURL),
                items: vm.story.items.map { AnyStoryItem(id: $0.id, imageURL: $0.imageURL) }
            )
        }
        let safeIndex = min(max(0, startIndex), max(0, mapped.count - 1))
        self.init(stories: mapped, startIndex: safeIndex)
    }
}
