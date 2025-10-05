//
//  StoryView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 30/09/2025.

import Combine
import SwiftUI

enum StoryAdvanceDirection {
    case previous
    case next
}

struct StoryView<ViewModel: StoryViewModelProtocol>: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var viewModel: ViewModel
    @FocusState private var isInputFocused: Bool
    @State private var isHolding: Bool = false
    @State private var holdWorkItem: DispatchWorkItem?
    @State private var messageText: String = ""
    @State private var avatarFrameGlobal: CGRect? = nil

    private let persistence: PersistenceStore

    let onDismiss: (() -> Void)?
    let style: StoryImageStyle
    let holdConfig: StoriesContainerHoldConfig
    let topOverlayHeight: CGFloat
    let overrideTopSafeAreaInset: CGFloat?
    let gestures: StoriesContainerGestureConfig
    let onLike: ((StoryItemProtocol, Bool) -> Void)?
    let onSend: ((StoryItemProtocol, String) -> Void)?
    let onReaction: ((StoryItemProtocol, String) -> Void)?
    private let quickReactions = ["😂", "😮", "😍", "🥲", "👏", "🔥"]

    private var isFullscreenIgnoringSafeAreas: Bool {
        if case let .fullscreen(ignoreSafeAreas) = style {
            return ignoreSafeAreas
        }
        return false
    }

    var body: some View {
        ZStack {
            contentContainer
            interfaceOverlay
                .opacity(isHolding ? 0 : 1)
                .animation(.easeInOut(duration: 0.22), value: isHolding)
        }
        .modifier(HoldGestureModifier(enabled: gestures.longPressPause, holdGesture: holdGesture))
        .overlay {
            if isInputFocused {
                Color.black.opacity(0.5)
                    .onTapGesture {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            isInputFocused = false
                        }
                        dismissKeyboard()
                    }
                    .transition(.opacity)
            }
        }
        .ignoresSafeArea(.keyboard)
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active: viewModel.pause(false)
            case .inactive, .background: viewModel.pause(true)
            @unknown default: break
            }
        }
        .onChange(of: viewModel.index) { _ in
            let newID = viewModel.currentItem.id
            if viewModel.cachedImage(for: newID) != nil {
                viewModel.onCurrentItemLoaded()
            }
            withAnimation(.easeInOut(duration: 0.22)) {
                messageText = ""
                isInputFocused = false
            }
        }
        .onDisappear {
            holdWorkItem?.cancel()
            holdWorkItem = nil
            if isHolding {
                isHolding = false
                viewModel.hold(false)
                viewModel.pause(false)
            }
        }
    }

    private var interfaceOverlay: some View {
        GeometryReader { geo in
            let topInset = isFullscreenIgnoringSafeAreas ? (overrideTopSafeAreaInset ?? UIWindow.topSafeAreaInset) : 0
            ZStack {
                if gestures.taps {
                    HStack(spacing: 0) {
                        Color.clear
                            .contentShape(Rectangle())
                            .highPriorityGesture(
                                TapGesture().onEnded { handleTap(direction: .previous) }
                            )
                            .accessibilityLabel("Previous story")
                        Color.clear
                            .contentShape(Rectangle())
                            .highPriorityGesture(
                                TapGesture().onEnded { handleTap(direction: .next) }
                            )
                            .accessibilityLabel("Next story")
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                }

                VStack(spacing: 0) {
                    LinearGradient(
                        colors: [Color.black.opacity(0.55), Color.black.opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: topOverlayHeight + topInset + 10)
                    .allowsHitTesting(false)
                    .ignoresSafeArea(edges: .top)
                    .overlay(alignment: .top) {
                        topBarContent
                            .padding(.top, topInset + 12)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxHeight: .infinity, alignment: .top)

                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    ZStack {
                        if isInputFocused && messageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            quickReactionsView
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                                .zIndex(2)
                        }
                    }
                    Spacer(minLength: 0)
                    bottomBar
                }
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }

    private func dismissKeyboard() {
        withAnimation(.easeInOut(duration: 0.22)) {
            isInputFocused = false
        }
    }

    init(
        viewModel: ViewModel,
        onDismiss: (() -> Void)?,
        style: StoryImageStyle,
        holdConfig: StoriesContainerHoldConfig,
        topOverlayHeight: CGFloat,
        overrideTopSafeAreaInset: CGFloat? = nil,
        gestures: StoriesContainerGestureConfig,
        persistence: PersistenceStore,
        onLike: ((StoryItemProtocol, Bool) -> Void)? = nil,
        onSend: ((StoryItemProtocol, String) -> Void)? = nil,
        onReaction: ((StoryItemProtocol, String) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.style = style
        self.holdConfig = holdConfig
        self.topOverlayHeight = topOverlayHeight
        self.overrideTopSafeAreaInset = overrideTopSafeAreaInset
        self.gestures = gestures
        self.persistence = persistence
        self.onLike = onLike
        self.onSend = onSend
        self.onReaction = onReaction
    }
    private var contentContainer: some View {
        GeometryReader { geo in
            backgroundStyled
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
    }

    @ViewBuilder
    private var backgroundStyled: some View {
        switch style {
        case let .card(aspectRatio, cornerRadius):
            backgroundBase(contentMode: .fit)
                .background(Color.clear)
                .frame(maxWidth: .infinity, alignment: .center)
                .aspectRatio(aspectRatio, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        case let .fullscreen(ignoreSafeAreas):
            let base = backgroundBase(contentMode: .fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .clipped()
                .contentShape(Rectangle())
            if ignoreSafeAreas {
                base.ignoresSafeArea()
            } else {
                base
            }
        }
    }

    @ViewBuilder
    private func backgroundBase(contentMode: ContentMode) -> some View {
        if viewModel.items.isEmpty {
            Color.black
        } else {
            let item = viewModel.currentItem
            let itemID = item.id
            let url = item.imageURL

            ZStack {
                if let cached = viewModel.cachedImage(for: itemID) {
                    cached
                        .resizable()
                        .imageScaleMode(contentMode)
                        .onAppear { viewModel.onCurrentItemLoaded() }
                } else {
                    AsyncImage(url: url, transaction: Transaction(animation: nil)) { phase in
                        switch phase {
                        case .success(let img):
                            img
                                .resizable()
                                .imageScaleMode(contentMode)
                                .onAppear {
                                    viewModel.store(image: img, for: itemID)
                                    viewModel.onCurrentItemLoaded()
                                }
                        default:
                            Color.black
                        }
                    }
                }
            }
        }
    }

    private var topBarContent: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                ForEach(Array(viewModel.items.indices), id: \.self) { barIndex in
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.25))
                            Capsule().fill(Color.white)
                                .frame(width: geo.size.width * filledAmount(for: barIndex))
                                .animation(nil, value: viewModel.index)
                        }
                    }
                }
            }
            .frame(height: 2)
            .padding(.horizontal, 8)
            .accessibilityLabel("\(viewModel.index + 1) / \(viewModel.items.count)")

            HStack(spacing: 12) {
                if let avatar = viewModel.story.user.avatarURL {
                    StoryAvatarView(url: avatar, seen: false, displayedPlace: .storyDetail)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .preference(key: AvatarFramePreferenceKey.self, value: geo.frame(in: .global))
                            }
                        )
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundStyle(.white)
                        .font(.title2)
                }
                Text(viewModel.story.user.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                Text("•").foregroundStyle(.white.opacity(0.7))
                Text("\(viewModel.index + 1)/\(viewModel.items.count)")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.9))
                Spacer()
                Button(action: { onDismiss?() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 24, weight: .regular))
                        .foregroundColor(.white)
                        .padding(8)
                }
                .accessibilityLabel("Close")
            }
            .padding(.horizontal)
        }
        .onPreferenceChange(AvatarFramePreferenceKey.self) { value in
            self.avatarFrameGlobal = value
        }
    }

    private func filledAmount(for barIndex: Int) -> CGFloat {
        if barIndex < viewModel.index { return 1 }
        if barIndex > viewModel.index { return 0 }
        return CGFloat(min(1, max(0, viewModel.progress)))
    }

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if holdWorkItem == nil { scheduleHold() }
                let dx = value.translation.width
                let dy = value.translation.height
                if (dx * dx + dy * dy) > (holdConfig.cancelDistance * holdConfig.cancelDistance) {
                    cancelHold()
                }
            }
            .onEnded { _ in finishHold() }
    }

    private func scheduleHold() {
        cancelHold()
        let work = DispatchWorkItem {
            isHolding = true
            viewModel.hold(true)
            viewModel.pause(true)
        }
        holdWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + holdConfig.minDuration, execute: work)
    }

    private func cancelHold() {
        holdWorkItem?.cancel()
        holdWorkItem = nil
        if isHolding {
            isHolding = false
            viewModel.hold(false)
            viewModel.pause(false)
        }
    }

    private func finishHold() {
        holdWorkItem?.cancel()
        holdWorkItem = nil
        if isHolding {
            isHolding = false
            viewModel.hold(false)
            viewModel.pause(false)
        }
    }

    private func handleTap(direction: StoryAdvanceDirection) {
        guard !isHolding else { return }
        viewModel.pause(false)
        viewModel.advance(to: direction)
    }

    private var quickReactionsView: some View {
        let columns = [
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10),
            GridItem(.flexible(), spacing: 10)
        ]
        return LazyVGrid(columns: columns, spacing: 18) {
            ForEach(Array(quickReactions.enumerated()), id: \.offset) { idx, emoji in
                Button {
                    onReaction?(viewModel.currentItem, emoji)
                    #if canImport(UIKit)
                    let impact = UIImpactFeedbackGenerator(style: .light)
                    impact.impactOccurred()
                    dismissKeyboard()
                    #endif
                } label: {
                    Text(emoji)
                        .font(.system(size: 44))
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 60)
    }

    private var bottomBar: some View {
        StoryBottomBarView(
            text: $messageText,
            isLiked: .constant(persistence.isLiked(viewModel.currentItem.id)),
            quickReactions: quickReactions,
            onFocusChanged: { focused in
                if focused {
                    viewModel.pause(true)
                    viewModel.hold(true)
                } else {
                    viewModel.hold(false)
                    viewModel.pause(false)
                }
                withAnimation(.easeInOut(duration: 0.22)) {
                    isInputFocused = focused
                }
            },
            onSend: {
                let trimmed = messageText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                onSend?(viewModel.currentItem, trimmed)
                withAnimation(.easeInOut(duration: 0.22)) {
                    messageText = ""
                    isInputFocused = false
                }
                dismissKeyboard()
            },
            onLike: {
                persistence.toggleLike(viewModel.currentItem.id)
                onLike?(viewModel.currentItem, persistence.isLiked(viewModel.currentItem.id))
            },
            onReaction: { emoji in
                onReaction?(viewModel.currentItem, emoji)
            }
        )
        .focused($isInputFocused)
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }
}

private struct AvatarFramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect? = nil
    static func reduce(value: inout CGRect?, nextValue: () -> CGRect?) {
        value = nextValue() ?? value
    }
}

private struct HoldGestureModifier<G: Gesture>: ViewModifier {
    let enabled: Bool
    let holdGesture: G

    func body(content: Content) -> some View {
        if enabled {
            content.simultaneousGesture(holdGesture)
        } else {
            content
        }
    }
}
