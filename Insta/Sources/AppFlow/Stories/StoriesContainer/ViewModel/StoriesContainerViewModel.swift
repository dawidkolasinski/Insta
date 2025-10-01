//
//  StoriesContainerViewModel.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//  Minimal, protocol-oriented VMs with main-thread Timer and progress.
//  No nested types inside classes. Universal & testable.
//

import Combine
import Foundation
import SwiftUI

final class StoriesContainerViewModel: ObservableObject {
    private let feed: StoriesFeedProtocol

    @Published private(set) var currentIndex: Int
    @Published private(set) var currentStoryViewModel: StoryViewModel
    @Published private(set) var isDirectionForward: Bool = true

    let dismissRequested = PassthroughSubject<Void, Never>()
    let resetDragRequested = PassthroughSubject<Void, Never>()
    let nextStoryRequested = PassthroughSubject<Void, Never>()

    private var childFinishCancellable: AnyCancellable?
    private var childPrevCancellable: AnyCancellable?
    private var storyViewModels: [StoryViewModel] = []

    var stories: [StoryProtocol] { feed.stories }

    var currentStory: StoryProtocol {
        guard let story = stories[safe: currentIndex] ?? stories.first else {
            fatalError("StoriesContainerViewModel should not be used with an empty stories array.")
        }
        return story
    }

    var previousStoryViewModel: StoryViewModel? {
        (currentIndex - 1) >= 0 ? storyViewModels[safe: currentIndex - 1] : nil
    }

    var nextStoryViewModel: StoryViewModel? {
        (currentIndex + 1) < storyViewModels.count ? storyViewModels[safe: currentIndex + 1] : nil
    }

    init(feed: StoriesFeedProtocol) {
        self.feed = feed
        let startIndex = max(0, min(feed.startIndex, max(0, feed.stories.count - 1)))
        self.currentIndex = startIndex

        let createdViewModels = feed.stories.map { StoryViewModel(story: $0) }
        self.storyViewModels = createdViewModels

        if let initialViewModel = createdViewModels[safe: startIndex] {
            self.currentStoryViewModel = initialViewModel
            for (index, vm) in createdViewModels.enumerated() {
                vm.pause(index != startIndex)
            }
        } else {
            fatalError("No stories are available to show. The view model should not be initialized with empty stories.")
        }

        bindChild()
    }

    func goToNextStory() {
        isDirectionForward = true
        if currentIndex + 1 < stories.count {
            currentIndex += 1
            swapChildForCurrent()
        }
    }

    func goToPreviousStory() {
        isDirectionForward = false
        if currentIndex - 1 >= 0 {
            currentIndex -= 1
            swapChildForCurrent()
        }
    }

    private func bindChild() {
        childFinishCancellable?.cancel()
        childPrevCancellable?.cancel()

        childFinishCancellable = currentStoryViewModel.$didFinish
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] finished in
                guard let self = self, finished else { return }
                self.handleChildFinished()
            }

        childPrevCancellable = currentStoryViewModel.$requestPrevStory
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] requested in
                guard let self = self, requested else { return }
                self.handlePrevRequested()
            }
    }

    private func handleChildFinished() {
        isDirectionForward = true
        currentStoryViewModel.clearDidFinish()
        let nextIndex = currentIndex + 1
        if nextIndex < stories.count {
            DispatchQueue.main.async { [weak self] in
                self?.nextStoryRequested.send()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                self?.nextStoryRequested.send()
            }
        } else {
            dismissRequested.send()
        }
    }

    private func handlePrevRequested() {
        isDirectionForward = false
        currentStoryViewModel.clearRequestPrev()
        if currentIndex - 1 >= 0 {
            currentIndex -= 1
            swapChildForCurrent()
            resetDragRequested.send()
        }
    }

    private func swapChildForCurrent() {
        for (index, vm) in storyViewModels.enumerated() { vm.pause(index != currentIndex) }
        if let newViewModel = storyViewModels[safe: currentIndex] {
            currentStoryViewModel = newViewModel
            currentStoryViewModel.clearDidFinish()
            currentStoryViewModel.clearRequestPrev()
            bindChild()
        }
    }

    deinit {
        childFinishCancellable?.cancel()
        childPrevCancellable?.cancel()
    }
}
