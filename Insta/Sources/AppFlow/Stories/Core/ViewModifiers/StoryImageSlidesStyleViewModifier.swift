//
//  StoryImageSlidesStyleViewModifier.swift
//  Insta
//
//  Created by Dawid Kolasinski on 01/10/2025.
//

import SwiftUI

struct StoryImageSlidesStyleViewModifier: ViewModifier {
    let style: StoryImageStyle

    func body(content: Content) -> some View {
        switch style {
        case let .card(aspect, radius):
            content
                .frame(maxWidth: .infinity, alignment: .center)
                .aspectRatio(aspect, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .contentShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)

        case .fullscreen:
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .scaledToFill()
                .clipped()
                .contentShape(Rectangle())
        }
    }
}

extension View {
    func storyImageSlidesStyle(_ style: StoryImageStyle) -> some View {
        modifier(StoryImageSlidesStyleViewModifier(style: style))
    }
}

