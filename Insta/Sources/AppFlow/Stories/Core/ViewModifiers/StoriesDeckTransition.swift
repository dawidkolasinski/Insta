//
//  StoriesDeckTransition.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//  Transitions and modifiers used by Stories presentation.
//

import SwiftUI

struct OffsetScaleOpacityModifier: ViewModifier {
    let offset: CGSize
    let scale: CGFloat
    let opacity: Double
    let rotation: Double
    let blur: CGFloat
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .rotation3DEffect(.degrees(rotation), axis: (x: 1, y: 0, z: 0))
            .blur(radius: blur)
            .opacity(opacity)
            .offset(offset)
    }
}

extension AnyTransition {
    static var storiesDeck: AnyTransition {
        let insertion = AnyTransition.modifier(
            active: OffsetScaleOpacityModifier(
                offset: CGSize(width: 0, height: 20),
                scale: 0.88,
                opacity: 0.0,
                rotation: 8,
                blur: 6
            ),
            identity: OffsetScaleOpacityModifier(
                offset: .zero,
                scale: 1.0,
                opacity: 1.0,
                rotation: 0,
                blur: 0
            )
        )
        let removal = AnyTransition.modifier(
            active: OffsetScaleOpacityModifier(
                offset: .zero,
                scale: 0.9,
                opacity: 0.0,
                rotation: 0,
                blur: 0
            ),
            identity: OffsetScaleOpacityModifier(
                offset: .zero,
                scale: 1.0,
                opacity: 1.0,
                rotation: 0,
                blur: 0
            )
        )
        return .asymmetric(insertion: insertion, removal: removal)
    }
}
