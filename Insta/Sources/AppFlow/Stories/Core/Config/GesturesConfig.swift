//
//  GesturesConfig.swift
//  Insta
//
//  Created by Dawid Kolasinski on 01/10/2025.
//

import Foundation

struct GesturesConfig: Equatable {
    var taps: Bool = true
    var swipes: Bool = true
    var verticalDismiss: Bool = true
    var longPressPause: Bool = true

    static let allEnabled = GesturesConfig()
}
