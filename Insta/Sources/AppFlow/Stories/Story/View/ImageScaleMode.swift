//
//  ImageScaleMode.swift
//  Insta
//
//  Created by Dawid Kolasinski on 02/10/2025.
//

import SwiftUI

struct ImageScaleMode: ViewModifier {
    let contentMode: ContentMode

    func body(content: Content) -> some View {
        switch contentMode {
        case .fit:
            content
                .scaledToFit()
        case .fill:
            content
                .scaledToFill()
                .clipped()
        @unknown default:
            content
                .scaledToFit()
        }
    }
}

extension View {
    func imageScaleMode(_ contentMode: ContentMode) -> some View {
        modifier(ImageScaleMode(contentMode: contentMode))
    }
}
