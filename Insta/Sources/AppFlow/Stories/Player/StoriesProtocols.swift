//
//  StoriesProtocols.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Foundation
import SwiftUI

protocol StoryItemProtocol {
    var id: String { get }
    var imageURL: URL? { get }
}

protocol StoryUserProtocol {
    var name: String { get }
    var avatarURL: URL? { get }
}

protocol StoryProtocol {
    var id: String { get }
    var user: StoryUserProtocol { get }
    var items: [any StoryItemProtocol] { get }
}

protocol StoriesFeedProtocol {
    var stories: [any StoryProtocol] { get }
    var startIndex: Int { get }
}

struct AnyStoryItem: StoryItemProtocol {
    let id: String
    let imageURL: URL?
    init(id: String, imageURL: URL?) { self.id = id; self.imageURL = imageURL }
}

struct AnyStoryUser: StoryUserProtocol {
    let name: String
    let avatarURL: URL?
    init(name: String, avatarURL: URL?) { self.name = name; self.avatarURL = avatarURL }
}

struct AnyStory: StoryProtocol {
    let id: String
    let user: StoryUserProtocol
    let items: [any StoryItemProtocol]
    init(id: String, user: StoryUserProtocol, items: [any StoryItemProtocol]) {
        self.id = id; self.user = user; self.items = items
    }
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
