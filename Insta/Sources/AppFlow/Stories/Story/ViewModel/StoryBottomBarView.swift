//
//  StoryBottomBar.swift
//  Insta
//
//  Created by Dawid Kolasinski on 30/09/2025.

import SwiftUI

struct StoryBottomBarView: View {
    @Binding var text: String
    @Binding var isLiked: Bool

    let quickReactions: [String]
    let onFocusChanged: (Bool) -> Void
    let onSend: () -> Void
    let onLike: () -> Void
    let onReaction: (String) -> Void

    @FocusState private var isFocused: Bool
    @State private var heartScale: CGFloat = 1.0

    var body: some View {
        HStack(spacing: 8) {
            if !isFocused {
                Image(systemName: "message")
                    .foregroundColor(.white)
                    .font(.system(size: 20, weight: .regular))
                    .padding(.leading, 4)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            TextField(
                "",
                text: $text,
                prompt: Text("Send message...").foregroundStyle(.white)
            )
            .textFieldStyle(.plain)
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color.clear, in: Capsule())
            .focused($isFocused)
            .onChange(of: isFocused) { focused in
                withAnimation(.easeInOut(duration: 0.22)) {
                    onFocusChanged(focused)
                }
            }
            .submitLabel(.send)
            .onSubmit {
                onSend()
            }
            .overlay {
                Capsule()
                    .strokeBorder(Color.white)
            }

            if !isFocused {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        isLiked.toggle()
                        heartScale = 1.3
                    }
                    onLike()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.6).delay(0.05)) {
                        heartScale = 1.0
                    }
                } label: {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .foregroundColor(isLiked ? .red : .white)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(10)
                        .background(Color.black.opacity(0.35), in: Circle())
                        .scaleEffect(heartScale)
                }
                .accessibilityLabel(isLiked ? "Unlike" : "Like")
                .transition(.move(edge: .trailing).combined(with: .opacity))

                Button {
                    onSend()
                } label: {
                    Image(systemName: "paperplane")
                        .foregroundStyle(.white)
                        .font(.system(size: 18, weight: .semibold))
                }
                .accessibilityLabel("Send")
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .padding(.horizontal, 4)
        .animation(.easeInOut(duration: 0.22), value: isFocused)
    }
}
