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
    var config: StoriesContainerConfig
    var autoConfig: StoryAutoAdvanceConfig = .init()

    private var isFullscreenIgnoringSafeAreas: Bool {
        if case let .fullscreen(ignore) = config.style {
            return ignore
        }
        return false
    }

    func body(content: Content) -> some View {
        content.overlay(
            GeometryReader { geo in
                let deviceTopInset = geo.safeAreaInsets.top

                ZStack {
                    if isPresented {
                        Color.black.opacity(dismissProgress == 0 ? 1 : 0)
                            .ignoresSafeArea()
                            .zIndex(0)
                        Color.black.opacity(max(0, min(1, config.dimmerMaxOpacity * (1 - sqrt(Double(dismissProgress))))))
                            .ignoresSafeArea()
                            .zIndex(1)

                        // Wrapper ignorujący safe area od 1. klatki
                        ZStack {
                            StoriesContainerView(
                                viewModel: StoriesContainerViewModel(feed: feed, config: config, autoConfig: autoConfig),
                                onDismiss: {
                                    withTransaction(Transaction(animation: nil)) { isPresented = false }
                                },
                                dismissProgress: $dismissProgress,
                                topSafeAreaInset: deviceTopInset
                            )
                            .transition(.storiesDeck)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .ignoresSafeArea(isFullscreenIgnoringSafeAreas ? .all : [])
                        .zIndex(2)
                    }
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
        config: StoriesContainerConfig = .init(),
        autoConfig: StoryAutoAdvanceConfig = .init()
    ) -> some View {
        modifier(StoriesPresenterModifier(isPresented: isPresented,
                                          feed: feed,
                                          dismissProgress: dismissProgress,
                                          config: config,
                                          autoConfig: autoConfig))
    }
}

