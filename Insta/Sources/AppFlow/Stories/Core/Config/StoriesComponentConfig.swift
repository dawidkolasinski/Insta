//
//  StoriesComponentConfig.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct StoriesComponentConfig: Equatable {
    var style: ImageSlidesStyle = .fullscreen(ignoreSafeAreas: true)
    var gestures: GesturesConfig = .allEnabled
    var containerGestures: StoriesContainerGesturesConfig = .init()
    var hold: HoldConfig = .init()
    var physics: PhysicsConfig = .init()
    var dimmerMaxOpacity: Double = 0.75
    var topOverlayHeight: CGFloat = 96
    var switchStyle: StoriesSwitchStyle = .springSlide()
}
