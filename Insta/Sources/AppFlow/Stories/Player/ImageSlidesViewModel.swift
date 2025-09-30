//
//  ImageSlidesViewModel.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Combine
import Foundation
import SwiftUI

final class ImageSlidesViewModel: ObservableObject {
    @Published private(set) var slides: [ImageSlide]
    @Published private(set) var index: Int
    @Published private(set) var progress: Double = 0
    @Published private(set) var isPaused: Bool = false
    @Published private(set) var holdCount: Int = 0

    private let auto: ImageSlidesAutoConfig
    private var timerRef: Timer?

    init(slides: [ImageSlide], startAt: Int = 0, auto: ImageSlidesAutoConfig = .init()) {
        self.slides = slides
        self.index = max(0, min(startAt, max(0, slides.count - 1)))
        self.auto = auto
    }

    deinit { stop() }

    var current: ImageSlide {
        if slides.indices.contains(index) { return slides[index] }
        return slides.first ?? ImageSlide(source: .asset(""))
    }

    func start() {
        stop()
        progress = 0
        guard auto.enabled, slides.count > 0 else { return }
        let timer = Timer.scheduledTimer(withTimeInterval: auto.tick, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.isPaused || self.holdCount > 0 { return }
            self.progress += self.auto.tick / max(0.0001, self.auto.durationPerSlide)
            if self.progress >= 1 {
                self.progress = 0
                if self.index < self.slides.count - 1 { self.index += 1 }
                else if self.auto.loops { self.index = 0 }
                else { self.stop() }
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        timerRef = timer
    }

    func stop() { timerRef?.invalidate(); timerRef = nil }
    func pause(_ value: Bool) { isPaused = value }
    func hold(_ value: Bool) { if value { holdCount += 1 } else { holdCount = max(0, holdCount - 1) } }
    func next() { progress = 0; if index < slides.count - 1 { index += 1 } else if auto.loops { index = 0 } }
    func prev() { progress = 0; if index > 0 { index -= 1 } else if auto.loops { index = max(0, slides.count - 1) } }
}
