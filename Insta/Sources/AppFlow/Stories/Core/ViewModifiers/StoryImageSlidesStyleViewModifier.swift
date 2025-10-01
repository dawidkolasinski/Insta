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
                .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                .frame(maxWidth: .infinity, alignment: .center)
                .aspectRatio(aspect, contentMode: .fit)
        case let .fullscreen(ignore):
            content
                .ignoresSafeArea(ignore ? .all : [])
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

extension View {
    func storyImageSlidesStyle(_ style: ImageSlidesStyle) -> some View {
        modifier(StoryImageSlidesStyleViewModifier(style: style))
    }
}
