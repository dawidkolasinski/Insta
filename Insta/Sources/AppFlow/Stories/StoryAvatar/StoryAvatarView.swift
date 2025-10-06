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
    @State private var triedDiskLoad = false

    var body: some View {
        Group {
            if let url {
                if let cached = cache.image(for: url) {
                    cached
                        .resizable()
                        .scaledToFill()
                } else {
                    Color.clear
                        .onAppear {
                            if !triedDiskLoad {
                                cache.loadFromDiskIfNeeded(for: url)
                                triedDiskLoad = true
                            }
                        }
                        .overlay(
                            ZStack {
                                StoryAvatarPlaceholderView(displayedPlace: displayedPlace)
                                ProgressView()
                                    .progressViewStyle(.circular)
                                    .frame(width: displayedPlace.avatarWidth * 0.4, height: displayedPlace.avatarWidth * 0.4)
                            }
                        )
                    if triedDiskLoad && cache.image(for: url) == nil {
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
                                StoryAvatarPlaceholderView(displayedPlace: displayedPlace)
                            default:
                                ZStack {
                                    StoryAvatarPlaceholderView(displayedPlace: displayedPlace)
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                        .frame(width: displayedPlace.avatarWidth * 0.4, height: displayedPlace.avatarWidth * 0.4)
                                }
                            }
                        }
                    }
                }
            } else {
                StoryAvatarPlaceholderView(displayedPlace: displayedPlace)
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
