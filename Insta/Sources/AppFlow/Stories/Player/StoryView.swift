//
//  StoryView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI
import Combine

struct StoryView: View {
    @ObservedObject var viewModel: StoryViewModel
    let onDismiss: (() -> Void)?
    let style: ImageSlidesStyle
    let holdConfig: HoldConfig
    let topOverlayHeight: CGFloat
    @Environment(\.scenePhase) private var scenePhase

    @State private var isHolding: Bool = false
    @State private var holdWorkItem: DispatchWorkItem?

    init(
        viewModel: StoryViewModel,
        onDismiss: (() -> Void)?,
        style: ImageSlidesStyle,
        holdConfig: HoldConfig,
        topOverlayHeight: CGFloat
    ) {
        self.viewModel = viewModel
        self.onDismiss = onDismiss
        self.style = style
        self.holdConfig = holdConfig
        self.topOverlayHeight = topOverlayHeight
    }

    var body: some View {
        VStack(spacing: 0) {
            contentContainer
        }
        .background(Color.clear)
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active: viewModel.pause(false)
            case .inactive, .background: viewModel.pause(true)
            @unknown default: break
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

    private var contentContainer: some View {
        ZStack {
            backgroundImage
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            guard !isHolding else { return }
                            viewModel.pause(false)
                            withTransaction(Transaction(animation: nil)) { viewModel.prev() }
                        }
                    )
                    .simultaneousGesture(holdGesture)
                Color.clear
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            guard !isHolding else { return }
                            viewModel.pause(false)
                            withTransaction(Transaction(animation: nil)) { viewModel.next() }
                        }
                    )
                    .simultaneousGesture(holdGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .overlay(alignment: .top) { topOverlay }
        .modifier(StyleApplier(style: style))
        .animation(nil, value: (viewModel.currentItem as StoryItemProtocol).id)
        .animation(nil, value: (viewModel.story as StoryProtocol).id)
    }

    private struct StyleApplier: ViewModifier {
        let style: ImageSlidesStyle
        func body(content: Content) -> some View {
            switch style {
            case let .card(aspect, radius):
                content
                    .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .aspectRatio(aspect, contentMode: .fit)
            case let .fullscreen(ignore):
                content
                    .ignoresSafeArea(ignore ? .all : [])
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private var backgroundImage: some View {
        if viewModel.items.isEmpty {
            Color.black
        } else {
            let item = (viewModel.currentItem as StoryItemProtocol)
            let itemID = item.id
            let url = item.imageURL

            if let cached = viewModel.cachedImage(for: itemID) {
                cached
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .onAppear { viewModel.onCurrentItemLoaded() }
            } else {
                AsyncImage(url: url, transaction: Transaction(animation: nil)) { phase in
                    switch phase {
                    case .success(let img):
                        img
                            .resizable()
                            .scaledToFill()
                            .clipped()
                            .onAppear {
                                viewModel.store(image: img, for: itemID)
                                viewModel.onCurrentItemLoaded()
                            }
                    case .failure:
                        Color.black
                            .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { viewModel.onCurrentItemLoaded() } }
                    default:
                        Color.black
                            .onAppear { DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { viewModel.onCurrentItemLoaded() } }
                    }
                }
            }
        }
    }

    private var topOverlay: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [Color.black.opacity(0.65), Color.black.opacity(0.0)], startPoint: .top, endPoint: .bottom)
                .frame(height: topOverlayHeight)
                .allowsHitTesting(false)

            VStack(spacing: 8) {
                HStack(spacing: 4) {
                    ForEach(Array(viewModel.items.indices), id: \.self) { barIndex in
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.25))
                                Capsule().fill(Color.white)
                                    .frame(width: geo.size.width * filledAmount(for: barIndex))
                            }
                        }
                    }
                }
                .frame(height: 2)
                .padding(.horizontal, 8)
                .accessibilityLabel("\(viewModel.index + 1) z \(viewModel.items.count)")

                HStack(spacing: 12) {
                    if let avatar = (viewModel.story.user as StoryUserProtocol).avatarURL {
                        StoryAvatarView(url: avatar, seen: false, displayedPlace: .storyDetail)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title2)
                    }
                    Text((viewModel.story.user as StoryUserProtocol).name)
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
                    .accessibilityLabel("Zamknij")
                }
                .padding(.horizontal)
            }
            .padding(.top, 12)
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
}
