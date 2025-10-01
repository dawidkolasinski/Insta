//
//  ImageSlidesAutoConfig.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Foundation

struct ImageSlidesAutoConfig: Equatable {
    var enabled: Bool = true
    var durationPerSlide: TimeInterval = 5.0
    var tick: TimeInterval = 0.05
    var loops: Bool = false
}
