//
//  StoriesPresenterModifier.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct StoriesPresenterModifier: ViewModifier {
    @Binding var isPresented: Bool
    var feed: StoriesFeedProtocol
    @Binding var dismissProgress: CGFloat
    var config: StoriesComponentConfig

    func body(content: Content) -> some View {
        content.overlay(
            ZStack {
                if isPresented {
                    Color.black.opacity(dismissProgress == 0 ? 1 : 0)
                        .ignoresSafeArea()
                        .zIndex(0)
                    Color.black.opacity(max(0, min(1, config.dimmerMaxOpacity * (1 - sqrt(Double(dismissProgress))))))
                        .ignoresSafeArea()
                        .zIndex(1)
                    StoriesContainerView(
                        viewModel: StoriesContainerViewModel(feed: feed, config: config),
                        onDismiss: {
                            withTransaction(Transaction(animation: nil)) { isPresented = false }
                        },
                        dismissProgress: $dismissProgress
                    )
                    .transition(.storiesDeck)
                    .zIndex(2)
                }
            }
        )
    }
}

extension View {
    func storiesPresenter(
        isPresented: Binding<Bool>,
        feed: StoriesFeedProtocol,
        dismissProgress: Binding<CGFloat> = .constant(0),
        config: StoriesComponentConfig = .init()
    ) -> some View {
        modifier(StoriesPresenterModifier(isPresented: isPresented, feed: feed, dismissProgress: dismissProgress, config: config))
    }
}
