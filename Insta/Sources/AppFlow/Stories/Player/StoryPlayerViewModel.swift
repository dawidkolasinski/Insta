//
//  StoryPlayerViewModel.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Combine
import SwiftUI

final class StoryPlayerViewModel: ObservableObject {
    @Published var userStories: [StoryItem]
    @Published var currentIndex: Int
    @Published var isPaused: Bool = false
    @Published var showHeart: Bool = false
    @Published var progress: Double = 0 // 0..1

    private let tick: TimeInterval = 0.04
    private let itemDuration: TimeInterval = 5.0
    private var timer: Timer?

    private let persistence: PersistenceStore
    var currentItem: StoryItem { userStories[currentIndex] }

    init(items: [StoryItem], startAt index: Int, persistence: PersistenceStore) {
        self.userStories = items
        self.currentIndex = index
        self.persistence = persistence
        markSeen()
        start()
    }

    func start() {
        stop()
        progress = 0
        timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { [weak self] _ in
            guard let self else { return }
            guard !self.isPaused else { return }
            self.progress += self.tick / self.itemDuration
            if self.progress >= 1 { self.next() }
        }
    }

    func stop() {
        timer?.invalidate(); timer = nil
    }

    func pause(_ value: Bool) {
        isPaused = value
    }

    func next() {
        progress = 0
        if currentIndex < userStories.count - 1 {
            currentIndex += 1
            markSeen()
        }
    }

    func prev() {
        progress = 0
        if currentIndex > 0 {
            currentIndex -= 1
            markSeen()
        }
    }

    func toggleLike(_ id: String) {
        persistence.toggleLike(id)
        withAnimation(.spring()) { showHeart = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut) { self.showHeart = false }
        }
    }

    func isLiked(_ id: String) -> Bool {
        return persistence.isLiked(id)
    }

    private func markSeen() {
        persistence.markSeen(currentItem.id)
    }
    
    deinit { stop() }
}
