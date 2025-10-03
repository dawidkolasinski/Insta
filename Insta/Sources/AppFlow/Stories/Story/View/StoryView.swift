//
//  StoryView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI
import Combine

enum StoryAdvanceDirection {
    case previous
    case next
}

struct StoryView<ViewModel: StoryViewModelProtocol>: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var viewModel: ViewModel
    @State private var isHolding: Bool = false
    @State private var holdWorkItem: DispatchWorkItem?

    let onDismiss: (() -> Void)?
    let style: StoryImageStyle
    let holdConfig: StoriesContainerHoldConfig
    let topOverlayHeight: CGFloat
    let overrideTopSafeAreaInset: CGFloat?
    let gestures: StoriesContainerGestureConfig

    private var isFullscreenIgnoringSafeAreas: Bool {
        if case let .fullscreen(ignoreSafeAreas) = style {
            return ignoreSafeAreas
        }
        return false
    }

    var body: some View {
        VStack(spacing: 0) {
            contentContainer
        }
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

    init(
        viewModel: ViewModel,
        onDismiss: (() -> Void)?,
        style: StoryImageStyle,
        holdConfig: StoriesContainerHoldConfig,
        topOverlayHeight: CGFloat,
        overrideTopSafeAreaInset: CGFloat? = nil,
        gestures: StoriesContainerGestureConfig
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.style = style
        self.holdConfig = holdConfig
        self.topOverlayHeight = topOverlayHeight
        self.overrideTopSafeAreaInset = overrideTopSafeAreaInset
        self.gestures = gestures
    }

    private var contentContainer: some View {
        GeometryReader { geo in
            let topInset = isFullscreenIgnoringSafeAreas ? (overrideTopSafeAreaInset ?? UIWindow.topSafeAreaInset) : 0

            ZStack {
                backgroundStyled

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
                } else {
                    Color.clear
                        .frame(width: geo.size.width, height: geo.size.height)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.black.opacity(0.65), Color.black.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: topOverlayHeight + topInset)
                .allowsHitTesting(false)
                .ignoresSafeArea(edges: .top)
            }
            .overlay(alignment: .top) {
                topBarContent
                    .padding(.top, topInset + 12)
            }
            .modifier(HoldGestureModifier(enabled: gestures.longPressPause, holdGesture: holdGesture))
        }
    }

    @ViewBuilder
    private var backgroundStyled: some View {
        switch style {
        case let .card(aspectRatio, cornerRadius):
            backgroundBase(contentMode: .fit)
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
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.55), in: Circle())
                }
                .accessibilityLabel("Close")
            }
            .padding(.horizontal)
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
