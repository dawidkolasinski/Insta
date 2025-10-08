//
//  CollapsibleHeaderContainer.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

/// Reużywalny kontener z chowanym nagłówkiem.
/// - headerHeight: wysokość nagłówka (np. 48).
/// - fadeAmount: maks. zanikanie treści przy pełnym schowaniu (0…1, np. 0.10 = 10%).
/// - smoothingDown / smoothingUp: współczynniki wygładzania (0…1) dla chowu/powrotu.
/// - header: closure z `progress` (0…1), aby sterować wyglądem nagłówka.
/// - content: treść przewijana pod nagłówkiem.
struct CollapsibleHeaderContainer<Header: View, Content: View>: View {

    // Konfiguracja
    let headerHeight: CGFloat
    let fadeAmount: CGFloat
    let smoothingDown: CGFloat
    let smoothingUp: CGFloat

    @ViewBuilder let header: (_ progress: CGFloat) -> Header
    @ViewBuilder let content: () -> Content

    // Stan wewnętrzny
    @State private var collapseProgress: CGFloat = 0
    @State private var lastOffset: CGFloat = 0

    init(
        headerHeight: CGFloat = 48,
        fadeAmount: CGFloat = 0.10,
        smoothingDown: CGFloat = 0.28,
        smoothingUp: CGFloat = 0.38,
        @ViewBuilder header: @escaping (_ progress: CGFloat) -> Header,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.headerHeight = headerHeight
        self.fadeAmount = fadeAmount
        self.smoothingDown = smoothingDown
        self.smoothingUp = smoothingUp
        self.header = header
        self.content = content
    }

    var body: some View {
        ZStack(alignment: .top) {
            // Header sterowany progresem
            header(collapseProgress)
                .offset(y: -headerHeight * collapseProgress)
                .zIndex(1)

            // Scrollowana treść
            ScrollView(.vertical, showsIndicators: false) {
                content()
                    .padding(.top, headerHeight * (CGFloat(1) - collapseProgress))
                    .opacity(1 - Double(collapseProgress * fadeAmount))
            }
            .onScrollGeometryChange(for: CGFloat.self) { proxy in
                proxy.contentOffset.y
            } action: { _, newY in
                handle(offset: newY)
            }
        }
    }

    // Kierunkowe wyliczanie progresu + łagodne wygładzanie
    private func handle(offset contentOffsetY: CGFloat) {
        if contentOffsetY <= 0 {
            collapseProgress = 0
            lastOffset = 0
            return
        }

        let delta = contentOffsetY - lastOffset
        lastOffset = contentOffsetY

        let target = min(max(collapseProgress + (delta / headerHeight), 0), 1)
        let k = (delta >= 0) ? smoothingDown : smoothingUp
        collapseProgress += (target - collapseProgress) * k
    }
}
