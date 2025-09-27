//
//  PersistenceStore.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Combine
import SwiftUI

final class PersistenceStore: ObservableObject {
    @Published private(set) var liked: Set<String> = []
    @Published private(set) var seen: Set<String> = []

    private let likedKey = "liked_ids_v1"
    private let seenKey  = "seen_ids_v1"
    private let defaults = UserDefaults.standard

    init() { load() }

    func isLiked(_ id: String) -> Bool { liked.contains(id) }
    func isSeen(_ id: String) -> Bool { seen.contains(id) }

    func toggleLike(_ id: String) {
        if liked.contains(id) { liked.remove(id) } else { liked.insert(id) }
        save()
    }

    func markSeen(_ id: String) {
        if !seen.contains(id) { seen.insert(id); save() }
    }

    private func load() {
        if let l = defaults.array(forKey: likedKey) as? [String] { liked = Set(l) }
        if let s = defaults.array(forKey: seenKey)  as? [String] { seen  = Set(s) }
    }

    private func save() {
        defaults.set(Array(liked), forKey: likedKey)
        defaults.set(Array(seen),  forKey: seenKey)
    }
}
