//
//  StoryRepository.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Foundation

final class StoryRepository {
    private let usersSource = UsersSource()
    private var userPages: [[User]] = []
    private let itemsPerStory = 3

    init() {
        if let pages = try? usersSource.loadAllUsers() {
            self.userPages = pages
        }
    }

    func loadPage(_ page: Int) async throws -> [Story] {
        guard !userPages.isEmpty else { return [] }

        let basePageIndex = page % userPages.count
        let users = userPages[basePageIndex]
        let now = Date()

        return users.enumerated().map { (idx, user) in
            let storyID = "story-\(page)-\(user.id)"

            let items: [StoryItem] = (0..<itemsPerStory).map { i in
                let seed = "\(user.id)-\(page)-\(i)"
                let imageURL = URL(string: "https://picsum.photos/seed/\(seed)/1080/1920")!

                return StoryItem(
                    id: "item-\(page)-\(user.id)-\(i)",
                    imageURL: imageURL,
                    postedAt: now.addingTimeInterval(TimeInterval(-(idx * itemsPerStory + i) * 3600))
                )
            }

            return Story(id: storyID, user: user, items: items)
        }
    }
}
