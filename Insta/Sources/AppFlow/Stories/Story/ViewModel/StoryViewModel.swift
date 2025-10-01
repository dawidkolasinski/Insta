//
//  StoryViewModel.swift
//  Insta
//
//  Created by Dawid Kolasinski on 30/09/2025.
//

import Combine
import SwiftUI

final class StoryViewModel: ObservableObject {
    private let autoAdvanceConfig: StoryAutoAdvanceConfig

    @Published private(set) var story: StoryProtocol
    @Published private(set) var items: [StoryItemProtocol]
    @Published private(set) var index: Int = 0
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var holdCount: Int = 0
    @Published private(set) var progress: Double = 0
    @Published private(set) var isCurrentItemLoaded: Bool = false
    @Published private(set) var imageCache: [String: Image] = [:]
    @Published private(set) var didFinish: Bool = false
    @Published private(set) var requestPrevStory: Bool = false

    private var timerRef: Timer?

    var currentItem: StoryItemProtocol {
        items[safe: index]
        ?? items.first
        ?? AnyStoryItem(id: "empty", imageURL: nil)
    }

    init(story: StoryProtocol, auto: StoryAutoAdvanceConfig = .init()) {
        self.story = story
        self.items = story.items
        self.autoAdvanceConfig = auto
        self.progress = 0
        self.didFinish = false
        self.requestPrevStory = false
        self.isCurrentItemLoaded = false
    }

    deinit { stop() }

    func cachedImage(for itemID: String) -> Image? { imageCache[itemID] }
    func store(image: Image, for itemID: String) { imageCache[itemID] = image }

    func load(story: StoryProtocol, startAt: Int = 0) {
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
        guard autoAdvanceConfig.enabled, !items.isEmpty else { return }

        let schedule = {
            let localTimer = Timer.scheduledTimer(withTimeInterval: self.autoAdvanceConfig.tick, repeats: true) { [weak self] _ in
                guard let self = self else { return }
                if self.isPaused || self.holdCount > 0 || !self.isCurrentItemLoaded { return }

                self.progress += self.autoAdvanceConfig.tick / max(0.0001, self.autoAdvanceConfig.durationPerSlide)
                if self.progress >= 1 {
                    self.progress = 0
                    if self.index < self.items.count - 1 {
                        self.index += 1
                        self.isCurrentItemLoaded = false
                        self.scheduleLoadFallback()
                    } else if self.autoAdvanceConfig.loops {
                        self.index = 0
                        self.isCurrentItemLoaded = false
                        self.scheduleLoadFallback()
                    } else {
                        self.markDidFinish()
                        self.stop()
                    }
                }
            }
            RunLoop.main.add(localTimer, forMode: .common)
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
            scheduleLoadFallback()
        } else if autoAdvanceConfig.loops {
            index = 0
            isCurrentItemLoaded = false
            scheduleLoadFallback()
        } else {
            markDidFinish()
            stop()
        }
    }

    func prev() {
        progress = 0
        if index > 0 {
            index -= 1
            isCurrentItemLoaded = false
            scheduleLoadFallback()
        } else if autoAdvanceConfig.loops {
            index = max(0, items.count - 1)
            isCurrentItemLoaded = false
            scheduleLoadFallback()
        } else {
            requestPrev()
        }
    }

    func onCurrentItemLoaded() {
        isCurrentItemLoaded = true
        if timerRef == nil { start() }
    }

    func pause(_ value: Bool) { isPaused = value }

    func hold(_ value: Bool) {
        if value { holdCount += 1 } else { holdCount = max(0, holdCount - 1) }
    }

    func markDidFinish() { didFinish = true }
    func clearDidFinish() { didFinish = false }
    func requestPrev() { requestPrevStory = true }
    func clearRequestPrev() { requestPrevStory = false }

    private func scheduleLoadFallback() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
            guard let strongSelf = self else { return }
            guard strongSelf.timerRef != nil, strongSelf.isCurrentItemLoaded == false else { return }
            strongSelf.onCurrentItemLoaded()
        }
    }
}
