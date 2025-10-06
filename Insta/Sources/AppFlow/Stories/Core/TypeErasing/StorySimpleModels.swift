//
//  StorySimpleModels.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Foundation
import SwiftUI

struct AnyStoryItem: StoryItemProtocol {
    let id: String
    let imageURL: URL
    let postedAt: Date
}

struct AnyStoryUser: StoryUserProtocol {
    let name: String
    let avatarURL: URL?
}

struct AnyStory: StoryProtocol {
    let id: String
    let user: StoryUserProtocol
    let items: [StoryItemProtocol]
    var postedAt: Date {
        items.max(by: { $0.postedAt < $1.postedAt })?.postedAt ?? Date()
    }
}
