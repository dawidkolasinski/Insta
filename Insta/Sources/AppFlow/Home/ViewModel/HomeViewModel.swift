//
//  HomeViewModel.swift
//  Insta
//
//  Created by Dawid Kolasinski on 27/09/2025.
//

import Combine
import Foundation
import Network

final class HomeViewModel: HomeViewModelProtocol {

    @Published private(set) var stories: [StoryItemViewModel] = []
    @Published private(set) var isOnline: Bool = true

    private var page: Int = 0

    private let repo: StoryRepository
    let persistenceObj: PersistenceStore

    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitorQueue")
    private var bag = Set<AnyCancellable>()

    init(
        repo: StoryRepository = StoryRepository(),
        persistence: PersistenceStore = PersistenceStore()
    ) {
        self.repo = repo
        self.persistenceObj = persistence

        monitor.pathUpdateHandler = { [weak self] path in
            let becameOnline = (path.status == .satisfied)
            DispatchQueue.main.async {
                guard let self = self else { return }
                let wasOnlineBefore = self.isOnline
                self.isOnline = becameOnline
                if becameOnline && !wasOnlineBefore {
                    // Auto-refresh content after reconnect
                    Task { await self.reloadAfterReconnect() }
                }
            }
        }
        monitor.start(queue: monitorQueue)

        persistenceObj.$seen
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshSeen()
            }
            .store(in: &bag)
        
        Task { [weak self] in
            await self?.loadInitialSyncAvatars()
        }
    }

    deinit {
        monitor.cancel()
    }

    func loadInitialSyncAvatars() async {
        guard stories.isEmpty else { return }
        guard isOnline else { return }
        if let pageStories = try? await repo.loadPage(0) {
            await withTaskGroup(of: Void.self) { group in
                for story in pageStories {
                    if let url = story.user.avatarURL {
                        group.addTask {
                            await AvatarImageCache.shared.prefetchSync(url: url)
                        }
                    }
                }
            }
            let newVMs = pageStories.map { StoryItemViewModel(story: $0, persistence: persistenceObj) }
            await MainActor.run {
                self.stories.append(contentsOf: newVMs)
                self.page = 1
            }
        }
    }

    func loadInitial() async {
        guard stories.isEmpty else { return }
        guard isOnline else { return }
        await loadMore()
    }

    func loadMoreIfNeeded(current storyVM: StoryItemViewModel?) async {
        guard let storyVM = storyVM, !stories.isEmpty else { return }
        let threshold = 3
        let limitIndex = stories.index(stories.endIndex, offsetBy: -threshold, limitedBy: stories.startIndex) ?? stories.startIndex
        if let currentIndex = stories.firstIndex(where: { $0.id == storyVM.id }), currentIndex >= limitIndex {
            await loadMore()
        }
    }

    private func loadMore() async {
        guard isOnline else { return }
        if let pageStories = try? await repo.loadPage(page) {
            await withTaskGroup(of: Void.self) { group in
                for story in pageStories {
                    if let url = story.user.avatarURL {
                        group.addTask {
                            await AvatarImageCache.shared.prefetchSync(url: url)
                        }
                    }
                }
            }
            let newVMs = pageStories.map { StoryItemViewModel(story: $0, persistence: persistenceObj) }
            await MainActor.run {
                self.stories.append(contentsOf: newVMs)
                self.page += 1
            }
        }
    }

    func refreshSeen() {
        stories = stories.map { StoryItemViewModel(story: $0.story, persistence: persistenceObj) }
    }

    @MainActor
    private func reloadAfterReconnect() async {
        page = 0
        if let firstPage = try? await repo.loadPage(0) {
            await withTaskGroup(of: Void.self) { group in
                for story in firstPage {
                    if let url = story.user.avatarURL {
                        group.addTask {
                            await AvatarImageCache.shared.prefetchSync(url: url)
                        }
                    }
                }
            }
            stories = firstPage.map { StoryItemViewModel(story: $0, persistence: persistenceObj) }
            page = 1
        }
    }

    func preloadAvatars(for users: [User]) {
        for user in users {
            if let url = user.avatarURL {
                AvatarImageCache.shared.loadFromDiskIfNeeded(for: url)
            }
        }
    }
}
