//
//  FeedListView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct FeedListView: View {
    let layout: FeedLayout

    var body: some View {
        switch layout {
        case .vertical:
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(0..<10, id: \.self) { number in
                        ListFeedPlaceholderView(number: number)
                    }
                }
            }
            .coordinateSpace(name: "feedScroll")
        case .horizontal:
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 8) {
                    ForEach(0..<10, id: \.self) { number in
                        ListFeedPlaceholderView(number: number)
                            .frame(width: 300)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    init(layout: FeedLayout = .vertical) {
        self.layout = layout
    }
}
