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



    var body: some View {
        ZStack {
            AsyncImage(url: viewModel.currentItem.imageURL) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill().ignoresSafeArea()
                case .failure: Color.black.ignoresSafeArea()
                default: Color.black.ignoresSafeArea()
                }
            }
            .overlay(alignment: .top) {
                VStack(spacing: 12) {
                    ProgressBarView(count: viewModel.userStories.count, currentIndex: viewModel.currentIndex, progress: viewModel.progress)
                    HStack(spacing: 12) {
                        StoryAvatarView(url: story.user.avatarURL, seen: false)
                            .frame(width: 28, height: 28)
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
            .overlay { HeartBurstView(visible: Binding(get: { viewModel.showHeart }, set: { _ in })) }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onEnded { value in
                        if value.translation.height > 80 { dismiss() }
                        else if value.translation.width < -60 { viewModel.next() }
                        else if value.translation.width > 60 { viewModel.prev() }
                    }
            )
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.15)
                    .onChanged { _ in viewModel.pause(true) }
                    .onEnded { _ in viewModel.pause(false) }
            )
            .simultaneousGesture(
                TapGesture(count: 2).onEnded { viewModel.toggleLike(viewModel.currentItem.id) }
            )
            .overlay(alignment: .bottom) {
                HStack {
                    Button { viewModel.prev() } label: { Image(systemName: "chevron.left") }
                    Spacer()
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                    Spacer()
                    Button { viewModel.next() } label: { Image(systemName: "chevron.right") }
                }
                .foregroundStyle(.white)
                .padding()
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onDisappear { viewModel.stop() }
    }

    init(story: Story, startAt: Int = 0) {
        self.story = story
        let persistence = PersistenceStore() //TODO: move to di, make sure same instance
        _viewModel = StateObject(wrappedValue: StoryPlayerViewModel(items: story.items, startAt: startAt, persistence: persistence))
    }
}
