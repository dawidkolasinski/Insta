//
//  PhysicsConfig.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct StoriesContainerPhysicsConfig: Equatable {
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
