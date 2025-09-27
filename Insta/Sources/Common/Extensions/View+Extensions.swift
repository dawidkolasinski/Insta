//
//  View+Extensions.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

extension View {
    func equalWidthAndHeight(_ length: CGFloat) -> some View {
        frame(width: length, height: length)
    }
}
