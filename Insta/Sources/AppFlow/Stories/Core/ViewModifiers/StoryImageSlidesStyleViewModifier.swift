//
//  StoryImageSlidesStyleViewModifier.swift
//  Insta
//
//  Created by Dawid Kolasinski on 01/10/2025.
//

import SwiftUI

struct StoryImageSlidesStyleViewModifier: ViewModifier {
    let style: ImageSlidesStyle

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
                .scaledToFill()
                .clipped()
        }
    }
}

extension View {
    func storyImageSlidesStyle(_ style: ImageSlidesStyle) -> some View {
        modifier(StoryImageSlidesStyleViewModifier(style: style))
    }
}

