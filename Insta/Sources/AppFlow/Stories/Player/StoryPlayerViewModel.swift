//
//  StoryPlayerViewModel.swift
//  Insta
//
//  Minimal, protocol-oriented VMs with main-thread Timer and progress.
//  No nested types inside classes. Universal & testable.
//

import Combine
import Foundation

struct AutoAdvanceConfig: Equatable {
    var enabled: Bool = true
    var durationPerSlide: TimeInterval = 5.0
    var tick: TimeInterval = 0.05
    var loops: Bool = false
}

final class StoriesContainerViewModel: ObservableObject {
    private(set) var feed: any StoriesFeedProtocol
    @Published private(set) var currentIndex: Int

    @Published private(set) var storyVM: StoryViewModel
    @Published var shouldDismiss: Bool = false
    private var childFinishCancellable: AnyCancellable?
    private var childPrevCancellable: AnyCancellable?

    var stories: [any StoryProtocol] { feed.stories }
    var currentStory: any StoryProtocol { stories[safe: currentIndex] ?? feed.stories.first! }

    init(feed: any StoriesFeedProtocol) {
        self.feed = feed
        let start = max(0, min(feed.startIndex, max(0, feed.stories.count - 1)))
        self.currentIndex = start
        let vm = StoryViewModel(story: feed.stories[start])
        self.storyVM = vm
        self.shouldDismiss = false
        bindChild()
    }

    private func bindChild() {
        childFinishCancellable?.cancel()
        childPrevCancellable?.cancel()

        childFinishCancellable = storyVM.$didFinish
            .removeDuplicates()
            .sink { [weak self] finished in
                guard let self = self, finished else { return }
                self.handleChildFinished()
            }

        childPrevCancellable = storyVM.$requestPrevStory
            .removeDuplicates()
            .sink { [weak self] requested in
                guard let self = self, requested else { return }
                self.handlePrevRequested()
            }
    }

    private func handleChildFinished() {
        let nextIndex = currentIndex + 1
        if nextIndex < stories.count {
            currentIndex = nextIndex
            swapChildForCurrent()
        } else {
            storyVM.didFinish = false
            shouldDismiss = true
        }
    }

    private func handlePrevRequested() {
        if currentIndex - 1 >= 0 {
            currentIndex -= 1
            swapChildForCurrent()
        } else {
            // At the first story; ignore, but reset the flag so future taps emit again.
            storyVM.requestPrevStory = false
        }
    }

    private func swapChildForCurrent() {
        storyVM.stop()
        storyVM = StoryViewModel(story: currentStory)
        bindChild()
    }

    func goNextStory() {
        if currentIndex + 1 < stories.count {
            currentIndex += 1
            swapChildForCurrent()
        }
    }
    func goPrevStory() {
        if currentIndex - 1 >= 0 {
            currentIndex -= 1
            swapChildForCurrent()
        }
    }
}

// MARK: - Single Story (slides/items) ViewModel

final class StoryViewModel: ObservableObject {
    // Config
    private let auto: AutoAdvanceConfig

    // State
    @Published private(set) var story: any StoryProtocol
    @Published private(set) var items: [any StoryItemProtocol]
    @Published private(set) var index: Int = 0
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var progress: Double = 0 // 0..1
    @Published private(set) var isCurrentItemLoaded: Bool = false
    @Published var didFinish: Bool = false
    @Published var requestPrevStory: Bool = false

    // Timer
    private var timerRef: Timer?

    var currentItem: any StoryItemProtocol { items[safe: index] ?? items.first! }

    init(story: any StoryProtocol, auto: AutoAdvanceConfig = .init()) {
        self.story = story
        self.items = story.items
        self.auto = auto
        self.progress = 0
        self.didFinish = false
        self.requestPrevStory = false
        self.isCurrentItemLoaded = false
    }

    func load(story: any StoryProtocol, startAt: Int = 0) {
        stop()
        self.story = story
        self.items = story.items
        self.index = max(0, min(startAt, max(0, items.count - 1)))
        self.isPaused = false
        self.progress = 0
        self.didFinish = false
        self.requestPrevStory = false
        self.isCurrentItemLoaded = false
    }

    func start() {
        stop()
        progress = 0
        guard auto.enabled, !items.isEmpty else { return }

        let schedule = {
            let localTimer = Timer.scheduledTimer(withTimeInterval: self.auto.tick, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                guard !self.isPaused else { return }

                self.progress += self.auto.tick / max(0.0001, self.auto.durationPerSlide)
                if self.progress >= 1 {
                    self.progress = 0
                    if self.index < self.items.count - 1 {
                        self.index += 1
                        self.isCurrentItemLoaded = false
                        self.stop()
                    } else if self.auto.loops {
                        self.index = 0
                        self.isCurrentItemLoaded = false
                        self.stop()
                    } else {
                        self.didFinish = true
                        self.stop()
                    }
                }
            }
            RunLoop.main.add(localTimer, forMode: .common) // ensure main-thread run loop
            self.timerRef = localTimer
        }

        if Thread.isMainThread { schedule() } else { DispatchQueue.main.async(execute: schedule) }
    }

    func stop() {
        timerRef?.invalidate()
        timerRef = nil
    }

    func restart() { progress = 0 }

    func next() {
        progress = 0
        if index < items.count - 1 {
            index += 1
            isCurrentItemLoaded = false
            stop()
        } else if auto.loops {
            index = 0
            isCurrentItemLoaded = false
            stop()
        } else {
            didFinish = true
            stop()
        }
    }

    func prev() {
        progress = 0
        if index > 0 {
            index -= 1
            isCurrentItemLoaded = false
            stop()
        } else if auto.loops {
            index = max(0, items.count - 1)
            isCurrentItemLoaded = false
            stop()
        } else {
            // First slide and no looping → request container to move to previous story
            // Do NOT stop the timer; keep current slide playing if there's no previous user.
            requestPrevStory = true
            // Intentionally not calling stop()
        }
    }

    func onCurrentItemLoaded() {
        isCurrentItemLoaded = true
        if timerRef == nil { start() }
    }

    func pause(_ value: Bool) { isPaused = value }

    deinit { stop() }
}

// MARK: - Safe indexing helper

private extension Array {
    subscript(safe index: Index) -> Element? { indices.contains(index) ? self[index] : nil }
}
