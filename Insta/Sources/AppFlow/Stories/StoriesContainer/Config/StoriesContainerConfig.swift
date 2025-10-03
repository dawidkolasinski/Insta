//
//  StoriesComponentConfig.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct StoriesContainerConfig: Equatable {
    var style: StoryImageStyle = .fullscreen(ignoreSafeAreas: true)
    var gestures: StoriesContainerGestureConfig = .allEnabled
    var hold: StoriesContainerHoldConfig = .init()
    var physics: StoriesContainerPhysicsConfig = .init()
    var dimmerMaxOpacity: Double = 0.75
    var topOverlayHeight: CGFloat = 96
    var switchStyle: StoriesSwitchStyle = .timingSlide()
}
