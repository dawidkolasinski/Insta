//
//  StoryAvatarView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct StoryAvatarView: View {
    let url: URL
    let seen: Bool
    let displayedPlace: AvatarDisplayedPlace

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let img): img.resizable().scaledToFill()
            case .failure: Color.gray.opacity(0.2)
            default: ProgressView()
            }
        }
        .equalWidthAndHeight(displayedPlace.avatarWidth)
        .clipShape(Circle())
        .padding(displayedPlace.strokeWidth != nil ? 8 : 0)
        .overlay {
            if let strokeWidth = displayedPlace.strokeWidth {
                if seen {
                    Circle()
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: strokeWidth)
                } else {
                    Circle()
                        .strokeBorder(
                            AngularGradient(colors: [.pink, .orange, .yellow, .pink], center: .center),
                            lineWidth: strokeWidth
                        )
                }
            }
        }
        .accessibilityLabel(seen ? "Story seen" : "Story unseen")
    }
}

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
