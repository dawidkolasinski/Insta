//
//  ImageSlidesView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct ImageSlidesView: View {
    @ObservedObject private var viewModel: ImageSlidesViewModel

    struct GesturesConfig: Equatable {
        var taps: Bool = true
        var swipes: Bool = true
        var verticalDismiss: Bool = true
        var longPressPause: Bool = true
        static let allEnabled = GesturesConfig()
    }

    private let style: ImageSlidesStyle
    private let gestures: GesturesConfig
    private let showsCounter: Bool
    private let onVerticalDismiss: (() -> Void)?
    private let holdConfig: HoldConfig

    @State private var isHolding: Bool = false
    @State private var holdWorkItem: DispatchWorkItem?
    @Environment(\.scenePhase) private var scenePhase

    init(
        slides: [ImageSlide],
        startAt: Int = 0,
        style: ImageSlidesStyle = .card(),
        gestures: GesturesConfig = .allEnabled,
        showsCounter: Bool = false,
        onVerticalDismiss: (() -> Void)? = nil,
        auto: ImageSlidesAutoConfig = .init(),
        holdConfig: HoldConfig = .init()
    ) {
        self.viewModel = ImageSlidesViewModel(slides: slides, startAt: startAt, auto: auto)
        self.style = style
        self.gestures = gestures
        self.showsCounter = showsCounter
        self.onVerticalDismiss = onVerticalDismiss
        self.holdConfig = holdConfig
    }

    init(
        sources: [ImageSource],
        startAt: Int = 0,
        style: ImageSlidesStyle = .card(),
        gestures: GesturesConfig = .allEnabled,
        showsCounter: Bool = false,
        onVerticalDismiss: (() -> Void)? = nil,
        auto: ImageSlidesAutoConfig = .init(),
        holdConfig: HoldConfig = .init()
    ) {
        let slides = sources.map { ImageSlide(source: $0) }
        self.viewModel = ImageSlidesViewModel(slides: slides, startAt: startAt, auto: auto)
        self.style = style
        self.gestures = gestures
        self.showsCounter = showsCounter
        self.onVerticalDismiss = onVerticalDismiss
        self.holdConfig = holdConfig
    }

    init(
        viewModel: ImageSlidesViewModel,
        style: ImageSlidesStyle = .card(),
        gestures: GesturesConfig = .allEnabled,
        showsCounter: Bool = false,
        onVerticalDismiss: (() -> Void)? = nil,
        holdConfig: HoldConfig = .init()
    ) {
        self.viewModel = viewModel
        self.style = style
        self.gestures = gestures
        self.showsCounter = showsCounter
        self.onVerticalDismiss = onVerticalDismiss
        self.holdConfig = holdConfig
    }

    var body: some View {
        ZStack(alignment: .top) {
            if viewModel.slides.isEmpty {
                Color.black
            } else {
                content
                progressOverlay
                if showsCounter { counterOverlay }
            }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear { viewModel.start() }
        .onDisappear {
            viewModel.stop()
            holdWorkItem?.cancel()
            holdWorkItem = nil
            if isHolding {
                isHolding = false
                viewModel.hold(false)
                viewModel.pause(false)
            }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active: viewModel.pause(false)
            case .inactive, .background: viewModel.pause(true)
            @unknown default: break
            }
        }
    }

    @ViewBuilder private var content: some View {
        let imageView = renderedImage(for: viewModel.current.source)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .animation(nil, value: viewModel.current.id)
            .overlay(navTapZones)

        let applied: AnyView = {
            switch style {
            case let .card(aspect, radius):
                return AnyView(
                    imageView
                        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .aspectRatio(aspect, contentMode: .fit)
                )
            case let .fullscreen(ignore):
                return AnyView(
                    imageView
                        .ignoresSafeArea(ignore ? .all : [])
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            }
        }()

        applied
            .simultaneousGesture(dragGesture)
    }

    private var navTapZones: some View {
        Group {
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            guard gestures.taps, !isHolding else { return }
                            viewModel.prev()
                        }
                    )
                    .simultaneousGesture(holdGesture)
                Color.clear
                    .contentShape(Rectangle())
                    .highPriorityGesture(
                        TapGesture().onEnded {
                            guard gestures.taps, !isHolding else { return }
                            viewModel.next()
                        }
                    )
                    .simultaneousGesture(holdGesture)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var progressOverlay: some View {
        LinearGradient(colors: [Color.black.opacity(0.65), .clear], startPoint: .top, endPoint: .bottom)
            .frame(height: 44)
            .overlay(
                HStack(spacing: 4) {
                    ForEach(viewModel.slides.indices, id: \.self) { index in
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.25))
                                Capsule().fill(Color.white)
                                    .frame(width: geo.size.width * filledAmount(for: index))
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .frame(height: 2), alignment: .bottom
            )
            .allowsHitTesting(false)
    }

    private func filledAmount(for index: Int) -> CGFloat {
        if index < viewModel.index { return 1 }
        if index > viewModel.index { return 0 }
        return CGFloat(min(1, max(0, viewModel.progress)))
    }

    private var counterOverlay: some View {
        LinearGradient(colors: [Color.black.opacity(0.65), .clear], startPoint: .top, endPoint: .bottom)
            .frame(height: 88)
            .overlay(
                HStack(spacing: 8) {
                    Text("\(viewModel.index + 1)/\(viewModel.slides.count)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8), alignment: .topLeading
            )
            .allowsHitTesting(false)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged { _ in viewModel.pause(true) }
            .onEnded { value in
                viewModel.pause(false)
                guard gestures.swipes else { return }
                if gestures.verticalDismiss, value.translation.height > 80 { onVerticalDismiss?(); return }
                if value.translation.width < -60 { viewModel.next() }
                else if value.translation.width > 60 { viewModel.prev() }
            }
    }

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                guard gestures.longPressPause else { return }
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
        guard gestures.longPressPause else { return }
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

    @ViewBuilder
    private func renderedImage(for source: ImageSource) -> some View {
        switch source {
        case .asset(let name): Image(name).resizable().scaledToFill()
        case .url(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                case .failure: Color.black
                default: Color.black
                }
            }
        }
    }
}
