//
//  HomeViewModelProtocol.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Combine
import Foundation

protocol HomeViewModelProtocol: ViewModelProtocol {
    var stories: [StoryItemViewModel] { get }
    var isOnline: Bool { get }

    func loadInitial() async
    func loadMoreIfNeeded(current storyVM: StoryItemViewModel?) async
    func refreshSeen()
}
