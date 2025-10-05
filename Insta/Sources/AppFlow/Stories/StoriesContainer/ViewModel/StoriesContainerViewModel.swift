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

final class StoriesContainerViewModel: StoriesContainerViewModelProtocol {
    private let storiesFeed: StoriesFeedProtocol
    let config: StoriesContainerConfig
    private let autoConfig: StoryAutoAdvanceConfig
    
    @Published private(set) var currentStoryIndex: Int
    @Published private(set) var currentStoryViewModel: StoryViewModel

    private let dismissRequestedSubject = PassthroughSubject<Void, Never>()
    private let resetDragRequestedSubject = PassthroughSubject<Void, Never>()
    private let nextStoryRequestedSubject = PassthroughSubject<Void, Never>()

    private var storyViewModelList: [StoryViewModel] = []
    private var subscriptions: Set<AnyCancellable> = []

    var stories: [StoryProtocol] { storiesFeed.stories }
    var currentStory: StoryProtocol { stories[safe: currentStoryIndex] ?? stories.first! }

    var dismissRequested: AnyPublisher<Void, Never> {
        dismissRequestedSubject.eraseToAnyPublisher()
    }
    var resetDragRequested: AnyPublisher<Void, Never> {
        resetDragRequestedSubject.eraseToAnyPublisher()
    }
    var nextStoryRequested: AnyPublisher<Void, Never> {
        nextStoryRequestedSubject.eraseToAnyPublisher()
    }
    var previousStoryViewModel: StoryViewModel? {
        storyViewModelList[safe: currentStoryIndex - 1]
    }
    var nextStoryViewModel: StoryViewModel? {
        storyViewModelList[safe: currentStoryIndex + 1]
    }

    init(feed: StoriesFeedProtocol, config: StoriesContainerConfig = .init(), autoConfig: StoryAutoAdvanceConfig = .init()) {
        self.storiesFeed = feed
        self.config = config
        self.autoConfig = autoConfig
        let safeStartIndex = max(0, min(feed.startIndex, feed.stories.count - 1))
        self.currentStoryIndex = safeStartIndex
        self.storyViewModelList = feed.stories.map { StoryViewModel(story: $0, auto: autoConfig) }

        guard let initialStoryViewModel = storyViewModelList[safe: safeStartIndex] else {
            fatalError("StoriesContainerViewModel should not be initialized with empty stories array")
        }
        self.currentStoryViewModel = initialStoryViewModel
        setActiveStory(at: safeStartIndex, direction: .next)
    }

    func goToNextStory() {
        transition(to: currentStoryIndex + 1, direction: .next)
    }

    func goToPreviousStory() {
        transition(to: currentStoryIndex - 1, direction: .prev)
    }

    private func transition(to newIndex: Int, direction: StoriesSwitchDirection) {
        guard newIndex != currentStoryIndex,
              newIndex >= 0, newIndex < stories.count else { return }

        setActiveStory(at: newIndex, direction: direction)
    }

    private func setActiveStory(at index: Int, direction: StoriesSwitchDirection) {
        subscriptions.removeAll()

        for (storyIndex, storyViewModel) in storyViewModelList.enumerated() {
            if storyIndex == index {
                storyViewModel.becomeCurrentStory()
            } else {
                storyViewModel.resignCurrentStory()
            }
        }

        currentStoryIndex = index
        currentStoryViewModel = storyViewModelList[index]

        currentStoryViewModel.didFinishPublisher
            .sink { [weak self] in self?.handleDidFinish() }
            .store(in: &subscriptions)

        currentStoryViewModel.requestPreviousPublisher
            .sink { [weak self] in self?.handleRequestPrevious() }
            .store(in: &subscriptions)
    }

    private func handleDidFinish() {
        if currentStoryIndex + 1 < stories.count {
            DispatchQueue.main.async {
                self.nextStoryRequestedSubject.send()
            }
        } else {
            dismissRequestedSubject.send()
        }
    }

    private func handleRequestPrevious() {
        if currentStoryIndex - 1 >= 0 {
            transition(to: currentStoryIndex - 1, direction: .prev)
            resetDragRequestedSubject.send()
        }
    }
}

// MARK: - StoryViewModel Delegation Helpers

private extension StoryViewModel {
    func becomeCurrentStory() {
        pause(false)
        clearDidFinish()
        clearRequestPrev()
        start()
    }
    func resignCurrentStory() {
        pause(true)
        stop()
        clearDidFinish()
        clearRequestPrev()
    }
    var didFinishPublisher: AnyPublisher<Void, Never> {
        $didFinish
            .removeDuplicates()
            .filter { $0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }
    var requestPreviousPublisher: AnyPublisher<Void, Never> {
        $requestPrevStory
            .removeDuplicates()
            .filter { $0 }
            .map { _ in }
            .eraseToAnyPublisher()
    }
}
