//
//  StoryItemProtocol.swift
//  Insta
//
//  Created by Dawid Kolasinski on 30/09/2025.
//

import Foundation

protocol StoryItemProtocol: Codable {
    var id: String { get }
    var imageURL: URL { get }
    var postedAt: Date { get }
}
