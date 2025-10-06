//
//  AvatarDisplayPlace.swift
//  Insta
//
//  Created by Dawid Kolasinski on 06/10/2025.
//

import Foundation

enum AvatarDisplayedPlace {
    case storyFeed
    case storyDetail
    case feed
}

extension AvatarDisplayedPlace {
    var avatarWidth: CGFloat {
        switch self {
        case .storyFeed:
            76
        case .storyDetail:
            16
        case .feed:
            22
        }
    }

    var strokeWidth: CGFloat? {
        switch self {
        case .storyFeed:
            4
        case .storyDetail:
            nil
        case .feed:
            0
        }
    }
}
