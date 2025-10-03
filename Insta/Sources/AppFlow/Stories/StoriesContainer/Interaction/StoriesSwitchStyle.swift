//
//  StoriesSwitchStyle.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

enum StoriesSwitchStyle: Equatable {
    case springSlide(
        response: Double = 0.36,
        damping: Double = 0.88,
        blend: Double = 0.1,
        travel: CGFloat = 1.0,
        durationHint: Double = 0.20
    )
    case timingSlide(duration: Double = 0.22)

    func run(direction: StoriesSwitchDirection,
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
