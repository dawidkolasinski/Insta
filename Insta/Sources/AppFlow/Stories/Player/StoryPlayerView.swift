//
//  StoryPlayerView.swift
//  Insta (Refactored as reusable component)
//
//  Created by Dawid Kolasinski on 27/09/2025.
//  Refactor: protocol-oriented, testable, generic, app-agnostic component.
//

import Combine
import SwiftUI

struct StoriesComponentConfig: Equatable {
    var style: ImageSlidesStyle = .card()
    var gestures: ImageSlidesView.GesturesConfig = .allEnabled
    var dimmerMaxOpacity: Double = 0.75
}

private enum DragAxis { case none, horizontal, vertical }

protocol StoryItemProtocol {
    var id: String { get }
    var imageURL: URL? { get }
}

protocol StoryUserProtocol {
    var name: String { get }
    var avatarURL: URL? { get }
}

protocol StoryProtocol {
    var id: String { get }
    var user: StoryUserProtocol { get }
    var items: [any StoryItemProtocol] { get }
}

protocol StoriesFeedProtocol {
    var stories: [any StoryProtocol] { get }
    var startIndex: Int { get }
}

struct AnyStoryItem: StoryItemProtocol {
    let id: String
    let imageURL: URL?
    init(id: String, imageURL: URL?) { self.id = id; self.imageURL = imageURL }
}

struct AnyStoryUser: StoryUserProtocol {
    let name: String
    let avatarURL: URL?
    init(name: String, avatarURL: URL?) { self.name = name; self.avatarURL = avatarURL }
}

struct AnyStory: StoryProtocol {
    let id: String
    let user: StoryUserProtocol
    let items: [any StoryItemProtocol]
    init(id: String, user: StoryUserProtocol, items: [any StoryItemProtocol]) {
        self.id = id; self.user = user; self.items = items
    }
}

struct OffsetScaleOpacityModifier: ViewModifier {
    let offset: CGSize
    let scale: CGFloat
    let opacity: Double
    let rotation: Double
    let blur: CGFloat
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotation3DEffect(.degrees(rotation), axis: (x: 1, y: 0, z: 0))
            .blur(radius: blur)
            .opacity(opacity)
            .offset(offset)
    }
}

extension AnyTransition {
    static var storiesDeck: AnyTransition {
        let insertion = AnyTransition.modifier(
            active: OffsetScaleOpacityModifier(
                offset: CGSize(width: 0, height: 20),
                scale: 0.88,
                opacity: 0.0,
                rotation: 8,
                blur: 6
            ),
            identity: OffsetScaleOpacityModifier(
                offset: .zero,
                scale: 1.0,
                opacity: 1.0,
                rotation: 0,
                blur: 0
            )
        )
        let removal = AnyTransition.modifier(
            active: OffsetScaleOpacityModifier(
                offset: .zero,
                scale: 0.9,
                opacity: 0.0,
                rotation: 0,
                blur: 0
            ),
            identity: OffsetScaleOpacityModifier(
                offset: .zero,
                scale: 1.0,
                opacity: 1.0,
                rotation: 0,
                blur: 0
            )
        )
        return .asymmetric(insertion: insertion, removal: removal)
    }
}

enum ImageSource: Equatable {
    case url(URL)
    case asset(String)
}

struct ImageSlide: Identifiable, Equatable {
    let id: String
    let source: ImageSource
    init(id: String = UUID().uuidString, source: ImageSource) {
        self.id = id
        self.source = source
    }
}

struct ImageSlidesAutoConfig: Equatable {
    var enabled: Bool = true
    var durationPerSlide: TimeInterval = 5.0
    var tick: TimeInterval = 0.05
    var loops: Bool = false
}

final class ImageSlidesViewModel: ObservableObject {
    @Published private(set) var slides: [ImageSlide]
    @Published private(set) var index: Int
    @Published private(set) var progress: Double = 0
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var holdCount: Int = 0

    private let auto: ImageSlidesAutoConfig
    private var timerRef: Timer?

    init(slides: [ImageSlide], startAt: Int = 0, auto: ImageSlidesAutoConfig = .init()) {
        self.slides = slides
        self.index = max(0, min(startAt, max(0, slides.count - 1)))
        self.auto = auto
    }

    var current: ImageSlide { slides[index] }

    func start() {
        stop()
        progress = 0
        guard auto.enabled, slides.count > 0 else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: auto.tick, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isPaused || self.holdCount > 0 { return }
            self.progress += self.auto.tick / max(0.0001, self.auto.durationPerSlide)
            if self.progress >= 1 {
                self.progress = 0
                if self.index < self.slides.count - 1 { self.index += 1 }
                else if self.auto.loops { self.index = 0 }
                else { self.stop() }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timerRef = timer
    }

    func stop() { timerRef?.invalidate(); timerRef = nil }
    func pause(_ value: Bool) { isPaused = value }
    func hold(_ value: Bool) {
        if value { holdCount += 1 } else { holdCount = max(0, holdCount - 1) }
    }

    func next() {
        progress = 0
        if index < slides.count - 1 { index += 1 }
        else if auto.loops { index = 0 }
    }
    func prev() {
        progress = 0
        if index > 0 { index -= 1 }
        else if auto.loops { index = max(0, slides.count - 1) }
    }

    deinit { stop() }
}

enum ImageSlidesStyle: Equatable { case card(aspectRatio: CGFloat = 9/16, cornerRadius: CGFloat = 16), fullscreen(ignoreSafeAreas: Bool = true) }

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

    @State private var isHolding: Bool = false
    @State private var holdWorkItem: DispatchWorkItem?

    init(
        slides: [ImageSlide],
        startAt: Int = 0,
        style: ImageSlidesStyle = .card(),
        gestures: GesturesConfig = .allEnabled,
        showsCounter: Bool = false,
        onVerticalDismiss: (() -> Void)? = nil,
        auto: ImageSlidesAutoConfig = .init()
    ) {
        self.viewModel = ImageSlidesViewModel(slides: slides, startAt: startAt, auto: auto)
        self.style = style
        self.gestures = gestures
        self.showsCounter = showsCounter
        self.onVerticalDismiss = onVerticalDismiss
    }

    init(
        sources: [ImageSource],
        startAt: Int = 0,
        style: ImageSlidesStyle = .card(),
        gestures: GesturesConfig = .allEnabled,
        showsCounter: Bool = false,
        onVerticalDismiss: (() -> Void)? = nil,
        auto: ImageSlidesAutoConfig = .init()
    ) {
        let slides = sources.map { ImageSlide(source: $0) }
        self.viewModel = ImageSlidesViewModel(slides: slides, startAt: startAt, auto: auto)
        self.style = style
        self.gestures = gestures
        self.showsCounter = showsCounter
        self.onVerticalDismiss = onVerticalDismiss
    }

    init(
        viewModel: ImageSlidesViewModel,
        style: ImageSlidesStyle = .card(),
        gestures: GesturesConfig = .allEnabled,
        showsCounter: Bool = false,
        onVerticalDismiss: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.style = style
        self.gestures = gestures
        self.showsCounter = showsCounter
        self.onVerticalDismiss = onVerticalDismiss
    }

    var body: some View {
        ZStack(alignment: .top) {
            content
            progressOverlay
            if showsCounter { counterOverlay }
        }
        .background(Color.black.ignoresSafeArea())
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
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
                if value.translation.height > 80 { onVerticalDismiss?(); return }
                if value.translation.width < -60 { viewModel.next() }
                else if value.translation.width > 60 { viewModel.prev() }
            }
    }

    private var holdGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .local)
            .onChanged { value in
                if holdWorkItem == nil { scheduleHold() }
                let dx = value.translation.width
                let dy = value.translation.height
                if (dx * dx + dy * dy) > (24 * 24) {
                    cancelHold()
                }
            }
            .onEnded { _ in
                finishHold()
            }
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: work)
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

struct StoriesContainerView: View {
    @StateObject private var containerVM: StoriesContainerViewModel
    @State private var horizontalDrag: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var isInteractiveSwitch: Bool = false

    @State private var verticalDrag: CGFloat = 0
    @State private var containerHeight: CGFloat = 0
    @State private var containerOpacity: Double = 1
    @State private var activeDragAxis: DragAxis = .none
    @State private var isVerticalSnappingBack: Bool = false

    private let onDismiss: (() -> Void)?
    @Binding private var dismissProgress: CGFloat
    private let config: StoriesComponentConfig
    init(
        feed: any StoriesFeedProtocol,
        onDismiss: (() -> Void)? = nil,
        dismissProgress: Binding<CGFloat> = .constant(0),
        config: StoriesComponentConfig = .init()
    ) {
        self.onDismiss = onDismiss
        self._dismissProgress = dismissProgress
        self.config = config
        _containerVM = StateObject(wrappedValue: StoriesContainerViewModel(feed: feed))
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let verticalProgress = min(1, max(0, verticalDrag / max(1, height)))
            let easedVertical = CGFloat(pow(Double(verticalProgress), 0.25))
            let showNeighbors = (activeDragAxis != .vertical && verticalDrag == 0 && !isVerticalSnappingBack)

            Color.clear.onAppear { containerWidth = width; containerHeight = height }

            ZStack {
                if !containerVM.stories.isEmpty {
                    if showNeighbors, let prev = containerVM.prevVM {
                        StoryView(viewModel: prev, onDismiss: onDismiss, style: config.style)
                            .id((prev.story as StoryProtocol).id)
                            .offset(x: horizontalDrag - width)
                            .allowsHitTesting(false)
                            .zIndex(0)
                    }
                    if showNeighbors, let next = containerVM.nextVM {
                        StoryView(viewModel: next, onDismiss: onDismiss, style: config.style)
                            .id((next.story as StoryProtocol).id)
                            .offset(x: horizontalDrag + width)
                            .allowsHitTesting(false)
                            .zIndex(0)
                    }
                    StoryView(viewModel: containerVM.storyVM, onDismiss: onDismiss, style: config.style)
                        .id((containerVM.currentStory as StoryProtocol).id)
                        .offset(x: horizontalDrag)
                        .zIndex(1)
                } else {
                    Text("No stories available")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
            .offset(y: verticalDrag)
            .scaleEffect(1 - 0.50 * easedVertical)
            .opacity(containerOpacity * max(0.0, 1 - 0.95 * Double(easedVertical)))
        }
        .background(Color.clear.ignoresSafeArea())
        .simultaneousGesture(dragGesture)
        .onAppear {
            containerVM.onDismiss = {
                let baseOvershoot: CGFloat = 0.45
                let targetY = max(containerHeight + containerHeight * baseOvershoot, 1)
                let remaining = max(0, targetY - verticalDrag)
                let duration = min(max(Double(remaining / 1400), 0.14), 0.26)
                withAnimation(.timingCurve(0.24, 0.92, 0.30, 1.0, duration: duration)) {
                    verticalDrag = targetY
                    containerOpacity = 0
                    horizontalDrag = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    onDismiss?()
                    withTransaction(Transaction(animation: nil)) {
                        verticalDrag = 0
                        dismissProgress = 0
                        containerOpacity = 1
                        horizontalDrag = 0
                    }
                }
            }
            containerVM.onResetDrag = {
                withTransaction(Transaction(animation: nil)) {
                    horizontalDrag = 0
                    verticalDrag = 0
                    dismissProgress = 0
                    isInteractiveSwitch = false
                    activeDragAxis = .none
                }
                containerVM.storyVM.pause(false)
            }
        }
        .onChange(of: verticalDrag) { newValue in
            let height = max(1, containerHeight)
            dismissProgress = min(1, max(0, newValue / height))
        }
        .onDisappear { containerVM.onDismiss = nil; containerVM.onResetDrag = nil }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .local)
            .onChanged { value in
                let deltaX = value.translation.width
                let deltaY = value.translation.height
                let hysteresis: CGFloat = 12

                if activeDragAxis == .none {
                    if abs(deltaX) > abs(deltaY) + hysteresis { activeDragAxis = .horizontal }
                    else if abs(deltaY) > abs(deltaX) + hysteresis { activeDragAxis = .vertical }
                }

                if activeDragAxis != .none {
                    containerVM.storyVM.pause(true)
                }

                switch activeDragAxis {
                case .horizontal:
                    horizontalDrag = deltaX
                    verticalDrag = 0
                    dismissProgress = 0
                case .vertical:
                    verticalDrag = max(0, deltaY)
                    let drift = deltaX
                    let maxDrift = containerWidth * 0.3
                    horizontalDrag = min(max(drift, -maxDrift), maxDrift)
                    isVerticalSnappingBack = false
                case .none:
                    break
                }
            }
            .onEnded { value in
                let endAxis = activeDragAxis
                let deltaX = value.translation.width
                let endVertical = max(0, value.translation.height)
                let threshold: CGFloat = max(60, containerWidth * 0.18)

                if endAxis == .vertical {
                    let projectedVertical = max(0, value.predictedEndTranslation.height)
                    let distanceRatio = containerHeight > 0 ? (endVertical / containerHeight) : 0
                    let projectedRatio = containerHeight > 0 ? (projectedVertical / containerHeight) : 0

                    let fastFlickMargin: CGFloat = 160
                    let shouldDismiss = (
                        distanceRatio >= 0.5 ||
                        projectedRatio >= 0.6 ||
                        (projectedVertical - endVertical) >= fastFlickMargin
                    )

                    if shouldDismiss {
                        let projected = max(0, value.predictedEndTranslation.height)
                        let extra = max(0, projected - endVertical)
                        let speedCfg: (speed: CGFloat, overshoot: CGFloat)
                        if extra >= 220 {
                            speedCfg = (speed: 2000, overshoot: 0.60)
                        } else if extra >= 80 {
                            speedCfg = (speed: 1600, overshoot: 0.52)
                        } else {
                            speedCfg = (speed: 1400, overshoot: 0.45)
                        }
                        let baseTarget = max(projected, containerHeight)
                        let targetY = max(baseTarget + containerHeight * speedCfg.overshoot, 1)
                        let remaining = max(0, targetY - verticalDrag)
                        let duration = min(max(Double(remaining / speedCfg.speed), 0.12), 0.26)

                        withAnimation(.timingCurve(0.24, 0.92, 0.30, 1.0, duration: duration)) {
                            verticalDrag = targetY
                            containerOpacity = 0
                            horizontalDrag = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            onDismiss?()
                            withTransaction(Transaction(animation: nil)) {
                                verticalDrag = 0
                                dismissProgress = 0
                                containerOpacity = 1
                                horizontalDrag = 0
                            }
                        }
                        activeDragAxis = .none
                        return
                    }

                    isVerticalSnappingBack = true
                    let snapDuration: Double = 0.22
                    withAnimation(.interactiveSpring(response: snapDuration, dampingFraction: 0.92, blendDuration: 0.1)) {
                        verticalDrag = 0
                        horizontalDrag = 0
                        dismissProgress = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + snapDuration) {
                        isVerticalSnappingBack = false
                        containerVM.storyVM.pause(false)
                    }
                    activeDragAxis = .none
                    return
                }

                if endAxis == .horizontal {
                    if deltaX <= -threshold, containerVM.currentIndex + 1 < containerVM.stories.count {
                        isInteractiveSwitch = true
                        withAnimation(.interactiveSpring(response: 0.36, dampingFraction: 0.88, blendDuration: 0.1)) {
                            horizontalDrag = -containerWidth
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                            containerVM.goNextStory()
                            isInteractiveSwitch = false
                            withTransaction(Transaction(animation: nil)) { horizontalDrag = 0 }
                            verticalDrag = 0
                            dismissProgress = 0
                        }
                        activeDragAxis = .none
                        return
                    } else if deltaX >= threshold, containerVM.currentIndex - 1 >= 0 {
                        isInteractiveSwitch = true
                        withAnimation(.interactiveSpring(response: 0.36, dampingFraction: 0.88, blendDuration: 0.1)) {
                            horizontalDrag = containerWidth
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.20) {
                            containerVM.goPrevStory()
                            isInteractiveSwitch = false
                            withTransaction(Transaction(animation: nil)) { horizontalDrag = 0 }
                            verticalDrag = 0
                            dismissProgress = 0
                        }
                        activeDragAxis = .none
                        return
                    }
                }

                let hadVertical = verticalDrag != 0
                if hadVertical { isVerticalSnappingBack = true }
                let snapBack: Double = 0.22
                withAnimation(.spring(response: snapBack, dampingFraction: 0.9)) {
                    horizontalDrag = 0
                    verticalDrag = 0
                    dismissProgress = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + snapBack) {
                    if hadVertical { isVerticalSnappingBack = false }
                    containerVM.storyVM.pause(false)
                }
                activeDragAxis = .none
            }
    }
}

struct StoryView: View {
    @ObservedObject var viewModel: StoryViewModel
    let onDismiss: (() -> Void)?
    let style: ImageSlidesStyle
    @Environment(\.scenePhase) private var scenePhase

    @State private var isHolding: Bool = false
    @State private var holdWorkItem: DispatchWorkItem?

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
        .transaction { $0.animation = nil }
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

    private var topOverlay: some View {
        ZStack(alignment: .top) {
            LinearGradient(colors: [Color.black.opacity(0.65), Color.black.opacity(0.0)], startPoint: .top, endPoint: .bottom)
                .frame(height: 140)
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
                if (dx * dx + dy * dy) > (24 * 24) {
                    cancelHold()
                }
            }
            .onEnded { _ in
                finishHold()
            }
    }

    private func scheduleHold() {
        cancelHold()
        let work = DispatchWorkItem {
            isHolding = true
            viewModel.hold(true)
            viewModel.pause(true)
        }
        holdWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22, execute: work)
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

struct StoriesPresenterModifier: ViewModifier {
    @Binding var isPresented: Bool
    var feed: any StoriesFeedProtocol
    @Binding var dismissProgress: CGFloat
    var config: StoriesComponentConfig
    func body(content: Content) -> some View {
        content.overlay(
            ZStack {
                if isPresented {
                    Color.black.opacity(dismissProgress == 0 ? 1 : 0)
                        .ignoresSafeArea()
                        .zIndex(0)
                    Color.black.opacity(max(0, min(1, config.dimmerMaxOpacity * (1 - sqrt(Double(dismissProgress))))))
                        .ignoresSafeArea()
                        .zIndex(1)
                    StoriesContainerView(
                        feed: feed,
                        onDismiss: {
                            withTransaction(Transaction(animation: nil)) { isPresented = false }
                        },
                        dismissProgress: $dismissProgress,
                        config: config
                    )
                    .transition(.storiesDeck)
                    .zIndex(2)
                }
            }
        )
    }
}

extension View {
    func storiesPresenter(
        isPresented: Binding<Bool>,
        feed: any StoriesFeedProtocol,
        dismissProgress: Binding<CGFloat> = .constant(0),
        config: StoriesComponentConfig = .init()
    ) -> some View {
        modifier(StoriesPresenterModifier(isPresented: isPresented, feed: feed, dismissProgress: dismissProgress, config: config))
    }
}

extension StoriesContainerView {
    init(story: Story, onDismiss: (() -> Void)? = nil) {
        struct SingleStoryFeed: StoriesFeedProtocol {
            let stories: [any StoryProtocol]
            let startIndex: Int = 0
            init(_ story: Story) {
                let mapped = AnyStory(
                    id: story.id,
                    user: AnyStoryUser(name: story.user.name, avatarURL: story.user.avatarURL),
                    items: story.items.map { AnyStoryItem(id: $0.id, imageURL: $0.imageURL) }
                )
                self.stories = [mapped]
            }
        }
        let feed = SingleStoryFeed(story)
        self.init(feed: feed, onDismiss: onDismiss)
    }
}
