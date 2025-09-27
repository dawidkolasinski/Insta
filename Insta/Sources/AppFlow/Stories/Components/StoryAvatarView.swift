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

    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let img): img.resizable().scaledToFill()
            case .failure: Color.gray.opacity(0.2)
            default: ProgressView()
            }
        }
        .equalWidthAndHeight(76)
        .clipShape(Circle())
        .padding(8)
        .overlay {
            if seen {
                Circle()
                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 4)
            } else {
                Circle()
                    .strokeBorder(AngularGradient(colors: [.pink, .orange, .yellow, .pink], center: .center), lineWidth: 4)
            }
        }
        .accessibilityLabel(seen ? "Story seen" : "Story unseen")
    }
}
