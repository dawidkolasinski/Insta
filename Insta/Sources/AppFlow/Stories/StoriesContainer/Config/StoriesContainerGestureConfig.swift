//
//  StoriesContainerGestureConfig.swift
//  Insta
//
//  Created by Dawid Kolasinski on 01/10/2025.
//

import Foundation

struct StoriesContainerGestureConfig: Equatable {
    var taps: Bool = true
    var horizontalSwipes: Bool = true
    var verticalDismiss: Bool = true
    var longPressPause: Bool = true

    static let allEnabled = StoriesContainerGestureConfig()
}
