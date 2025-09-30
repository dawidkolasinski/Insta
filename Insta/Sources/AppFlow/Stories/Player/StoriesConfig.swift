//
//  StoriesConfig.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//  Configuration structs and styles for Stories component.
//

import Foundation
import SwiftUI

struct StoriesContainerGesturesConfig: Equatable {
    var horizontalSwipes: Bool = true
    var verticalDismiss: Bool = true

    init(horizontalSwipes: Bool = true, verticalDismiss: Bool = true) {
        self.horizontalSwipes = horizontalSwipes
        self.verticalDismiss = verticalDismiss
    }
}

struct HoldConfig: Equatable {
    var minDuration: Double = 0.22
    var cancelDistance: CGFloat = 24
    init(minDuration: Double = 0.22, cancelDistance: CGFloat = 24) {
        self.minDuration = minDuration
        self.cancelDistance = cancelDistance
    }
}

struct PhysicsConfig: Equatable {
    var horizontalHysteresis: CGFloat = 12
    var horizontalSwipeThresholdFraction: CGFloat = 0.18
    var verticalDismissDistanceRatio: CGFloat = 0.5
    var verticalProjectedRatio: CGFloat = 0.6
    var verticalFastFlickMargin: CGFloat = 160
    var verticalSpeedSlow: CGFloat = 1400
    var verticalSpeedMedium: CGFloat = 1600
    var verticalSpeedFast: CGFloat = 2000
    var verticalOvershootSlow: CGFloat = 0.45
    var verticalOvershootMedium: CGFloat = 0.52
    var verticalOvershootFast: CGFloat = 0.60
    var snapBackDuration: Double = 0.22
    var interactiveSwitchResponse: Double = 0.36
    var interactiveSwitchDamping: Double = 0.88
    var dismissMinDuration: Double = 0.12
    var dismissMaxDuration: Double = 0.26
    var horizontalOverscrollToVerticalGain: CGFloat = 0.5
    var overscrollHorizontalDriftFactor: CGFloat = 0.15
}

enum ImageSlidesStyle: Equatable {
    case card(aspectRatio: CGFloat = 9/16, cornerRadius: CGFloat = 16)
    case fullscreen(ignoreSafeAreas: Bool = true)
}

struct StoriesComponentConfig: Equatable {
    var style: ImageSlidesStyle = .card()
    var gestures: ImageSlidesView.GesturesConfig = .allEnabled
    var containerGestures: StoriesContainerGesturesConfig = .init()
    var hold: HoldConfig = .init()
    var physics: PhysicsConfig = .init()
    var dimmerMaxOpacity: Double = 0.75
    var topOverlayHeight: CGFloat = 96
    var switchStyle: StoriesSwitchStyle = .springSlide()
}

enum StoriesSwitchStyle: Equatable {
    case springSlide(
        response: Double = 0.36,
        damping: Double = 0.88,
        blend: Double = 0.1,
        travel: CGFloat = 1.0,
        durationHint: Double = 0.20
    )
    case timingSlide(duration: Double = 0.22)

    func run(direction: StoriesContainerView.SwitchDirection,
             width: CGFloat,
             setDrag: @escaping (CGFloat) -> Void) -> Double {
        let offset = (direction == .next ? -1 : 1) * width
        switch self {
        case let .springSlide(response, damping, blend, travel, durationHint):
            withAnimation(.interactiveSpring(response: response, dampingFraction: damping, blendDuration: blend)) {
                setDrag(offset * travel)
            }
            return durationHint
        case let .timingSlide(duration):
            withAnimation(.timingCurve(0.25, 0.8, 0.2, 1.0, duration: duration)) {
                setDrag(offset)
            }
            return duration
        }
    }
}

struct ImageSlidesAutoConfig: Equatable {
    var enabled: Bool = true
    var durationPerSlide: TimeInterval = 5.0
    var tick: TimeInterval = 0.05
    var loops: Bool = false
}
