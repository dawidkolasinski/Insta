//
//  StoryAvatarView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct StoryAvatarView: View {
    let url: URL?
    let seen: Bool
    let displayedPlace: AvatarDisplayedPlace

    @ObservedObject private var cache = AvatarImageCache.shared

    var body: some View {
        Group {
            if let url, let cached = cache.image(for: url) {
                cached
                    .resizable()
                    .scaledToFill()
            } else if let url {
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
            } else {
                // Brak URL: placeholder
                Color.gray.opacity(0.2)
                    .overlay(
                        Image(systemName: "person.fill")
                            .resizable()
                            .scaledToFit()
                            .foregroundStyle(.secondary)
                            .padding(8)
                    )
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
            if let url { cache.prefetch(url: url) }
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
