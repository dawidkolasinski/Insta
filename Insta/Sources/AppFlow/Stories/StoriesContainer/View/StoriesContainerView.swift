//
//  StoriesContainerView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI
import Combine

struct StoriesContainerView<ViewModel: StoriesContainerViewModelProtocol>: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @StateObject private var containerViewModel: ViewModel

    @State private var horizontalDrag: CGFloat = 0
    @State private var verticalDrag: CGFloat = 0
    @State private var activeDragAxis: DragAxis = .none
    @State private var verticalMode: StoriesVerticalGestureMode = .none
    @State private var isInteractiveSwitch: Bool = false
    @State private var isVerticalSnappingBack: Bool = false
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
    private let topSafeAreaInset: CGFloat
    private let persistence: PersistenceStore

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
                .onChange(of: width) { newWidth in
                    containerWidth = newWidth
                }
                .onChange(of: height) { newHeight in
                    containerHeight = newHeight
                }

            ZStack {
                if !containerViewModel.stories.isEmpty {
                    if let previous = containerViewModel.previousStoryViewModel {
                        StoryView(
                            viewModel: previous,
                            onDismiss: { performDismissAnimation() },
                            style: containerViewModel.config.style,
                            holdConfig: containerViewModel.config.hold,
                            topOverlayHeight: containerViewModel.config.topOverlayHeight,
                            overrideTopSafeAreaInset: topSafeAreaInset,
                            gestures: containerViewModel.config.gestures,
                            persistence: persistence,
                            onLike: { item, liked in
                                persistence.toggleLike(item.id)
                            }
                        )
                        .offset(x: horizontalDrag - effectiveWidth)
                        .opacity(showNeighbors ? 1 : 0)
                        .allowsHitTesting(false)
                        .zIndex(0)
                        .accessibilityHidden(true)
                    }
                    if let next = containerViewModel.nextStoryViewModel {
                        StoryView(
                            viewModel: next,
                            onDismiss: { performDismissAnimation() },
                            style: containerViewModel.config.style,
                            holdConfig: containerViewModel.config.hold,
                            topOverlayHeight: containerViewModel.config.topOverlayHeight,
                            overrideTopSafeAreaInset: topSafeAreaInset,
                            gestures: containerViewModel.config.gestures,
                            persistence: persistence,
                            onLike: { item, liked in
                                persistence.toggleLike(item.id)
                            }
                        )
                        .offset(x: horizontalDrag + effectiveWidth)
                        .opacity(showNeighbors ? 1 : 0)
                        .allowsHitTesting(false)
                        .zIndex(0)
                        .accessibilityHidden(true)
                    }
                    StoryView(
                        viewModel: containerViewModel.currentStoryViewModel,
                        onDismiss: { performDismissAnimation() },
                        style: containerViewModel.config.style,
                        holdConfig: containerViewModel.config.hold,
                        topOverlayHeight: containerViewModel.config.topOverlayHeight,
                        overrideTopSafeAreaInset: topSafeAreaInset,
                        gestures: containerViewModel.config.gestures,
                        persistence: persistence,
                        onLike: { item, liked in
                            persistence.toggleLike(item.id)
                        }
                    )
                    .offset(x: horizontalDrag)
                    .zIndex(1)
                } else {
                    Text("No stories available")
                        .foregroundColor(.white)
                        .font(.headline)
                }
            }
            .frame(width: width, height: height)
            .clipped()
            .offset(y: verticalDrag)
            .scaleEffect(reduceMotion ? 1 : (1 - 0.50 * easedVertical))
            .opacity(containerOpacity * max(0.0, 1 - 0.95 * Double(easedVertical)))
        }
        .simultaneousGesture(dragGesture)
        .onReceive(containerViewModel.dismissRequested) { _ in
            performDismissAnimation()
        }
        .onReceive(containerViewModel.resetDragRequested) { _ in
            withTransaction(Transaction(animation: nil)) {
                resetAllGestureStates()
            }
            containerViewModel.currentStoryViewModel.pause(false)
        }
        .onReceive(containerViewModel.nextStoryRequested) { _ in
            DispatchQueue.main.async {
                performHorizontalSwitch(.next)
            }
        }
        .onChange(of: verticalDrag) { newValue in
            let height = max(1, containerHeight)
            dismissProgress = min(1, max(0, newValue / height))
        }
    }

    init(
        viewModel: @autoclosure @escaping () -> ViewModel,
        onDismiss: (() -> Void)? = nil,
        dismissProgress: Binding<CGFloat> = .constant(0),
        topSafeAreaInset: CGFloat,
        persistence: PersistenceStore
    ) {
        self.onDismiss = onDismiss
        self._dismissProgress = dismissProgress
        self.topSafeAreaInset = topSafeAreaInset
        self.persistence = persistence
        _containerViewModel = StateObject(wrappedValue: viewModel())
    }

    private func resetDragAxisState() {
        activeDragAxis = .none
        verticalMode = .none
        verticalBaseOffset = 0
        verticalBaseDY = 0
        horizontalBaseOffset = 0
        horizontalBaseDX = 0
    }

    private func resetAllGestureStates() {
        horizontalDrag = 0
        verticalDrag = 0
        dismissProgress = 0
        isInteractiveSwitch = false
        isVerticalSnappingBack = false
        animWidth = 0
        resetDragAxisState()
    }

    private func beginVerticalDragFromHorizontal(deltaX: CGFloat, deltaY: CGFloat) {
        activeDragAxis = .vertical
        verticalMode = .fromY
        verticalBaseOffset = verticalEquivalent(fromHorizontal: deltaX)
        verticalBaseDY = deltaY
        horizontalBaseOffset = horizontalDrag
        horizontalBaseDX = deltaX
    }

    private func beginVerticalDragFromVertical(deltaX: CGFloat) {
        activeDragAxis = .vertical
        verticalMode = .fromY
        verticalBaseOffset = 0
        verticalBaseDY = 0
        horizontalBaseOffset = horizontalDrag
        horizontalBaseDX = deltaX
    }

    private func beginHorizontalDrag() {
        activeDragAxis = .horizontal
        verticalMode = .none
    }

    private func performHorizontalSwitch(_ direction: StoriesSwitchDirection) {
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
        let startIndex = containerViewModel.currentStoryIndex

        switch direction {
        case .next:
            guard containerViewModel.currentStoryIndex + 1 < containerViewModel.stories.count else { animWidth = 0; return }
        case .prev:
            guard containerViewModel.currentStoryIndex - 1 >= 0 else { animWidth = 0; return }
        }

        isInteractiveSwitch = true
        containerViewModel.currentStoryViewModel.pause(true)

        let fromDrag = abs(horizontalDrag) > 1
        if !fromDrag {
            let sign: CGFloat = (direction == .next) ? -1 : 1
            withTransaction(Transaction(animation: nil)) {
                horizontalDrag = sign * max(0.5, computedWidth * 0.001)
            }
        }

        DispatchQueue.main.async {
            let duration: Double = containerViewModel.config.switchStyle.run(direction: direction, width: computedWidth) { newDrag in
                horizontalDrag = newDrag
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                if containerViewModel.currentStoryIndex == startIndex {
                    switch direction {
                    case .next: containerViewModel.goToNextStory()
                    case .prev: containerViewModel.goToPreviousStory()
                    }
                }
                isInteractiveSwitch = false
                withTransaction(Transaction(animation: nil)) { horizontalDrag = 0 }
                verticalDrag = 0
                dismissProgress = 0
                containerViewModel.currentStoryViewModel.pause(false)
                animWidth = 0
            }
        }
    }

    private func performDismissAnimation() {
        let baseOvershoot: CGFloat = containerViewModel.config.physics.verticalOvershootSlow
        let targetY = max(containerHeight + containerHeight * baseOvershoot, 1)
        let remaining = max(0, targetY - verticalDrag)
        let safeSpeed = max(0.001, containerViewModel.config.physics.verticalSpeedSlow)
        let duration = min(max(Double(remaining / safeSpeed), 0.14), containerViewModel.config.physics.dismissMaxDuration)
        withAnimation(.timingCurve(0.24, 0.92, 0.30, 1.0, duration: duration)) {
            verticalDrag = targetY
            containerOpacity = 0
            horizontalDrag = 0
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            onDismiss?()
            withTransaction(Transaction(animation: nil)) {
                resetAllGestureStates()
                containerOpacity = 1
            }
        }
    }

    private func verticalEquivalent(fromHorizontal dx: CGFloat) -> CGFloat {
        let w = max(1, containerWidth)
        let h = max(1, containerHeight)
        let gain = max(0, containerViewModel.config.physics.horizontalOverscrollToVerticalGain)
        return abs(dx) * (h / w) * gain
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 16, coordinateSpace: .local)
            .onChanged { value in
                let deltaX = value.translation.width
                let deltaY = value.translation.height
                let hysteresis: CGFloat = containerViewModel.config.physics.horizontalHysteresis

                let isAtFirst = containerViewModel.currentStoryIndex <= 0
                let isAtLast = containerViewModel.currentStoryIndex >= max(0, containerViewModel.stories.count - 1)
                let overscrollMissingNeighbor = (deltaX > 0 && isAtFirst) || (deltaX < 0 && isAtLast)

                if activeDragAxis == .none {
                    let canH = containerViewModel.config.gestures.horizontalSwipes
                    let canV = containerViewModel.config.gestures.verticalDismiss
                    if overscrollMissingNeighbor, canV {
                        beginVerticalDragFromHorizontal(deltaX: deltaX, deltaY: deltaY)
                    } else if canH, abs(deltaX) > abs(deltaY) + hysteresis {
                        beginHorizontalDrag()
                    } else if canV, abs(deltaY) > abs(deltaX) + hysteresis {
                        beginVerticalDragFromVertical(deltaX: deltaX)
                    }
                } else if activeDragAxis == .horizontal, overscrollMissingNeighbor, containerViewModel.config.gestures.verticalDismiss {
                    beginVerticalDragFromHorizontal(deltaX: deltaX, deltaY: deltaY)
                }

                if activeDragAxis != .none {
                    containerViewModel.currentStoryViewModel.pause(true)
                }

                switch activeDragAxis {
                case .horizontal:
                    guard containerViewModel.config.gestures.horizontalSwipes else { return }
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
                    guard containerViewModel.config.gestures.verticalDismiss else { return }
                    let rawY = verticalBaseOffset + (deltaY - verticalBaseDY)
                    verticalDrag = max(0, rawY)
                    let factor = max(0, containerViewModel.config.physics.overscrollHorizontalDriftFactor)
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

                let isAtFirst = containerViewModel.currentStoryIndex <= 0
                let isAtLast = containerViewModel.currentStoryIndex >= max(0, containerViewModel.stories.count - 1)
                let overscrollMissingNeighbor = (deltaX > 0 && isAtFirst) || (deltaX < 0 && isAtLast)

                let threshold: CGFloat = max(60, containerWidth * containerViewModel.config.physics.horizontalSwipeThresholdFraction)

                if (endAxis == .vertical && containerViewModel.config.gestures.verticalDismiss) ||
                    (overscrollMissingNeighbor && containerViewModel.config.gestures.verticalDismiss) {

                    let endVertical = max(0, verticalBaseOffset + (endVerticalFromY - verticalBaseDY))
                    let projectedVertical = max(0, verticalBaseOffset + (value.predictedEndTranslation.height - verticalBaseDY))

                    let distanceRatio = containerHeight > 0 ? (endVertical / containerHeight) : 0
                    let projectedRatio = containerHeight > 0 ? (projectedVertical / containerHeight) : 0

                    let fastFlickMargin: CGFloat = containerViewModel.config.physics.verticalFastFlickMargin
                    let shouldDismiss = (
                        distanceRatio >= containerViewModel.config.physics.verticalDismissDistanceRatio ||
                        projectedRatio >= containerViewModel.config.physics.verticalProjectedRatio ||
                        (projectedVertical - endVertical) >= fastFlickMargin
                    )

                    if shouldDismiss {
                        let extra = max(0, projectedVertical - endVertical)
                        let speedCfg: (speed: CGFloat, overshoot: CGFloat)
                        if extra >= 220 {
                            speedCfg = (speed: containerViewModel.config.physics.verticalSpeedFast, overshoot: containerViewModel.config.physics.verticalOvershootFast)
                        } else if extra >= 80 {
                            speedCfg = (speed: containerViewModel.config.physics.verticalSpeedMedium, overshoot: containerViewModel.config.physics.verticalOvershootMedium)
                        } else {
                            speedCfg = (speed: containerViewModel.config.physics.verticalSpeedSlow, overshoot: containerViewModel.config.physics.verticalOvershootSlow)
                        }
                        let baseTarget = max(projectedVertical, containerHeight)
                        let targetY = max(baseTarget + containerHeight * speedCfg.overshoot, 1)
                        let remaining = max(0, targetY - verticalDrag)
                        let safeSpeed = max(0.001, speedCfg.speed)
                        let duration = min(max(Double(remaining / safeSpeed), containerViewModel.config.physics.dismissMinDuration), containerViewModel.config.physics.dismissMaxDuration)

                        withAnimation(.timingCurve(0.24, 0.92, 0.30, 1.0, duration: duration)) {
                            verticalDrag = targetY
                            containerOpacity = 0
                            horizontalDrag = 0
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            onDismiss?()
                            withTransaction(Transaction(animation: nil)) {
                                resetAllGestureStates()
                                containerOpacity = 1
                            }
                        }
                        resetDragAxisState()
                        return
                    }

                    isVerticalSnappingBack = true
                    let snapDuration: Double = containerViewModel.config.physics.snapBackDuration
                    withAnimation(.interactiveSpring(response: snapDuration, dampingFraction: 0.92, blendDuration: 0.1)) {
                        verticalDrag = 0
                        horizontalDrag = 0
                        dismissProgress = 0
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + snapDuration) {
                        isVerticalSnappingBack = false
                        containerViewModel.currentStoryViewModel.pause(false)
                    }
                    resetDragAxisState()
                    return
                }

                if endAxis == .horizontal, containerViewModel.config.gestures.horizontalSwipes {
                    if deltaX <= -threshold, containerViewModel.currentStoryIndex + 1 < containerViewModel.stories.count {
                        performHorizontalSwitch(.next)
                        resetDragAxisState()
                        return
                    } else if deltaX >= threshold, containerViewModel.currentStoryIndex - 1 >= 0 {
                        performHorizontalSwitch(.prev)
                        resetDragAxisState()
                        return
                    }
                }

                let hadVertical = verticalDrag != 0
                if hadVertical { isVerticalSnappingBack = true }
                let snapBack: Double = containerViewModel.config.physics.snapBackDuration
                withAnimation(.spring(response: snapBack, dampingFraction: 0.9)) {
                    horizontalDrag = 0
                    verticalDrag = 0
                    dismissProgress = 0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + snapBack) {
                    if hadVertical { isVerticalSnappingBack = false }
                    containerViewModel.currentStoryViewModel.pause(false)
                }
                resetDragAxisState()
            }
    }
}

