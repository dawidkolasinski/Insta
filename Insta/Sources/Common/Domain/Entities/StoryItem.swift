//
//  StoryItem.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Foundation

struct StoryItem: Identifiable, Hashable, Codable {
    let id: String                // np. "item-<page>-<userId>-<i>"
    let imageURL: URL             // zdalny obraz (picsum z seedem)
    let postedAt: Date            // metadata do sortowania/paska progresu
}
