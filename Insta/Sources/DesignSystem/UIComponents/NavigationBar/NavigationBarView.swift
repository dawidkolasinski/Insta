//
//  NavigationBarView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct NavigationBarView: View {
    var title: String = "for you"
    var progress: CGFloat = 0 // 0 = w pełni widoczny, 1 = całkowicie ukryty (tylko tło)
    var onLeadingTap: () -> Void = {}
    var onTrailingTap: () -> Void = {}
    var onMenuPrimary: () -> Void = {}
    var onMenuSecondary: () -> Void = {}

    private var contentOpacity: CGFloat {
        max(0, min(1, 1 - progress))
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Tło paska – pozostaje widoczne
            Color.clear
                .background(.ultraThinMaterial)

            // Treść paska – zanika wraz z progresem
            HStack(spacing: 0) {
                Menu {
                    Button("Option 1", action: onMenuPrimary)
                    Button("Option 2", action: onMenuSecondary)
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

                Button(action: onLeadingTap) {
                    Image(systemName: "heart")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundColor(.black)
                }

                Button(action: onTrailingTap) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 18, weight: .semibold))
                        .frame(width: 44, height: 44)
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 8)
            .frame(height: 48)
            .opacity(contentOpacity)

            // Dolny divider (może też lekko zanikać, jeśli chcesz)
            Divider()
                .opacity(0.7)
        }
        .frame(height: 48)
    }
}
