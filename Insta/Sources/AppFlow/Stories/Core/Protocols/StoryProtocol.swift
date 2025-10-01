//
//  StoryProtocol.swift
//  Insta
//
//  Created by Dawid Kolasinski on 30/09/2025.
//

import Foundation

protocol StoryProtocol {
    var id: String { get }
    var user: StoryUserProtocol { get }
    var items: [StoryItemProtocol] { get }
}
