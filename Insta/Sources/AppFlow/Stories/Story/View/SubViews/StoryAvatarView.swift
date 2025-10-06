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

    @ObservedObject private var cache = AvatarImageCache.shared

    var body: some View {
        Group {
            if let cached = cache.image(for: url) {
                cached
                    .resizable()
                    .scaledToFill()
            } else {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let img):
                        img.resizable().scaledToFill()
                            .onAppear {
                                Task { @MainActor in
                                    cache.store(img, for: url)
                                }
                            }
                    case .failure:
                        Color.gray.opacity(0.2)
                    default:
                        ProgressView()
                    }
                }
            }
        }
        .frame(width: displayedPlace.avatarWidth, height: displayedPlace.avatarWidth)
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
        .onAppear {
            cache.prefetch(url: url)
        }
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
