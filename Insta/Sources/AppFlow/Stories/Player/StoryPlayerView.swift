//
//  StoryPlayerView.swift
//  Insta (Refactored as reusable component)
//
//  Created by Dawid Kolasinski on 27/09/2025.
//  Refactor: protocol-oriented, testable, generic, app-agnostic component.
//

import Combine
import SwiftUI

// MARK: - Protocols (component-facing)

/// Minimal item contract for the story player.
protocol StoryItemProtocol {
    var id: String { get }
    var imageURL: URL? { get }
}

/// Minimal user contract for the story player.
protocol StoryUserProtocol {
    var name: String { get }
    var avatarURL: URL? { get }
}

/// Minimal story contract for the story player.
protocol StoryProtocol {
    var id: String { get }
    var user: StoryUserProtocol { get }
    var items: [any StoryItemProtocol] { get }
}

/// Stories feed protocol for container view model
protocol StoriesFeedProtocol {
    var stories: [any StoryProtocol] { get }
    var startIndex: Int { get }
}

struct AnyStoryItem: StoryItemProtocol {
    let id: String
    let imageURL: URL?
    init(id: String, imageURL: URL?) { self.id = id; self.imageURL = imageURL }
}

struct AnyStoryUser: StoryUserProtocol {
    let name: String
    let avatarURL: URL?
    init(name: String, avatarURL: URL?) { self.name = name; self.avatarURL = avatarURL }
}

struct AnyStory: StoryProtocol {
    let id: String
    let user: StoryUserProtocol
    let items: [any StoryItemProtocol]
    init(id: String, user: StoryUserProtocol, items: [any StoryItemProtocol]) {
        self.id = id; self.user = user; self.items = items
    }
}

// MARK: - Generic Image Slides (no domain model required)

/// A source for an image: either remote URL or asset name.
enum ImageSource: Equatable {
    case url(URL)
    case asset(String)
}

/// One slide representing a single image from a source.
struct ImageSlide: Identifiable, Equatable {
    let id: String
    let source: ImageSource
    init(id: String = UUID().uuidString, source: ImageSource) {
        self.id = id
        self.source = source
    }
}
/// File-scope auto-advance config for ImageSlides
struct ImageSlidesAutoConfig: Equatable {
    var enabled: Bool = true
    var durationPerSlide: TimeInterval = 5.0
    var tick: TimeInterval = 0.05
    var loops: Bool = false
}

/// Minimal VM that navigates between image slides.
final class ImageSlidesViewModel: ObservableObject {
    @Published private(set) var slides: [ImageSlide]
    @Published private(set) var index: Int
    @Published private(set) var progress: Double = 0

    private let auto: ImageSlidesAutoConfig
    private var timerRef: Timer?

    init(slides: [ImageSlide], startAt: Int = 0, auto: ImageSlidesAutoConfig = .init()) {
        self.slides = slides
        self.index = max(0, min(startAt, max(0, slides.count - 1)))
        self.auto = auto
    }

    var current: ImageSlide { slides[index] }

    func start() {
        stop()
        progress = 0
        guard auto.enabled, slides.count > 0 else { return }
        let localTimer = Timer.scheduledTimer(withTimeInterval: auto.tick, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.progress += self.auto.tick / max(0.0001, self.auto.durationPerSlide)
            if self.progress >= 1 {
                self.progress = 0
                if self.index < self.slides.count - 1 {
                    self.index += 1
                } else if self.auto.loops {
                    self.index = 0
                } else {
                    self.stop()
                }
            }
        }
        RunLoop.main.add(localTimer, forMode: .common)
        self.timerRef = localTimer
    }

    func stop() { timerRef?.invalidate(); timerRef = nil }

    func pause(_ value: Bool) { isPaused = value }

    @Published private(set) var isPaused: Bool = false

    func next() {
        progress = 0
        if index < slides.count - 1 { index += 1 }
        else if auto.loops { index = 0 }
    }

    func prev() {
        progress = 0
        if index > 0 { index -= 1 }
        else if auto.loops { index = max(0, slides.count - 1) }
    }

    deinit { stop() }
}

/// Display style options for the image slides player.
enum ImageSlidesStyle: Equatable {
    /// Card-style inside safe area with aspect ratio and corner radius.
    case card(aspectRatio: CGFloat = 9/16, cornerRadius: CGFloat = 16)
    /// Fullscreen background (optionally ignoring safe areas).
    case fullscreen(ignoreSafeAreas: Bool = true)
}

/// Generic image slides player supporting taps/swipes and basic styles.
struct ImageSlidesView: View {
    @ObservedObject private var viewModel: ImageSlidesViewModel

    struct GesturesConfig: Equatable {
        var taps: Bool = true
        var swipes: Bool = true
        var verticalDismiss: Bool = true
        var longPressPause: Bool = true
        static let allEnabled = GesturesConfig()
    }

    private let style: ImageSlidesStyle
    private let gestures: GesturesConfig
    private let showsCounter: Bool
    private let onVerticalDismiss: (() -> Void)?

    init(
        slides: [ImageSlide],
        startAt: Int = 0,
        style: ImageSlidesStyle = .card(),
        gestures: GesturesConfig = .allEnabled,
        showsCounter: Bool = false,
        onVerticalDismiss: (() -> Void)? = nil,
        auto: ImageSlidesAutoConfig = .init()
    ) {
        self.viewModel = ImageSlidesViewModel(slides: slides, startAt: startAt, auto: auto)
        self.style = style
        self.gestures = gestures
        self.showsCounter = showsCounter
        self.onVerticalDismiss = onVerticalDismiss
    }

    init(
        sources: [ImageSource],
        startAt: Int = 0,
        style: ImageSlidesStyle = .card(),
        gestures: GesturesConfig = .allEnabled,
        showsCounter: Bool = false,
        onVerticalDismiss: (() -> Void)? = nil,
        auto: ImageSlidesAutoConfig = .init()
    ) {
        let slides = sources.map { ImageSlide(source: $0) }
        self.viewModel = ImageSlidesViewModel(slides: slides, startAt: startAt, auto: auto)
        self.style = style
        self.gestures = gestures
        self.showsCounter = showsCounter
        self.onVerticalDismiss = onVerticalDismiss
    }

    init(
        viewModel: ImageSlidesViewModel,
        style: ImageSlidesStyle = .card(),
        gestures: GesturesConfig = .allEnabled,
        showsCounter: Bool = false,
        onVerticalDismiss: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.style = style
        self.gestures = gestures
        self.showsCounter = showsCounter
        self.onVerticalDismiss = onVerticalDismiss
    }

    var body: some View {
        ZStack(alignment: .top) {
            content
            progressOverlay
            if showsCounter { counterOverlay }
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { viewModel.start() }
        .onDisappear { viewModel.stop() }
    }

    @ViewBuilder
    private var content: some View {
        let imageView = renderedImage(for: viewModel.current.source)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .clipped()
            .animation(nil, value: viewModel.current.id)
            .overlay(navTapZones)

        let applied: AnyView = {
            switch style {
            case let .card(aspect, radius):
                return AnyView(
                    imageView
                        .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .aspectRatio(aspect, contentMode: .fit)
                )
            case let .fullscreen(ignore):
                return AnyView(
                    imageView
                        .ignoresSafeArea(ignore ? .all : [])
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                )
            }
        }()

        applied.highPriorityGesture(dragGesture)
    }

    private var navTapZones: some View {
        Group {
            if gestures.taps {
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.prev()
                        }
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture {
                            viewModel.next()
                        }
                }
            } else {
                Color.clear
            }
        }
    }

    private var progressOverlay: some View {
        LinearGradient(colors: [Color.black.opacity(0.65), .clear], startPoint: .top, endPoint: .bottom)
            .frame(height: 44)
            .overlay(
                HStack(spacing: 4) {
                    ForEach(viewModel.slides.indices, id: \.self) { i in
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.25))
                                Capsule().fill(Color.white)
                                    .frame(width: geo.size.width * filledAmount(for: i))
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .frame(height: 2), alignment: .bottom
            )
            .allowsHitTesting(false)
    }

    private func filledAmount(for i: Int) -> CGFloat {
        if i < viewModel.index { return 1 }
        if i > viewModel.index { return 0 }
        return CGFloat(min(1, max(0, viewModel.progress)))
    }

    private var counterOverlay: some View {
        LinearGradient(colors: [Color.black.opacity(0.65), .clear], startPoint: .top, endPoint: .bottom)
            .frame(height: 88)
            .overlay(
                HStack(spacing: 8) {
                    Text("\(viewModel.index + 1)/\(viewModel.slides.count)")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 8), alignment: .topLeading
            )
            .allowsHitTesting(false)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onChanged { _ in
                if gestures.longPressPause { viewModel.pause(true) }
            }
            .onEnded { value in
                if gestures.longPressPause { viewModel.pause(false) }
                if gestures.verticalDismiss, value.translation.height > 80 {
                    onVerticalDismiss?()
                    return
                }
                if gestures.swipes {
                    if value.translation.width < -60 { viewModel.next() }
                    else if value.translation.width > 60 { viewModel.prev() }
                }
            }
    }

    @ViewBuilder
    private func renderedImage(for source: ImageSource) -> some View {
        switch source {
        case .asset(let name):
            Image(name).resizable().scaledToFill()
        case .url(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img): img.resizable().scaledToFill()
                case .failure: Color.black
                default: Color.black
                }
            }
        }
    }
}


struct StoriesContainerView: View {
    @Environment(\.dismiss) private var dismiss

    @StateObject private var containerVM: StoriesContainerViewModel

    init(feed: any StoriesFeedProtocol) {
        _containerVM = StateObject(wrappedValue: StoriesContainerViewModel(feed: feed))
    }

    var body: some View {
        ZStack {
            if !containerVM.stories.isEmpty {
                StoryView(viewModel: containerVM.storyVM)
                    .id((containerVM.currentStory as StoryProtocol).id)
                    .transition(.opacity)
            } else {
                Text("No stories available")
                    .foregroundColor(.white)
                    .font(.headline)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .gesture(dragGesture)
        .preferredColorScheme(.dark)
        .animation(.easeInOut(duration: 0.2), value: containerVM.currentIndex)
        .onChange(of: containerVM.shouldDismiss) { should in
            if should { dismiss() }
        }
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 20, coordinateSpace: .local)
            .onEnded { value in
                if value.translation.height > 80 {
                    dismiss()
                } else if value.translation.width < -60 {
                    containerVM.goNextStory()
                } else if value.translation.width > 60 {
                    containerVM.goPrevStory()
                }
            }
    }
}

// MARK: - StoryView: single story slides view

struct StoryView: View {
    @ObservedObject var viewModel: StoryViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            contentContainer
        }
        .overlay(alignment: .top) { topOverlay.safeAreaPadding(.top) }
        .background(Color.black.ignoresSafeArea())
    }

    private var contentContainer: some View {
        ZStack {
            backgroundImage
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.pause(false)
                        withTransaction(Transaction(animation: nil)) { viewModel.prev() }
                    }
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        viewModel.pause(false)
                        withTransaction(Transaction(animation: nil)) { viewModel.next() }
                    }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .frame(maxWidth: .infinity, alignment: .center)
        .aspectRatio(9/16, contentMode: .fit)
        .animation(nil, value: (viewModel.currentItem as StoryItemProtocol).id)
        .animation(nil, value: (viewModel.story as StoryProtocol).id)
        .transaction { $0.animation = nil }
        .simultaneousGesture(longPressGesture)
    }

    private var backgroundImage: some View {
        let url = (viewModel.currentItem as StoryItemProtocol).imageURL
        return AsyncImage(url: url) { phase in
            switch phase {
            case .success(let img):
                img
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .onAppear { viewModel.onCurrentItemLoaded() }
            case .failure:
                Color.black
            default:
                Color.black
            }
        }
    }

    private var topOverlay: some View {
        ZStack(alignment: .top) {
            LinearGradient(
                colors: [Color.black.opacity(0.65), Color.black.opacity(0.0)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 140)
            .ignoresSafeArea(edges: .top)
            .allowsHitTesting(false)

            VStack(spacing: 8) {
                // Progress bars
                HStack(spacing: 4) {
                    ForEach(Array(viewModel.items.indices), id: \.self) { barIndex in
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.25))
                                Capsule().fill(Color.white)
                                    .frame(width: geo.size.width * filledAmount(for: barIndex))
                            }
                        }
                    }
                }
                .frame(height: 2)
                .padding(.horizontal, 8)

                // Header with X button
                HStack(spacing: 12) {
                    if let avatar = (viewModel.story.user as StoryUserProtocol).avatarURL {
                        StoryAvatarView(url: avatar, seen: false, displayedPlace: .storyDetail)
                    } else {
                        Image(systemName: "person.crop.circle.fill")
                            .foregroundStyle(.white)
                            .font(.title2)
                    }
                    Text((viewModel.story.user as StoryUserProtocol).name)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("•").foregroundStyle(.white.opacity(0.7))
                    Text("\(viewModel.index + 1)/\(viewModel.items.count)")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.9))
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.55), in: Circle())
                    }
                }
                .padding(.horizontal)
            }
            .padding(.top, 12)
        }
    }

    private func filledAmount(for barIndex: Int) -> CGFloat {
        if barIndex < viewModel.index { return 1 }
        if barIndex > viewModel.index { return 0 }
        return CGFloat(min(1, max(0, viewModel.progress)))
    }

    private var longPressGesture: some Gesture {
        LongPressGesture(minimumDuration: 0.2)
            .onChanged { _ in viewModel.pause(true) }
            .onEnded { _ in viewModel.pause(false) }
    }
}

// MARK: - Convenience initializer for your current app models

extension StoriesContainerView {
    /// Convenience init to keep your current `Story` model working without changes.
    /// Wraps single story into a StoriesFeedProtocol inline struct.
    init(story: Story) {
        struct SingleStoryFeed: StoriesFeedProtocol {
            let stories: [any StoryProtocol]
            let startIndex: Int = 0
            init(_ story: Story) {
                let mapped = AnyStory(
                    id: story.id,
                    user: AnyStoryUser(name: story.user.name, avatarURL: story.user.avatarURL),
                    items: story.items.map { AnyStoryItem(id: $0.id, imageURL: $0.imageURL) }
                )
                self.stories = [mapped]
            }
        }
        let feed = SingleStoryFeed(story)
        self.init(feed: feed)
    }
}
