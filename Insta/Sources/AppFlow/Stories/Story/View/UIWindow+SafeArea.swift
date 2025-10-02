//
//  UIWindow+SafeArea.swift
//  Insta
//
//  Created by Dawid Kolasinski on 02/10/2025.
//

import UIKit

extension UIWindow {
    static var topSafeAreaInset: CGFloat {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
        let keyWindow = scenes
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        return keyWindow?.safeAreaInsets.top ?? 0
    }
}
