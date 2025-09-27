//
//  StoryRowView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct StoryRowView: View {
    let story: Story
    @EnvironmentObject private var persistence: PersistenceStore

    private var isEntireStorySeen: Bool {
        story.items.allSatisfy { persistence.isSeen($0.id) }
    }

    var body: some View {
        HStack(spacing: 12) {
            StoryAvatarView(url: story.user.avatarURL, seen: isEntireStorySeen)
            VStack(alignment: .leading, spacing: 4) {
                Text(story.user.name).font(.headline)
                Text("\(story.items.count) items")
                    .font(.subheadline).foregroundColor(.secondary)
            }
            Spacer()
            if story.items.contains(where: { persistence.isLiked($0.id) }) {
                Image(systemName: "heart.fill").foregroundStyle(.red)
                    .accessibilityHidden(true)
            }
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}
