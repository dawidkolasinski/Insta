//
//  StoriesFeedProtocol.swift
//  Insta
//
//  Created by Dawid Kolasinski on 30/09/2025.
//

import Foundation

protocol StoriesFeedProtocol {
    var stories: [StoryProtocol] { get }
    var startIndex: Int { get }
}
