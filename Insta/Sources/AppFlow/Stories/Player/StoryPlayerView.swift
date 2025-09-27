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

    var body: some View {
        ZStack {
            // Solid base to prevent white flash on appear
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                contentContainer
                bottomBar
                    .safeAreaPadding(.bottom)
            }
            .overlay(alignment: .top) {
                topOverlay
                    .safeAreaPadding(.top)
            }
        }
        .onDisappear { viewModel.stop() }
        .preferredColorScheme(.dark)
    }

    private var contentContainer: some View {
        ZStack {
            backgroundImage
            heartOverlayLayer
            Rectangle()
                .fill(Color.clear)
                .contentShape(Rectangle())
                .gesture(dragGesture)
                .simultaneousGesture(longPressGesture)
                .simultaneousGesture(doubleTapGesture)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .center)
        .aspectRatio(9/16, contentMode: .fit)
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
    }

    private var topOverlay: some View {
        VStack(spacing: 12) {
            ProgressBarView(count: viewModel.userStories.count, currentIndex: viewModel.currentIndex, progress: viewModel.progress)
            HStack(spacing: 12) {
                StoryAvatarView(url: story.user.avatarURL, seen: false, displayedPlace: .storyDetail)
                Text(story.user.name).font(.headline).foregroundStyle(.white)
                Spacer()
                Button { viewModel.toggleLike(viewModel.currentItem.id) } label: {
                    Image(systemName: viewModel.isLiked(viewModel.currentItem.id) ? "heart.fill" : "heart")
                        .foregroundStyle(.white)
                        .font(.system(size: 20, weight: .semibold))
                }
                .accessibilityLabel(viewModel.isLiked(viewModel.currentItem.id) ? "Unlike" : "Like")
            }
            .padding(.horizontal)
        }
        .padding(.top, 12)
    }

    private var heartOverlay: some View {
        HeartBurstView(visible: Binding(get: { viewModel.showHeart }, set: { _ in }))
    }

    private var heartOverlayLayer: some View {
        HeartBurstView(visible: Binding(get: { viewModel.showHeart }, set: { _ in }))
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
            }

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
                if value.translation.height > 80 { dismiss() }
                else if value.translation.width < -60 { viewModel.next() }
                else if value.translation.width > 60 { viewModel.prev() }
            }
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.15)
            .onChanged { _ in viewModel.pause(true) }
            .onEnded { _ in viewModel.pause(false) }
    }

    private var doubleTapGesture: some Gesture {
        TapGesture(count: 2).onEnded { viewModel.toggleLike(viewModel.currentItem.id) }
    }

    init(story: Story, startAt: Int = 0) {
        self.story = story
        _viewModel = StateObject(wrappedValue: StoryPlayerViewModel(items: story.items, startAt: startAt))
    }
}
