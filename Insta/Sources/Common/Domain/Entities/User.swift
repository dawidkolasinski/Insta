//
//  User.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Foundation

struct User: Identifiable, Hashable, Codable {
    let id: Int
    let name: String
    let avatarURL: URL
}
