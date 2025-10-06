//
//  StoryUserProtocol.swift
//  Insta
//
//  Created by Dawid Kolasinski on 30/09/2025.
//

import Foundation

protocol StoryUserProtocol: Codable {
    var name: String { get }
    var avatarURL: URL? { get }
}
