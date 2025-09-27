//
//  StoryPlayerViewModel.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Combine
import SwiftUI

enum HeartPulse {
    case like
    case dislike
}

final class StoryPlayerViewModel: ObservableObject {
    @Published var userStories: [StoryItem]
    @Published var currentIndex: Int
    @Published var isPaused: Bool = false
    @Published var showHeart: Bool = false
    @Published var heartPulse: HeartPulse? = nil
    @Published var progress: Double = 0 // 0..1
    @Published var didExhaustUser: Bool = false
    @Published var currentStory: Story

    var currentItem: StoryItem { userStories[currentIndex] }

    private let tick: TimeInterval = 0.04
    private let itemDuration: TimeInterval = 5.0
    private let persistence: PersistenceStore

    private var bag = Set<AnyCancellable>()
    private var timer: Timer?
    private var hasStarted = false

    // Callbacks provided by the view layer
    private let nextUserProvider: (() -> Story?)?
    private let prevUserProvider: (() -> Story?)?
    private var dismissAction: (() -> Void)?

    func load(story: Story, startAt index: Int = 0) {
        stop()
        currentStory = story
        userStories = story.items
        currentIndex = min(max(0, index), userStories.indices.last ?? 0)
        progress = 0
        hasStarted = false
    }

    init(story: Story,
         startAt index: Int,
         persistence: PersistenceStore = PersistenceStore(),
         onPrevUser: (() -> Story?)? = nil,
         onNextUser: (() -> Story?)? = nil,
         onDismiss: (() -> Void)? = nil) {
        self.currentStory = story
        self.userStories = story.items
        self.currentIndex = index
        self.persistence = persistence
        self.prevUserProvider = onPrevUser
        self.nextUserProvider = onNextUser
        self.dismissAction = onDismiss
        bind()
    }

    func setDismiss(_ action: (() -> Void)?) {
        dismissAction = action
    }

    func start() {
        stop()
        progress = 0
        if !hasStarted {
            markSeen()
            hasStarted = true
        }
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

    func restart() {
        progress = 0
    }

    func prevOrRestart() {
        if currentIndex > 0 {
            currentIndex -= 1
            progress = 0
            markSeen()
        } else {
            progress = 0
        }
    }

    func next() {
        progress = 0
        if currentIndex < userStories.count - 1 {
            currentIndex += 1
            markSeen()
        } else {
            didExhaustUser = true
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
        let willLike = !isLiked(id)
        // Trigger distinct overlay state first, then toggle persistence
        withAnimation(.spring(response: 0.35, dampingFraction: 0.6)) {
            heartPulse = willLike ? .like : .dislike
        }
        persistence.toggleLike(id)
        // Clear pulse after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            withAnimation(.easeOut(duration: 0.25)) { self.heartPulse = nil }
        }
    }

    func isLiked(_ id: String) -> Bool {
        return persistence.isLiked(id)
    }

    private func bind() {
        $didExhaustUser
            .removeDuplicates()
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if let next = self.nextUserProvider?() {
                    self.load(story: next, startAt: 0)
                } else {
                    self.dismissAction?()
                }
                self.didExhaustUser = false
            }
            .store(in: &bag)
    }

    private func markSeen() {
        persistence.markSeen(currentItem.id)
    }

    deinit { stop() }
}
