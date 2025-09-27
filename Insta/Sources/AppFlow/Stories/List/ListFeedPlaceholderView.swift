//
//  ListFeedPlaceholderView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct ListFeedPlaceholderView: View {
    let number: Int
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Circle().fill(.gray.opacity(0.3)).frame(width: 32, height: 32)
                Text("user_\(number + 1)").font(.subheadline).foregroundStyle(.secondary)
            }
            Rectangle().fill(.gray.opacity(0.15)).frame(height: 220)
                .overlay(
                    Text("Feed content placeholder")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                )
        }
        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 16, trailing: 16))
    }
}
