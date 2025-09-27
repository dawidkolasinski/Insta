//
//  ProgressBarView.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import SwiftUI

struct ProgressBarView: View {
    let count: Int
    let currentIndex: Int
    let progress: Double

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<count, id: \.self) { i in
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.35))
                        if i < currentIndex {
                            Capsule().fill(Color.white).frame(width: geo.size.width)
                        } else if i == currentIndex {
                            Capsule().fill(Color.white).frame(width: geo.size.width * progress)
                        }
                    }
                }
                .frame(height: 3)
            }
        }
        .frame(height: 3)
        .padding(.horizontal)
    }
}
