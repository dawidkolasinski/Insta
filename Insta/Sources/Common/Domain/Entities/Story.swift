//
//  Story.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Foundation

struct Story: Identifiable, StoryProtocol {
    let id: String
    var user: StoryUserProtocol
    var items: [StoryItemProtocol]
    var postedAt: Date {
        items.max(by: { $0.postedAt < $1.postedAt })?.postedAt ?? Date()
    }
}

// MARK: - Codable
extension Story: Codable {
    enum CodingKeys: String, CodingKey {
        case id
        case user
        case items
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        // Use type erasure wrappers for encoding
        if let codableUser = user as? Codable & StoryUserProtocol {
            try container.encode(AnyStoryUser(
                name: codableUser.name,
                avatarURL: codableUser.avatarURL
            ), forKey: .user)
        } else if let user = user as? User {
            try container.encode(AnyStoryUser(
                name: user.name,
                avatarURL: user.avatarURL
            ), forKey: .user)
        } else {
            throw EncodingError.invalidValue(user, .init(codingPath: [CodingKeys.user], debugDescription: "User is not encodable"))
        }
        
        try container.encode(items.map { item -> AnyStoryItem in
            if let concrete = item as? StoryItem {
                return AnyStoryItem(id: concrete.id, imageURL: concrete.imageURL, postedAt: concrete.postedAt)
            } else if let any = item as? AnyStoryItem {
                return any
            } else {
                fatalError("Unsupported item type for encoding")
            }
        }, forKey: .items)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        
        // Decode as AnyStoryUser and assign to protocol property
        let decodedUser = try container.decode(AnyStoryUser.self, forKey: .user)
        user = decodedUser
        
        let decodedItems = try container.decode([AnyStoryItem].self, forKey: .items)
        items = decodedItems
    }
}

// MARK: - Equatable
extension Story: Equatable {
    static func == (lhs: Story, rhs: Story) -> Bool {
        lhs.id == rhs.id &&
        lhs.user.name == rhs.user.name &&
        lhs.user.avatarURL == rhs.user.avatarURL &&
        lhs.items.elementsEqual(rhs.items, by: { l, r in
            l.id == r.id &&
            l.imageURL == r.imageURL &&
            l.postedAt == r.postedAt
        })
    }
}

// MARK: - Hashable
extension Story: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(user.name)
        hasher.combine(user.avatarURL)
        for item in items {
            hasher.combine(item.id)
            hasher.combine(item.imageURL)
            hasher.combine(item.postedAt)
        }
    }
}
