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
    @State private var heartOffsetY: CGFloat = 0
    @State private var animatingLike: Bool = false

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
                    animatingLike = true
                    withAnimation(.interpolatingSpring(stiffness: 250, damping: 6)) {
                        heartScale = 1.4
                        heartOffsetY = -24
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                        isLiked.toggle()
                        onLike()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                            heartScale = 1.0
                            heartOffsetY = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                            animatingLike = false
                        }
                    }
                } label: {
                    Image(systemName: isLiked || animatingLike ? "heart.fill" : "heart")
                        .foregroundColor(isLiked || animatingLike ? .red : .white)
                        .font(.system(size: 20, weight: .semibold))
                        .padding(10)
                        .background(Color.black.opacity(0.35), in: Circle())
                        .scaleEffect(heartScale)
                        .offset(y: heartOffsetY)
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
