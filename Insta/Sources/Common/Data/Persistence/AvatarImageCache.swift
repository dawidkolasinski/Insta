//
//  AvatarImageCache.swift
//  Insta
//
//  Created by Dawid Kolasinski on 06/10/2025.
//

import Combine
import SwiftUI

@MainActor
final class AvatarImageCache: ObservableObject {
    static let shared = AvatarImageCache()
    @Published private(set) var cache: [URL: Image] = [:]

    private let fileManager = FileManager.default
    private let cacheDir: URL

    init() {
        self.cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("AvatarImageCache", isDirectory: true)
        try? fileManager.createDirectory(at: cacheDir, withIntermediateDirectories: true)
    }

    func image(for url: URL) -> Image? {
        cache[url]
    }

    func loadFromDiskIfNeeded(for url: URL) {
        guard cache[url] == nil else { return }
        let fileURL = self.fileURL(for: url)
        guard fileManager.fileExists(atPath: fileURL.path) else { return }
        Task { @MainActor in
            if let uiImage = UIImage(contentsOfFile: fileURL.path) {
                let img = Image(uiImage: uiImage)
                self.cache[url] = img
            }
        }
    }

    func store(_ image: Image, for url: URL) {
        cache[url] = image
    }

    func storeUIImage(_ uiImage: UIImage, for url: URL) {
        let image = Image(uiImage: uiImage)
        cache[url] = image
        saveImageToDisk(uiImage, for: url)
    }

    func prefetch(url: URL) {
        guard cache[url] == nil, !fileManager.fileExists(atPath: fileURL(for: url).path) else { return }
        Task.detached { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let uiImage = UIImage(data: data) else { return }
                await MainActor.run {
                    self?.storeUIImage(uiImage, for: url)
                }
            } catch {
                print("prefetchSync failed for \(url): \(error)")
            }
        }
    }

    func prefetchSync(url: URL) async {
        if image(for: url) != nil { return }
        let fileURL = self.fileURL(for: url)
        if fileManager.fileExists(atPath: fileURL.path) {
            await MainActor.run {
                self.loadFromDiskIfNeeded(for: url)
            }
            return
        }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let uiImage = UIImage(data: data) else { return }
            await MainActor.run {
                self.storeUIImage(uiImage, for: url)
            }
        } catch {
            print("prefetchSync failed for \(url): \(error)")
        }
    }

    private func fileURL(for url: URL) -> URL {
        let filename = url.absoluteString.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) ?? UUID().uuidString
        return cacheDir.appendingPathComponent(filename + ".png")
    }

    private func saveImageToDisk(_ image: UIImage, for url: URL) {
        let url = fileURL(for: url)
        guard !fileManager.fileExists(atPath: url.path) else { return }
        guard let data = image.pngData() else { return }
        try? data.write(to: url)
    }
}
