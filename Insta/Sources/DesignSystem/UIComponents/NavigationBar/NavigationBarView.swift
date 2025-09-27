//
//  NavigationBarView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct NavigationBarView: View {
    let title: String
    var onLeadingTap: () -> Void = {}
    var onTrailingTap: () -> Void = {}

    var body: some View {
        ZStack {
            Text(title)
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .italic()

            HStack {
                Button(action: onLeadingTap) {
                    Image(systemName: "camera")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
                Spacer()
                Button(action: onTrailingTap) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.horizontal, 8)
        .frame(height: 48)
        .background(.ultraThinMaterial)
        .overlay(alignment: .bottom) {
            Divider().opacity(0.7)
        }
    }
}
