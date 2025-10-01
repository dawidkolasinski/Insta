//
//  StoriesProtocols.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Foundation
import SwiftUI

struct AnyStoryItem: StoryItemProtocol {
    let id: String
    let imageURL: URL?
}

struct AnyStoryUser: StoryUserProtocol {
    let name: String
    let avatarURL: URL?

}

struct AnyStory: StoryProtocol {
    let id: String
    let user: StoryUserProtocol
    let items: [StoryItemProtocol]
}

enum ImageSource: Equatable {
    case url(URL)
    case asset(String)
}

struct ImageSlide: Identifiable, Equatable {
    let id: String
    let source: ImageSource
    init(id: String = UUID().uuidString, source: ImageSource) {
        self.id = id
        self.source = source
    }
}
