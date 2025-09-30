//
//  StoriesContainerView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI
import Combine

enum DragAxis { case none, horizontal, vertical }
enum VerticalMode { case none, fromY }

struct StoriesContainerView: View {
    @StateObject private var containerVM: StoriesContainerViewModel

    // Horizontal/vertical interaction state
    @State private var horizontalDrag: CGFloat = 0
    @State private var verticalDrag: CGFloat = 0
    @State private var activeDragAxis: DragAxis = .none
    @State private var verticalMode: VerticalMode = .none
    @State private var isInteractiveSwitch: Bool = false
    @State private var isVerticalSnappingBack: Bool = false

    // Geometry-dependent state
    @State private var containerWidth: CGFloat = 0
    @State private var containerHeight: CGFloat = 0
    @State private var containerOpacity: Double = 1
    @State private var verticalBaseOffset: CGFloat = 0
    @State private var verticalBaseDY: CGFloat = 0
    @State private var horizontalBaseOffset: CGFloat = 0
    @State private var horizontalBaseDX: CGFloat = 0
    @State private var animWidth: CGFloat = 0

    @Binding private var dismissProgress: CGFloat
    private let onDismiss: (() -> Void)?
    private let config: StoriesComponentConfig

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var springAnimation: Animation {
        .interactiveSpring(
            response: config.physics.interactiveSwitchResponse,
            dampingFraction: config.physics.interactiveSwitchDamping,
            blendDuration: 0.1
        )
    }

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

    enum SwitchDirection { case next, prev }

    private func performHorizontalSwitch(_ direction: SwitchDirection) {
        guard !isInteractiveSwitch else { return }

        let computedWidth: CGFloat = {
            if containerWidth > 0 { return containerWidth }
            #if os(iOS) || os(tvOS) || os(visionOS)
            return UIScreen.main.bounds.width
            #else
            return 320
            #endif
        }()
        animWidth = computedWidth
        let startIndex = containerVM.currentIndex

        switch direction {
        case .next:
            guard containerVM.currentIndex + 1 < containerVM.stories.count else { animWidth = 0; return }
        case .prev:
            guard containerVM.currentIndex - 1 >= 0 else { animWidth = 0; return }
        }

        isInteractiveSwitch = true
        containerVM.storyVM.pause(true)

        let fromDrag = abs(horizontalDrag) > 1
        if !fromDrag {
            let sign: CGFloat = (direction == .next) ? -1 : 1
            withTransaction(Transaction(animation: nil)) {
                horizontalDrag = sign * max(0.5, computedWidth * 0.001)
            }
        }

        let duration: Double = config.switchStyle.run(direction: direction, width: computedWidth) { newDrag in
            horizontalDrag = newDrag
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            if containerVM.currentIndex == startIndex {
                switch direction {
                case .next: containerVM.goNextStory()
                case .prev: containerVM.goPrevStory()
                }
            }
            isInteractiveSwitch = false
            withTransaction(Transaction(animation: nil)) { horizontalDrag = 0 }
            verticalDrag = 0
            dismissProgress = 0
            containerVM.storyVM.pause(false)
            animWidth = 0
        }
    }

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let effectiveWidth = animWidth > 0 ? animWidth : width
            let verticalProgress = min(1, max(0, verticalDrag / max(1, height)))
            let easedVertical = CGFloat(pow(Double(verticalProgress), 0.25))
            let showNeighbors = (isInteractiveSwitch || (activeDragAxis != .vertical && verticalDrag == 0 && !isVerticalSnappingBack))

            Color.clear
                .onAppear {
                    containerWidth = width
                    containerHeight = height
                }
                .onChange(of: width) { newW in
                    containerWidth = newW
                }
                .onChange(of: height) { containerHeight = $0 }
            ZStack {
                if !containerVM.stories.isEmpty {
                    if showNeighbors, let prev = containerVM.prevVM {
                        StoryView(viewModel: prev, onDismiss: onDismiss, style: config.style, holdConfig: config.hold, topOverlayHeight: config.topOverlayHeight)
                            .id((prev.story as StoryProtocol).id)
                            .offset(x: horizontalDrag - effectiveWidth)
                            .allowsHitTesting(false)
                            .zIndex(0)
                    }
                    if showNeighbors, let next = containerVM.nextVM {
                        StoryView(viewModel: next, onDismiss: onDismiss, style: config.style, holdConfig: config.hold, topOverlayHeight: config.topOverlayHeight)
                            .id((next.story as StoryProtocol).id)
                            .offset(x: horizontalDrag + effectiveWidth)
                            .allowsHitTesting(false)
                            .zIndex(0)
                    }
                    StoryView(viewModel: containerVM.storyVM, onDismiss: onDismiss, style: config.style, holdConfig: config.hold, topOverlayHeight: config.topOverlayHeight)
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
            .scaleEffect(reduceMotion ? 1 : (1 - 0.50 * easedVertical))
            .opacity(containerOpacity * max(0.0, 1 - 0.95 * Double(easedVertical)))
        }
        .background(Color.clear.ignoresSafeArea())
        .simultaneousGesture(dragGesture)
        .onReceive(containerVM.dismissRequested) { _ in
            performDismissAnimation()
        }
        .onReceive(containerVM.resetDragRequested) { _ in
            withTransaction(Transaction(animation: nil)) {
                horizontalDrag = 0
                verticalDrag = 0
                dismissProgress = 0
                isInteractiveSwitch = false
                activeDragAxis = .none
                isVerticalSnappingBack = false
                verticalMode = .none
                verticalBaseOffset = 0
                verticalBaseDY = 0
                horizontalBaseOffset = 0
                horizontalBaseDX = 0
                animWidth = 0
            }
            containerVM.storyVM.pause(false)
        }
        .onReceive(containerVM.nextStoryRequested) { _ in
            DispatchQueue.main.async {
                performHorizontalSwitch(.next)
            }
        }
        .onChange(of: verticalDrag) { newValue in
            let height = max(1, containerHeight)
            dismissProgress = min(1, max(0, newValue / height))
        }
    }

    private func performDismissAnimation() {
        let baseOvershoot: CGFloat = config.physics.verticalOvershootSlow
        let targetY = max(containerHeight + containerHeight * baseOvershoot, 1)
        let remaining = max(0, targetY - verticalDrag)
        let duration = min(max(Double(remaining / config.physics.verticalSpeedSlow), 0.14), config.physics.dismissMaxDuration)
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

    private func verticalEquivalent(fromHorizontal dx: CGFloat) -> CGFloat {
        let w = max(1, containerWidth)
        let h = max(1, containerHeight)
        let gain = max(0, config.physics.horizontalOverscrollToVerticalGain)
        return abs(dx) * (h / w) * gain
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .local)
            .onChanged { value in
                let deltaX = value.translation.width
                let deltaY = value.translation.height
                let hysteresis: CGFloat = config.physics.horizontalHysteresis

                let isAtFirst = containerVM.currentIndex <= 0
                let isAtLast = containerVM.currentIndex >= max(0, containerVM.stories.count - 1)
                let overscrollMissingNeighbor = (deltaX > 0 && isAtFirst) || (deltaX < 0 && isAtLast)

                if activeDragAxis == .none {
                    let canH = config.containerGestures.horizontalSwipes
                    let canV = config.containerGestures.verticalDismiss
                    if overscrollMissingNeighbor, canV {
                        activeDragAxis = .vertical
                        verticalMode = .fromY
                        verticalBaseOffset = verticalEquivalent(fromHorizontal: deltaX)
                        verticalBaseDY = deltaY
                        horizontalBaseOffset = horizontalDrag
                        horizontalBaseDX = deltaX
                    } else if canH, abs(deltaX) > abs(deltaY) + hysteresis {
                        activeDragAxis = .horizontal
                        verticalMode = .none
                    } else if canV, abs(deltaY) > abs(deltaX) + hysteresis {
                        activeDragAxis = .vertical
                        verticalMode = .fromY
                        verticalBaseOffset = 0
                        verticalBaseDY = 0
                        horizontalBaseOffset = horizontalDrag
                        horizontalBaseDX = deltaX
                    }
                } else if activeDragAxis == .horizontal, overscrollMissingNeighbor, config.containerGestures.verticalDismiss {
                    activeDragAxis = .vertical
                    verticalMode = .fromY
                    verticalBaseOffset = verticalEquivalent(fromHorizontal: deltaX)
                    verticalBaseDY = deltaY
                    horizontalBaseOffset = horizontalDrag
                    horizontalBaseDX = deltaX
                }

                if activeDragAxis != .none {
                    containerVM.storyVM.pause(true)
                }

                switch activeDragAxis {
                case .horizontal:
                    guard config.containerGestures.horizontalSwipes else { return }
                    if overscrollMissingNeighbor {
                        let rubber: CGFloat = 0.15
                        horizontalDrag = deltaX * rubber
                        verticalDrag = 0
                        dismissProgress = 0
                    } else {
                        horizontalDrag = deltaX
                        verticalDrag = 0
                        dismissProgress = 0
                    }
                case .vertical:
                    guard config.containerGestures.verticalDismiss else { return }
                    let rawY = verticalBaseOffset + (deltaY - verticalBaseDY)
                    verticalDrag = max(0, rawY)
                    let factor = max(0, config.physics.overscrollHorizontalDriftFactor)
                    let rawX = horizontalBaseOffset + (deltaX - horizontalBaseDX) * factor
                    let maxDrift = containerWidth * 0.3
                    horizontalDrag = min(max(rawX, -maxDrift), maxDrift)
                    isVerticalSnappingBack = false
                case .none:
                    break
                }
            }
            .onEnded { value in
                let endAxis = activeDragAxis
                let deltaX = value.translation.width
                let endVerticalFromY = max(0, value.translation.height)

                let isAtFirst = containerVM.currentIndex <= 0
                let isAtLast = containerVM.currentIndex >= max(0, containerVM.stories.count - 1)
                let overscrollMissingNeighbor = (deltaX > 0 && isAtFirst) || (deltaX < 0 && isAtLast)

                let threshold: CGFloat = max(60, containerWidth * config.physics.horizontalSwipeThresholdFraction)

                if (endAxis == .vertical && config.containerGestures.verticalDismiss) ||
                    (overscrollMissingNeighbor && config.containerGestures.verticalDismiss) {

                    let endVertical = max(0, verticalBaseOffset + (endVerticalFromY - verticalBaseDY))
                    let projectedVertical = max(0, verticalBaseOffset + (value.predictedEndTranslation.height - verticalBaseDY))

                    let distanceRatio = containerHeight > 0 ? (endVertical / containerHeight) : 0
                    let projectedRatio = containerHeight > 0 ? (projectedVertical / containerHeight) : 0

                    let fastFlickMargin: CGFloat = config.physics.verticalFastFlickMargin
                    let shouldDismiss = (
                        distanceRatio >= config.physics.verticalDismissDistanceRatio ||
                        projectedRatio >= config.physics.verticalProjectedRatio ||
                        (projectedVertical - endVertical) >= fastFlickMargin
                    )

                    if shouldDismiss {
                        let extra = max(0, projectedVertical - endVertical)
                        let speedCfg: (speed: CGFloat, overshoot: CGFloat)
                        if extra >= 220 {
                            speedCfg = (speed: config.physics.verticalSpeedFast, overshoot: config.physics.verticalOvershootFast)
                        } else if extra >= 80 {
                            speedCfg = (speed: config.physics.verticalSpeedMedium, overshoot: config.physics.verticalOvershootMedium)
                        } else {
                            speedCfg = (speed: config.physics.verticalSpeedSlow, overshoot: config.physics.verticalOvershootSlow)
                        }
                        let baseTarget = max(projectedVertical, containerHeight)
                        let targetY = max(baseTarget + containerHeight * speedCfg.overshoot, 1)
                        let remaining = max(0, targetY - verticalDrag)
                        let duration = min(max(Double(remaining / speedCfg.speed), config.physics.dismissMinDuration), config.physics.dismissMaxDuration)

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
                        verticalMode = .none
                        verticalBaseOffset = 0
                        verticalBaseDY = 0
                        horizontalBaseOffset = 0
                        horizontalBaseDX = 0
                        return
                    }

                    isVerticalSnappingBack = true
                    let snapDuration: Double = config.physics.snapBackDuration
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
                    verticalMode = .none
                    verticalBaseOffset = 0
                    verticalBaseDY = 0
                    horizontalBaseOffset = 0
                    horizontalBaseDX = 0
                    return
                }

                if endAxis == .horizontal, config.containerGestures.horizontalSwipes {
                    if deltaX <= -threshold, containerVM.currentIndex + 1 < containerVM.stories.count {
                        performHorizontalSwitch(.next)
                        activeDragAxis = .none
                        verticalMode = .none
                        verticalBaseOffset = 0
                        verticalBaseDY = 0
                        horizontalBaseOffset = 0
                        horizontalBaseDX = 0
                        return
                    } else if deltaX >= threshold, containerVM.currentIndex - 1 >= 0 {
                        performHorizontalSwitch(.prev)
                        activeDragAxis = .none
                        verticalMode = .none
                        verticalBaseOffset = 0
                        verticalBaseDY = 0
                        horizontalBaseOffset = 0
                        horizontalBaseDX = 0
                        return
                    }
                }

                let hadVertical = verticalDrag != 0
                if hadVertical { isVerticalSnappingBack = true }
                let snapBack: Double = config.physics.snapBackDuration
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
                verticalMode = .none
                verticalBaseOffset = 0
                verticalBaseDY = 0
                horizontalBaseOffset = 0
                horizontalBaseDX = 0
            }
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
