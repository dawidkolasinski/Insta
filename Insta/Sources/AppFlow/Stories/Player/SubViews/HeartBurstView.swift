//
//  HeartBurstView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct HeartBurstView: View {
    @Binding var visible: Bool

    var body: some View {
        Image(systemName: "heart.fill")
            .font(.system(size: 90))
            .foregroundStyle(.red)
            .opacity(visible ? 1 : 0)
            .scaleEffect(visible ? 1 : 0.5)
            .animation(.spring(response: 0.4, dampingFraction: 0.6), value: visible)
    }
}
