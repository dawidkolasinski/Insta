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
            let itemsCount = Int.random(in: 1...10)

            var offsets: [Int] = (0..<itemsCount).map { _ in Int.random(in: 1_800...14_400) }
            for i in 1..<offsets.count {
                offsets[i] += offsets[i-1]
            }
            offsets = offsets.reversed()

            let items: [StoryItem] = (0..<itemsCount).map { i in
                let seed = "\(user.id)-\(page)-\(i)"
                let imageURL = URL(string: "https://picsum.photos/seed/\(seed)/1080/1920")!
                let itemDate = now.addingTimeInterval(-TimeInterval(offsets[i]))
                return StoryItem(
                    id: "item-\(page)-\(user.id)-\(i)",
                    imageURL: imageURL,
                    postedAt: itemDate
                )
            }

            return Story(id: storyID, user: user, items: items)
        }
    }
}
