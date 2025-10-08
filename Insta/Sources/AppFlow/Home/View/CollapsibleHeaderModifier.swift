//
//  CollapsibleHeaderModifier.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct CollapsibleHeaderModifier<Header: View>: ViewModifier {
    var headerHeight: CGFloat = 48
    var fadeAmount: CGFloat = 0.1
    var smoothingDown: CGFloat = 0.28
    var smoothingUp: CGFloat = 0.38
    @ViewBuilder let header: (_ progress: CGFloat) -> Header

    @State private var progress: CGFloat = 0
    @State private var lastOffset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .contentMargins(.top, headerHeight * (1.0 - progress), for: .scrollContent)
            .opacity(1.0 - progress * fadeAmount)
            .overlay(alignment: .top) {
                header(progress)
                    .offset(y: -(headerHeight * progress))
                    .allowsHitTesting(true)
            }
            .onScrollGeometryChange(for: CGFloat.self) { proxy in
                proxy.contentOffset.y
            } action: { _, newY in
                handle(offset: newY)
            }
    }

    private func handle(offset y: CGFloat) {
        if y <= 0 {
            progress = 0
            lastOffset = 0
            return
        }
        let delta = y - lastOffset
        lastOffset = y
        let target = min(max(progress + (delta / headerHeight), 0), 1)
        let k = (delta >= 0) ? smoothingDown : smoothingUp
        progress += (target - progress) * k
    }
}

extension View {
    func collapsibleHeader<Header: View>(
        height: CGFloat = 48,
        fadeAmount: CGFloat = 0.10,
        smoothingDown: CGFloat = 0.28,
        smoothingUp: CGFloat = 0.38,
        @ViewBuilder header: @escaping (_ progress: CGFloat) -> Header
    ) -> some View {
        modifier(
            CollapsibleHeaderModifier(
                headerHeight: height,
                fadeAmount: fadeAmount,
                smoothingDown: smoothingDown,
                smoothingUp: smoothingUp,
                header: header
            )
        )
    }
}
