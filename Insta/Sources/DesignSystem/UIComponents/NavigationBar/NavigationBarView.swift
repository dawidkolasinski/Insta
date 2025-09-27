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
        HStack(spacing: 16) {
            Button(action: onLeadingTap) {
                Image(systemName: "camera")
                    .imageScale(.large)
            }
            Spacer()
            Text(title)
                .font(.title2)
                .fontWeight(.semibold)
            Spacer()
            Button(action: onTrailingTap) {
                Image(systemName: "paperplane")
                    .imageScale(.large)
            }
        }
        .padding(.horizontal)
        .frame(height: 44)
        .background(.thinMaterial)
    }
}
