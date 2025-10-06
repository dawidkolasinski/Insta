//
//  StoryAvatarPlaceholder.swift
//  Insta
//
//  Created by Dawid Kolasinski on 06/10/2025.
//

import SwiftUI

struct StoryAvatarPlaceholderView: View {
    let displayedPlace: AvatarDisplayedPlace

    var body: some View {
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
