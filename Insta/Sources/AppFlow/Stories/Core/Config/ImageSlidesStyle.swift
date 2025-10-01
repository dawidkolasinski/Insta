//
//  ImageSlidesStyle.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

enum ImageSlidesStyle: Equatable {
    case card(aspectRatio: CGFloat = 9/16, cornerRadius: CGFloat = 16)
    case fullscreen(ignoreSafeAreas: Bool = true)
}
