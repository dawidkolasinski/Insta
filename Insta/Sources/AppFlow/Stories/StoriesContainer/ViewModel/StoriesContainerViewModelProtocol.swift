//
//  StoriesContainerViewModelProtocol.swift
//  Insta
//
//  Created by Dawid Kolasinski on 01/10/2025.
//

import Combine
import Foundation

protocol StoriesContainerViewModelProtocol: ViewModelProtocol {
    var currentStoryIndex: Int { get }
    var currentStoryViewModel: StoryViewModel { get }
    var previousStoryViewModel: StoryViewModel? { get }
    var nextStoryViewModel: StoryViewModel? { get }
    var stories: [StoryProtocol] { get }
    var currentStory: StoryProtocol { get }
    var config: StoriesComponentConfig { get }

    var dismissRequested: AnyPublisher<Void, Never> { get }
    var resetDragRequested: AnyPublisher<Void, Never> { get }
    var nextStoryRequested: AnyPublisher<Void, Never> { get }

    func goToNextStory()
    func goToPreviousStory()
}
