//
//  StoryPlayerView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Combine
import SwiftUI

struct StoryPlayerView: View {
    let story: Story
    @StateObject private var viewModel: StoryPlayerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var didStart = false
    @State private var inputText: String = ""
    let onPrevUser: ((Story) -> Story?)?
    let onNextUser: ((Story) -> Story?)?

    var body: some View {
        VStack(spacing: 0) {
            contentContainer
            bottomBar
                .safeAreaPadding(.bottom)
        }
        .overlay(alignment: .top) {
            topOverlay
                .safeAreaPadding(.top)
        }
        .background (Color.black.ignoresSafeArea())
        .onDisappear { viewModel.stop() }
        .preferredColorScheme(.dark)
        .onAppear { viewModel.setDismiss { dismiss() } }
    }

    private var contentContainer: some View {
        ZStack {
            backgroundImage
            heartOverlayLayer
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.pause(false)
                        withTransaction(Transaction(animation: nil)) {
                            viewModel.prevOrRestart()
                        }
                    }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.pause(false)
                        withTransaction(Transaction(animation: nil)) {
                            viewModel.next()
                        }
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .center)
        .aspectRatio(9/16, contentMode: .fit)
        .animation(nil, value: viewModel.currentItem.id)
        .animation(nil, value: viewModel.currentStory.id)
        .transaction { $0.animation = nil }
        .highPriorityGesture(dragGesture)
        .simultaneousGesture(longPressGesture)
        .simultaneousGesture(doubleTapGesture)
    }

    private var backgroundImage: some View {
        AsyncImage(url: viewModel.currentItem.imageURL) { phase in
            switch phase {
            case .success(let img):
                img.resizable().scaledToFill()
                    .clipped()
                    .onAppear { if !didStart { didStart = true; viewModel.start() } }
            case .failure:
                Color.black
                    .onAppear { if !didStart { didStart = true; viewModel.start() } }
            default:
                Color.black
            }
        }
        .id(viewModel.currentItem.id)
    }

    private var topOverlay: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color.black.opacity(0.65), Color.black.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            VStack(spacing: 12) {
                ProgressBarView(count: viewModel.userStories.count, currentIndex: viewModel.currentIndex, progress: viewModel.progress)
                HStack(spacing: 12) {
                    StoryAvatarView(url: viewModel.currentStory.user.avatarURL, seen: false, displayedPlace: .storyDetail)
                    Text(viewModel.currentStory.user.name).font(.headline).foregroundStyle(.white)
                    Text("•").foregroundStyle(.white.opacity(0.7))
                    Text("\(viewModel.currentIndex + 1)/\(viewModel.userStories.count)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    HStack(spacing: 16) {
                        Button(action: { /* more options */ }) {
                            Image(systemName: "ellipsis").font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                        }
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark").font(.system(size: 18, weight: .semibold)).foregroundStyle(.white)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 12)
        }
        .animation(nil, value: viewModel.currentIndex)
    }

    private var heartOverlay: some View {
        HeartBurstView(visible: Binding(get: { viewModel.showHeart }, set: { _ in }))
    }

    private var heartOverlayLayer: some View {
        Group {
            switch viewModel.heartPulse {
            case .like?:
                Image(systemName: "heart.fill")
                    .font(.system(size: 120, weight: .regular))
                    .foregroundColor(.red)
                    .transition(.scale.combined(with: .opacity))
            case .dislike?:
                Image(systemName: "heart")
                    .font(.system(size: 110, weight: .regular))
                    .foregroundColor(.white)
                    .transition(.scale.combined(with: .opacity))
            case nil:
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .allowsHitTesting(false)
    }

    private var bottomBar: some View {
        HStack(spacing: 8) {
            Button {

            } label: {
                Image(systemName: "message")
                    .font(.system(size: 18, weight: .semibold))
            }

            ZStack(alignment: .leading) {
                if inputText.isEmpty {
                    Text("Send message")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                }
                TextField("Send message", text: $inputText)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Color.white.opacity(0.12),
                        in: Capsule()
                    )
                    .foregroundColor(.white)
              }

            Button { viewModel.toggleLike(viewModel.currentItem.id) } label: {
                Image(systemName: viewModel.isLiked(viewModel.currentItem.id) ? "heart.fill" : "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(viewModel.isLiked(viewModel.currentItem.id) ? .red : .white)
            }
            .accessibilityLabel(viewModel.isLiked(viewModel.currentItem.id) ? "Unlike" : "Like")

            Button {

            } label: {
                Image(systemName: "paperplane")
                    .font(.system(size: 18, weight: .semibold))
            }
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { value in
                viewModel.pause(false)
                if value.translation.height > 80 {
                    dismiss()
                } else if value.translation.width < -60 {
                    // swipe left → next user (or dismiss if none)
                    if let next = onNextUser?(viewModel.currentStory) {
                        didStart = false
                        viewModel.load(story: next, startAt: 0)
                        viewModel.start()
                    } else {
                        dismiss()
                    }
                } else if value.translation.width > 60 {
                    // swipe right → previous user (or dismiss if none)
                    if let prev = onPrevUser?(viewModel.currentStory) {
                        didStart = false
                        viewModel.load(story: prev, startAt: 0)
                        viewModel.start()
                    } else {
                        dismiss()
                    }
                }
            }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.35)
            .onChanged { _ in viewModel.pause(true) }
            .onEnded { _ in viewModel.pause(false) }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2).onEnded { viewModel.toggleLike(viewModel.currentItem.id) }
    }

    init(story: Story, startAt: Int = 0, onPrevUser: ((Story) -> Story?)? = nil, onNextUser: ((Story) -> Story?)? = nil) {
        self.story = story
        self.onPrevUser = onPrevUser
        self.onNextUser = onNextUser
        _viewModel = StateObject(wrappedValue: StoryPlayerViewModel(
            story: story,
            startAt: startAt,
            onPrevUser: onPrevUser,
            onNextUser: onNextUser
        ))
    }
}
