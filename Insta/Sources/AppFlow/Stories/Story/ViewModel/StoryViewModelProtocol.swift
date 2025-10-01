//
//  StoryViewModelProtocol.swift
//  Insta
//
//  Created by Dawid Kolasinski on 01/10/2025.
//

import SwiftUI

protocol StoryViewModelProtocol: ViewModelProtocol {
    var story: StoryProtocol { get }
    var items: [StoryItemProtocol] { get }
    var index: Int { get }
    var progress: Double { get }
    var currentItem: StoryItemProtocol { get }
    
    func cachedImage(for itemID: String) -> Image?
    func store(image: Image, for itemID: String)
    func pause(_ value: Bool)
    func hold(_ value: Bool)
    func advance(to direction: StoryAdvanceDirection)
    func onCurrentItemLoaded()
}
