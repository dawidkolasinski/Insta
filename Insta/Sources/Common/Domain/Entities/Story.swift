//
//  Story.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Foundation

struct Story: Identifiable, Hashable, Codable {
    let id: String
    let user: User
    let items: [StoryItem]
}

