//
//  NavigationBarView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct NavigationBarView: View {
    var title: String = "for you"
    var onLeadingTap: () -> Void = {}
    var onTrailingTap: () -> Void = {}
    var onMenuPrimary: () -> Void = {}
    var onMenuSecondary: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            // Trailing text as a menu
            Menu {
                Button("Opcja 1", action: onMenuPrimary)
                Button("Opcja 2", action: onMenuSecondary)
            } label: {
                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 22, weight: .semibold, design: .rounded))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .contentShape(Rectangle())
                .frame(height: 44)
            }
            .padding(.trailing, 4)
            Spacer(minLength: 0)
            // Icons (black)
            Button(action: onLeadingTap) {
                Image(systemName: "heart")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .foregroundColor(.black)
            }
            Button(action: onTrailingTap) {
                Image(systemName: "bubble.right")
                    .font(.system(size: 18, weight: .semibold))
                    .frame(width: 44, height: 44)
                    .foregroundColor(.black)
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
